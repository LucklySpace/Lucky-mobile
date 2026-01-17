import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../config/app_config.dart';
import '../../../../constants/app_colors.dart';
import '../../widgets/common/app_webview.dart';

/// 简化后的 WebView 容器页面
/// 具备沉浸式能力，逻辑全部托管给 AppWebView 组件
class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  WebViewController? _webController;
  String _title = "加载中...";
  late final String _url;
  late final bool _hideAppBar; // 是否全屏隐藏导航栏

  @override
  void initState() {
    super.initState();
    // 解析参数
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _url = args['url'] ?? Get.parameters['url'] ?? AppConfig.defaultUrl;
    _hideAppBar = args['hideAppBar'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canBack = await _webController?.canGoBack() ?? false;
        if (canBack) {
          _webController?.goBack();
        } else {
          Get.back();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _hideAppBar ? null : _buildAppBar(),
        body: AppWebView(
          initialUrl: _url,
          onTitleChanged: (title) => setState(() => _title = title),
          onWebViewCreated: (controller) => _webController = controller,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_title, style: const TextStyle(fontSize: 16)),
      centerTitle: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Get.back(),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            _buildMenuItem('refresh', Icons.refresh, '刷新'),
            _buildMenuItem('copy', Icons.copy, '复制链接'),
            _buildMenuItem('share', Icons.share, '分享'),
            _buildMenuItem('browser', Icons.open_in_browser, '浏览器打开'),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(
      String value, IconData icon, String text) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textPrimary),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  void _handleMenuAction(String value) async {
    final currentUrl = await _webController?.currentUrl() ?? _url;
    switch (value) {
      case 'refresh':
        _webController?.reload();
        break;
      case 'copy':
        // 逻辑已在之前实现，这里简化
        break;
      case 'share':
        Share.share(currentUrl);
        break;
      case 'browser':
        launchUrl(Uri.parse(currentUrl), mode: LaunchMode.externalApplication);
        break;
    }
  }
}
