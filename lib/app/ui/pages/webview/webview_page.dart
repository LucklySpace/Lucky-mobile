import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../config/app_config.dart';
import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../routes/app_routes.dart';

/// 优化说明：
/// - 加载进度以细线显示在 AppBar 下方
/// - 使用下拉刷新（RefreshIndicator）支持刷新页面
/// - 显示加载进度条和页面标题（自动获取 document.title）
/// - 提供右上角菜单：刷新、在浏览器打开、复制链接、分享链接
/// - 更清晰的后退逻辑（优先 WebView 后退，否则回到上级或首页）
/// - 关键处都有中文注释，代码结构更清晰、可维护性更高
class WebViewPage extends StatefulWidget {
  const WebViewPage({Key? key}) : super(key: key);

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;

  String _title = "加载中..."; // AppBar 标题
  int _progress = 0; // 页面加载进度 (0 - 100)
  late String _initialUrl; // 初始 URL
  Completer<void>? _refreshCompleter;

  // 可调：进度线的高度
  static const double kProgressHeight = AppSizes.spacing3;

  @override
  void initState() {
    super.initState();

    // 从 Get 参数中读取 url，优先级：Get.parameters > Get.arguments > AppConfig.defaultUrl
    _initialUrl =
        Get.parameters["url"] ?? Get.arguments?["url"] ?? AppConfig.defaultUrl;

    // 初始化 WebViewController（webview_flutter >=4.x API）
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // 页面加载进度回调（0 - 100）
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (String url) {
            // 页面开始加载时可以设置标题占位（可选）
            if (mounted) setState(() => _title = "加载中...");
          },
          onPageFinished: (String url) {
            // 页面加载完成：更新标题并完成 refresh completer（如果存在）
            _updateTitle();
            _refreshCompleter?.complete();
            _refreshCompleter = null;
          },
          onNavigationRequest: _handleNavigationRequest,
        ),
      )
      ..loadRequest(Uri.parse(_initialUrl));
  }

  @override
  void dispose() {
    // 避免未完成的 completer 导致内存泄漏
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      _refreshCompleter!.complete();
    }
    super.dispose();
  }

  /// 从 DOM 获取 document.title 并更新 AppBar 标题
  Future<void> _updateTitle() async {
    try {
      final result =
          await _controller.runJavaScriptReturningResult("document.title");
      // runJavaScriptReturningResult 在 JS 字符串返回时可能包含引号
      final title = result.toString().replaceAll('"', '').trim();
      if (title.isNotEmpty && mounted) {
        setState(() => _title = title);
      }
    } catch (e) {
      // 获取 title 失败时保留原 title；打印日志便于调试
      Get.log("❌ 获取网页标题失败: $e");
    }
  }

  /// 处理 WebView 的跳转请求：支持 http/https 内部跳转，否则尝试使用外部应用处理（比如 tel:, mailto:）
  FutureOr<NavigationDecision> _handleNavigationRequest(
      NavigationRequest request) async {
    final uri = Uri.tryParse(request.url);
    if (uri == null) {
      Get.log("⚠️ 无效 URL: ${request.url}");
      return NavigationDecision.prevent;
    }

    // http/https 使用 WebView 内部导航
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return NavigationDecision.navigate;
    }

    // 非 http/https，尝试通过外部应用打开（例如拨号、邮件、第三方应用协议）
    if (await canLaunchUrl(uri)) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        Get.log("⚠️ 调用外部应用失败: $e");
      }
      return NavigationDecision.prevent;
    }

    Get.log("⚠️ 无法处理的 URL: ${request.url}");
    return NavigationDecision.prevent;
  }

  /// 后退处理：优先 webview 回退，否则使用 Get 导航返回上一页；如果没有上一页则回到首页
  Future<void> _handleBack() async {
    try {
      if (await _controller.canGoBack()) {
        await _controller.goBack();
        return;
      }
    } catch (e) {
      // 忽略 controller 异常，继续使用 Get 导航逻辑
      Get.log("⚠️ 检查 canGoBack 异常: $e");
    }

    // 如果可以返回上一页（Get 层），则回退，否则直接回到首页
    if (Get.previousRoute.isNotEmpty) {
      //   Get.back();
      // } else {
      Get.offAllNamed(Routes.HOME);
    }
  }

  /// 执行下拉刷新：调用 reload 并等待 onPageFinished 完成或者超时
  Future<void> _onRefresh() async {
    // 如果已存在未完成的 refresh，则直接等待
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }
    _refreshCompleter = Completer<void>();
    try {
      await _controller.reload();
      // 等待 onPageFinished 在 8 秒内完成，否则直接返回
      await _refreshCompleter!.future
          .timeout(const Duration(seconds: 8), onTimeout: () {});
    } catch (e) {
      Get.log("⚠️ 刷新异常: $e");
    } finally {
      if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete();
      }
      _refreshCompleter = null;
    }
  }

  /// 获取当前 URL（出错时返回初始 URL）
  Future<String> _currentUrl() async {
    try {
      final url = await _controller.currentUrl();
      return url ?? _initialUrl;
    } catch (_) {
      return _initialUrl;
    }
  }

  /// 在外部浏览器打开当前 URL
  Future<void> _openInBrowser() async {
    final urlStr = await _currentUrl();
    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar("打开失败", "无法在外部浏览器打开链接");
    }
  }

  /// 复制当前 URL 到剪贴板
  Future<void> _copyLink() async {
    final urlStr = await _currentUrl();
    await Clipboard.setData(ClipboardData(text: urlStr));
    Get.snackbar("已复制链接", urlStr, snackPosition: SnackPosition.TOP);
  }

  /// 分享当前 URL（使用 share_plus）
  Future<void> _shareLink() async {
    final urlStr = await _currentUrl();
    try {
      await Share.share(urlStr);
    } catch (e) {
      Get.snackbar("分享失败", e.toString());
    }
  }

  /// 构建 AppBar 下方的进度条（细线），使用 AnimatedOpacity 做平滑显示隐藏
  PreferredSizeWidget? _buildProgressBottom() {
    // 当正在加载（0 < progress < 100）时显示进度线，否则返回 null（不占位）
    final bool show = _progress > 0 && _progress < 100;
    // 若不希望占用 AppBar bottom 的高度时，返回 null
    if (!show) return null;

    // 使用 PreferredSize 包装自定义高度的进度线
    return PreferredSize(
      preferredSize: Size.fromHeight(kProgressHeight),
      child: SizedBox(
        height: kProgressHeight,
        child: LinearProgressIndicator(
          // 当 progress 为 0 或 100 时可以使用 null（不应到这里）
          value: (_progress.clamp(0, 100)) / 100.0,
          minHeight: kProgressHeight,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          backgroundColor: AppColors.primary.withOpacity(0.2),
        ),
      ),
    );
  }

  /// AppBar 右侧操作菜单（刷新、打开浏览器、复制、分享）
  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 显示简单的刷新按钮
        IconButton(
          tooltip: "刷新",
          icon: const Icon(Icons.refresh),
          onPressed: () => _controller.reload(),
        ),
        const SizedBox(width: AppSizes.spacing16),

        /// 返回首页按钮
        IconButton(
          tooltip: "首页",
          icon: const Icon(Icons.home),
          onPressed: () => Get.offAllNamed(Routes.HOME),
        ),
        // 更多操作：在浏览器打开 / 复制链接 / 分享
        PopupMenuButton<int>(
          tooltip: "更多",
          onSelected: (value) async {
            switch (value) {
              case 1:
                await _openInBrowser();
                break;
              case 2:
                await _copyLink();
                break;
              case 3:
                await _shareLink();
                break;
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 1,
              child: ListTile(
                leading: Icon(Icons.open_in_browser),
                title: Text('在浏览器中打开'),
              ),
            ),
            const PopupMenuItem(
              value: 2,
              child: ListTile(
                leading: Icon(Icons.copy),
                title: Text('复制链接'),
              ),
            ),
            const PopupMenuItem(
              value: 3,
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('分享链接'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // AppBar 标题超长时显示省略号
    return WillPopScope(
      onWillPop: () async {
        await _handleBack();
        // 我们自己处理回退，不让系统自动 pop
        return false;
      },
      child: Scaffold(
        // AppBar：将进度条放在 bottom（AppBar 下方）
        appBar: AppBar(
          title: Text(_title, overflow: TextOverflow.ellipsis),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: _handleBack,
          ),
          actions: [_buildActions()],
          // bottom: 根据进度动态返回 PreferredSize 或 null
          bottom: _buildProgressBottom(),
        ),
        // 下拉刷新包裹 WebViewWidget
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: WebViewWidget(controller: _controller),
        ),
      ),
    );
  }
}
