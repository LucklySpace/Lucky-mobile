import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../constants/app_colors.dart';

/// 统一定义 JS Bridge 回调名
class WebViewJSBridge {
  static const String channelName = 'LuckyNative';

  // 定义指令
  static const String cmdClose = 'closePage';
  static const String cmdShare = 'share';
  static const String cmdToast = 'toast';
}

/// 自定义 JS 通道配置类
class AppJSChannel {
  final String name;
  final void Function(JavaScriptMessage) onMessageReceived;

  AppJSChannel({required this.name, required this.onMessageReceived});
}

/// 高级 WebView 核心组件
/// 提供了进度条、标题同步、JSBridge 交互、加载状态管理等
class AppWebView extends StatefulWidget {
  final String initialUrl;
  final String? title;
  final bool showProgress;
  final Function(String title)? onTitleChanged;
  final Function(int progress)? onProgressChanged;
  final Function(WebViewController controller)? onWebViewCreated;
  final List<AppJSChannel>? extraJSChannels;

  const AppWebView({
    super.key,
    required this.initialUrl,
    this.title,
    this.showProgress = true,
    this.onTitleChanged,
    this.onProgressChanged,
    this.onWebViewCreated,
    this.extraJSChannels,
  });

  @override
  State<AppWebView> createState() => _AppWebViewState();
}

class _AppWebViewState extends State<AppWebView> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) setState(() => _progress = progress);
            widget.onProgressChanged?.call(progress);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _hasError = false);
          },
          onPageFinished: (url) => _syncTitle(),
          onWebResourceError: (WebResourceError error) {
            // 忽略一些不重要的错误（比如某些资源加载失败）
            if (error.description.contains('net::ERR_CACHE_MISS')) return;
            if (mounted) setState(() => _hasError = true);
          },
        ),
      );

    // 注册默认的 JS Bridge
    _controller.addJavaScriptChannel(
      WebViewJSBridge.channelName,
      onMessageReceived: _handleJSMessage,
    );

    // 注册额外的 JS 通道
    if (widget.extraJSChannels != null) {
      for (var channel in widget.extraJSChannels!) {
        _controller.addJavaScriptChannel(
          channel.name,
          onMessageReceived: channel.onMessageReceived,
        );
      }
    }

    // 加载初始 URL
    _controller.loadRequest(Uri.parse(widget.initialUrl));
    widget.onWebViewCreated?.call(_controller);
  }

  /// 处理 JS 回调（JSBridge）
  /// H5 调用示例: LuckyNative.postMessage('closePage')
  void _handleJSMessage(JavaScriptMessage message) {
    final msg = message.message;
    Get.log('🌐 WebView JSBridge Received: $msg');

    switch (msg) {
      case WebViewJSBridge.cmdClose:
        Get.back();
        break;
      case WebViewJSBridge.cmdToast:
        // 后续可扩展更多指令解析
        break;
    }
  }

  /// 同步网页标题
  Future<void> _syncTitle() async {
    try {
      final title = await _controller.getTitle();
      if (title != null && title.isNotEmpty) {
        widget.onTitleChanged?.call(title);
      }
    } catch (e) {
      Get.log('❌ WebView GetTitle Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 核心网页层
        WebViewWidget(controller: _controller),

        // 加载进度条（细线风格）
        if (widget.showProgress && _progress > 0 && _progress < 100)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                value: _progress / 100.0,
                backgroundColor: Colors.transparent,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),

        // 错误重试界面
        if (_hasError) _buildErrorView(),
      ],
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 64, color: AppColors.textHint.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('页面加载失败',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _controller.reload(),
            child: const Text('点击重试'),
          ),
        ],
      ),
    );
  }
}
