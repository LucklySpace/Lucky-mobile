import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_constant.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../routes/app_routes.dart';
import '../../../../utils/audio.dart';
import 'login_authorization_page.dart';

/// 扫一扫页面，支持扫描二维码并处理 URL、登录授权和好友资料
/// 特性：
/// - 使用 MobileScanner 提供二维码扫描功能。
/// - 支持闪光灯开关和扫描线动画。
/// - 提供震动和音效反馈，处理不同类型二维码（URL、登录、好友资料）。
/// - 自动管理相机生命周期（暂停/恢复）。
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  // 常量定义
  static const _scanAreaSize = AppSizes.spacing250; // 扫描区域尺寸
  static const _cornerSize = AppSizes.spacing30; // 扫描框角尺寸
  static const _cornerBorderWidth = AppSizes.spacing4; // 扫描框角边框宽度
  static const _animationDuration = Duration(seconds: 2); // 扫描线动画时长
  static const _audioPath = 'audio/beep.mp3'; // 扫码音效路径
  static const _iconSize = AppSizes.iconMedium; // 返回按钮图标尺寸
  static const _torchIconSize = AppSizes.spacing40; // 闪光灯图标尺寸

  final MobileScannerController _controller = MobileScannerController();
  bool _isTorchOn = false; // 闪光灯状态
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // 设置强制竖屏
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // 添加生命周期监听
    WidgetsBinding.instance.addObserver(this);
    // 初始化动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    )..repeat();
    // 启动相机
    _controller.start();
  }

  @override
  void dispose() {
    // 移除生命周期监听
    WidgetsBinding.instance.removeObserver(this);
    // 释放相机和动画资源
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// 监听应用生命周期变化
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    switch (state) {
      case AppLifecycleState.resumed:
        // 应用恢复时启动相机
        if (!_controller.isStarting) _controller.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        // 应用暂停时停止相机
        if (_controller.isStarting) _controller.stop();
        break;
      default:
        break;
    }
  }

  /// 处理二维码扫描结果
  void _handleBarcode(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null) return;

    final code = barcode.rawValue;
    if (code == null) return;

    debugPrint(
        '✅ 扫码结果: $code, 格式: ${barcode.format.name}, 类型: ${barcode.type.name}');

    // 触发震动和音效反馈
    HapticFeedback.mediumImpact();
    AudioPlayerUtil().play(_audioPath, useMediaVolume: false);

    // 停止相机以防止重复扫描
    _controller.stop();

    // 定义二维码处理逻辑
    var handlers = {
      AppConstants.LOGIN_QRCODE_PREFIX: _handleLoginQRCode,
      AppConstants.FRIEND_PROFILE_PREFIX: _handleFriendProfileQRCode,
      AppConstants.WALLET_ADDRESS_PREFIX: _handleWalletAddressQRCode,
    };

    // 检查是否为 URL 或特定前缀
    if (GetUtils.isURL(code)) {
      _navigateTo(Routes.WEB_VIEW, arguments: {'url': code});
      return;
    }

    // 匹配前缀并执行对应处理
    for (final entry in handlers.entries) {
      if (code.startsWith(entry.key)) {
        final trimmedCode = code.substring(entry.key.length);
        if (trimmedCode.isNotEmpty) {
          entry.value(trimmedCode);
        }
        return;
      }
    }

    // 未识别的二维码，显示提示
    Get.snackbar('提示', '无法识别的二维码内容');
    _controller.start();
  }

  /// 处理登录二维码
  void _handleLoginQRCode(String code) {
    if (ModalRoute.of(context)?.settings.name != '/authorization') {
      _navigateToWidget(AuthorizationPage(code: code));
    }
  }

  /// 处理好友资料二维码
  void _handleFriendProfileQRCode(String userId) {
    _navigateTo('${Routes.HOME}${Routes.FRIEND_PROFILE}',
        arguments: {'userId': userId});
  }

  /// 处理钱包地址二维码
  void _handleWalletAddressQRCode(String code) {
    // 解析地址和金额
    // 格式可能为: address&amount=xxx
    String address = code;
    String? amount;

    if (code.contains('&amount=')) {
      final parts = code.split('&amount=');
      if (parts.isNotEmpty) {
        address = parts[0];
        if (parts.length > 1) {
          amount = parts[1];
        }
      }
    }

    // 导航到支付页面，并传递地址参数
    _navigateTo('${Routes.HOME}${Routes.PAYMENT}',
        arguments: {'toAddress': address, 'amount': amount});
  }

  /// 页面跳转并处理返回
  Future<void> _navigateTo(String route,
      {Map<String, dynamic>? arguments}) async {
    try {
      await Get.toNamed(route, arguments: arguments);
      if (mounted) _controller.start();
    } catch (err) {
      debugPrint('❌ 页面跳转失败: $err');
      Get.back();
    }
  }

  /// 跳转到指定页面
  Future<void> _navigateToWidget(Widget page, {dynamic arguments}) async {
    try {
      await Get.to(() => page, arguments: arguments);
      if (mounted) _controller.start();
    } catch (err) {
      debugPrint('❌ 页面跳转失败: $err');
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          /// 扫描相机视图
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),

          /// 返回按钮
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSizes.spacing10,
            left: AppSizes.spacing16,
            child: IconButton(
              icon:
                  const Icon(Icons.close, color: AppColors.textWhite, size: _iconSize),
              onPressed: Get.back,
            ),
          ),

          /// 扫描区域边框和动画
          Center(child: _buildScanOverlay()),

          /// 闪光灯按钮
          Positioned(
            top: screenHeight / 2 + AppSizes.spacing140,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                iconSize: _torchIconSize,
                icon: Icon(
                  _isTorchOn ? Icons.flash_on : Icons.flash_off,
                  color: _isTorchOn ? AppColors.warning : AppColors.textWhite,
                ),
                onPressed: () {
                  setState(() {
                    _isTorchOn = !_isTorchOn;
                    _controller.toggleTorch();
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建扫描区域边框和动画
  Widget _buildScanOverlay() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const SizedBox(width: _scanAreaSize, height: _scanAreaSize),

        /// 扫描线动画
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Positioned(
              top: _animationController.value * _scanAreaSize,
              child: Container(
              width: _scanAreaSize - AppSizes.spacing20,
              height: AppSizes.spacing2,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.success.withOpacity(0),
                      AppColors.success.withOpacity(0.5),
                      AppColors.success,
                      AppColors.success.withOpacity(0.5),
                      AppColors.success.withOpacity(0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        /// 左上角
        Positioned(
          left: 0,
          top: 0,
          child: _buildCornerBorder(left: true, top: true),
        ),

        /// 右上角
        Positioned(
          right: 0,
          top: 0,
          child: _buildCornerBorder(right: true, top: true),
        ),

        /// 左下角
        Positioned(
          left: 0,
          bottom: 0,
          child: _buildCornerBorder(left: true, bottom: true),
        ),

        /// 右下角
        Positioned(
          right: 0,
          bottom: 0,
          child: _buildCornerBorder(right: true, bottom: true),
        ),
      ],
    );
  }

  /// 构建扫描区域的角边框
  Widget _buildCornerBorder(
      {bool left = false,
      bool right = false,
      bool top = false,
      bool bottom = false}) {
    return Container(
      width: _cornerSize,
      height: _cornerSize,
      decoration: BoxDecoration(
        border: Border(
          left: left
              ? const BorderSide(color: AppColors.success, width: _cornerBorderWidth)
              : BorderSide.none,
          right: right
              ? const BorderSide(color: AppColors.success, width: _cornerBorderWidth)
              : BorderSide.none,
          top: top
              ? const BorderSide(color: AppColors.success, width: _cornerBorderWidth)
              : BorderSide.none,
          bottom: bottom
              ? const BorderSide(color: AppColors.success, width: _cornerBorderWidth)
              : BorderSide.none,
        ),
      ),
    );
  }
}
