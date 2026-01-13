import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' hide MessageType;
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../config/app_config.dart';
import '../../../../constants/app_colors.dart';
import '../../../../constants/app_message.dart';
import '../../../../constants/app_sizes.dart';
import '../../../api/api_service.dart';
import '../../../controller/webrtc_controller.dart';
import '../../../services/event_bus_service.dart';

/// 视频通话页面
/// 实现了一对一视频通话功能，包括本地预览、远程视频显示、摄像头切换和音频控制等功能
///
/// 参考资料:
/// - WebRTC实现: https://github.com/as946640/flutter_webrtc_demo/blob/main/README.md
/// - 全屏方案: https://dev59.com/_bTma4cB1Zd3GeqP-a-c
/// - 屏幕常亮: https://juejin.cn/post/7226745855033540666
class VideoCallPage extends StatefulWidget {
  const VideoCallPage({Key? key}) : super(key: key);

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage>
    with AutomaticKeepAliveClientMixin {
  /// WebRTC 控制器，负责管理视频通话的核心功能
  final WebRtcController controller = Get.put(WebRtcController());

  /// 事件总线，用于处理通话相关的事件
  final EventBus _eventBus = Get.find<EventBus>();

  late final String _userId; // 当前用户的推流ID
  late final String _friendId; // 对方用户的ID
  late final bool _isInitiator; // 是否为通话发起方
  bool _isAudioEnabled = false; // 音频是否开启
  bool _isRemoteSuccess = false; // 远程流是否成功
  int cameraIndex = 0; // 相机索引

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeParameters(); // 初始化参数
    _setupEventListeners(); // 设置事件监听
    _initVideo(); // 初始化视频
    _configureSystemUI(); // 配置系统UI
    WakelockPlus.enable(); // 保持屏幕常亮
  }

  /// 初始化从路由参数中获取的通话参数
  void _initializeParameters() {
    _userId = Get.arguments['userId'] as String? ?? '';
    _friendId = Get.arguments['friendId'] as String? ?? '';
    _isInitiator = Get.arguments['isInitiator'] as bool? ?? false;
  }

  /// 配置系统UI，设置状态栏透明和显示模式
  void _configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );
  }

  void _setupEventListeners() {
    _eventBus.on('call_accept', (data) async {
      Get.log("开始拉流");
      await _startRemoteStream();
    });

    _eventBus.on('call_reject', (data) {
      _handleCallTermination("对方拒绝了通话");
    });

    _eventBus.on('call_cancel', (data) {
      _handleCallTermination("对方取消了通话");
    });

    _eventBus.on('call_hangup', (data) {
      _handleCallTermination("对方挂断了通话");
    });
  }

  void _handleCallTermination(String message) {
    Get.snackbar('提示', message,
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 2));
  }

  Future<void> _startRemoteStream() async {
    try {
      final remoteSuccess = await controller.addRemoteLive(
        AppConfig.srsServer,
        '${AppConfig.webRtcServer}$_friendId',
        callback: (bool res) {
          if (!res) {
            Get.snackbar('提示', '远程视频连接失败',
                backgroundColor: AppColors.surface,
                duration: const Duration(seconds: 2));
          }
        },
      );

      if (!remoteSuccess) {
        Get.log('远程视频连接失败');
      }
      _isRemoteSuccess = remoteSuccess;
    } catch (e) {
      Get.log('启动远程视频流失败: $e');
    }
  }

  Future<void> _initVideo() async {
    try {
      // 请求相机和麦克风权限
      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();

      if (!cameraStatus.isGranted || !micStatus.isGranted) {
        Get.snackbar('权限提示', '需要相机和麦克风权限才能进行视频通话',
            backgroundColor: AppColors.surface,
            duration: const Duration(seconds: 2));
        Get.back();
        return;
      }

      await controller.loadDevices();
      await controller.openVideo();

      final localSuccess = await controller.addLocalMedia(
        AppConfig.srsServer,
        '${AppConfig.webRtcServer}$_userId',
        callback: (bool res) {
          if (!res) {
            Get.snackbar('提示', '开启本地视频失败',
                backgroundColor: AppColors.surface,
                duration: const Duration(seconds: 2));
          }
        },
      );

      if (!localSuccess) return;

      // 如果为接收方则拉取远程流
      if (!_isInitiator) {
        await _startRemoteStream();
      }
    } catch (e) {
      Get.log('初始化视频失败: $e');
      Get.snackbar('错误', '视频初始化失败',
          backgroundColor: AppColors.surface,
          duration: const Duration(seconds: 2));
    }
  }

  Future<void> _closeVideo() async {
    try {
      // 关闭控制器中的所有连接和资源
      await controller.close();

      // 恢复系统 UI 设置
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp]);

      // 发送挂断消息给对方
      if (_userId.isNotEmpty && _friendId.isNotEmpty) {
        try {
          await Get.find<ApiService>().sendCallMessage({
            'fromId': _userId,
            'toId': _friendId,
            'type': _isRemoteSuccess
                ? MessageType.rtcHangup.code
                : MessageType.rtcCancel.code
          });
        } catch (e) {
          Get.log('发送挂断消息时出错: $e');
        }
      }
    } catch (e) {
      Get.log('关闭视频时出错: $e');
    } finally {
      // 确保返回上一页
      Get.back();
    }
  }

  @override
  void dispose() {
    // 移除事件监听
    _eventBus.off('call_accept');
    _eventBus.off('call_reject');
    _eventBus.off('call_cancel');
    _eventBus.off('call_hangup');

    // 关闭屏幕常亮
    WakelockPlus.disable();

    // 删除控制器实例
    Get.delete<WebRtcController>();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: () async {
        await _closeVideo();
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildLocalVideoPreview(), // 本地视频预览
              _buildRemoteVideoWindow(), // 远程视频窗口
              _buildControlButtons(), // 控制按钮
            ],
          ),
        ),
      ),
    );
  }

  /// 构建本地视频预览窗口
  Widget _buildLocalVideoPreview() {
    return Obx(() {
      if (controller.rtcList.isEmpty) {
        return _buildLoadingIndicator();
      }
      final localRenderer =
          controller.rtcList[0]['renderer'] as RTCVideoRenderer;
      return RTCVideoView(
        localRenderer,
        mirror: true, // 镜像显示本地视频
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      );
    });
  }

  /// 构建加载指示器
  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.textWhite),
          SizedBox(height: AppSizes.spacing16),
          Text('正在启动摄像头...', style: TextStyle(color: AppColors.textWhite)),
        ],
      ),
    );
  }

  /// 构建远程视频窗口（右上角小窗）
  Widget _buildRemoteVideoWindow() {
    return Positioned(
      top: AppSizes.spacing40,
      right: AppSizes.spacing20,
      child: Container(
        width: AppSizes.spacing120,
        height: AppSizes.spacing160,
        decoration: BoxDecoration(
          color: AppColors.mask,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          border: Border.all(color: AppColors.textWhite.withOpacity(0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radius8),
          child: _buildRemoteVideoPreview(),
        ),
      ),
    );
  }

  /// 构建远程视频预览
  Widget _buildRemoteVideoPreview() {
    return Obx(() {
      if (controller.rtcList.length < 2) {
        return const Center(
          child: Text(
            '等待连接...',
            style: TextStyle(
                color: AppColors.textWhite, fontSize: AppSizes.font12),
          ),
        );
      }
      final remoteRenderer =
          controller.rtcList[1]['renderer'] as RTCVideoRenderer;
      return RTCVideoView(
        remoteRenderer,
        mirror: false,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      );
    });
  }

  /// 构建底部控制按钮
  Widget _buildControlButtons() {
    return Positioned(
      bottom: AppSizes.spacing50,
      left: 0,
      right: 0,
      child: Container(
        height: AppSizes.spacing80,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(
              icon: Icons.switch_camera,
              onPressed: _handleCameraSwitch,
            ),
            _buildControlButton(
              icon: Icons.call_end,
              backgroundColor: AppColors.error,
              iconColor: AppColors.textWhite,
              size: AppSizes.radius35,
              iconSize: AppSizes.iconLarge,
              onPressed: _closeVideo,
            ),
            _buildControlButton(
              icon: _isAudioEnabled ? Icons.mic : Icons.mic_off,
              onPressed: _handleAudioToggle,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建圆形控制按钮
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color backgroundColor = const Color(0x8AFFFFFF), // Colors.white54
    Color iconColor = AppColors.black, // Colors.black
    double size = AppSizes.radius30,
    double iconSize = AppSizes.iconMedium,
  }) {
    return CircleAvatar(
      radius: size,
      backgroundColor: backgroundColor,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: iconColor,
          size: iconSize,
        ),
      ),
    );
  }

  /// 处理摄像头切换事件
  Future<void> _handleCameraSwitch() async {
    final currentId = controller.cameraIndex;
    final isFront = currentId?.contains('1') ?? true;
    final newDeviceId = controller.getVideoDevice(front: !isFront);
    await controller.selectVideoInput(newDeviceId);
  }

  /// 处理音频开关事件
  Future<void> _handleAudioToggle() async {
    await controller.toggleAudio();
    setState(() {
      _isAudioEnabled = !_isAudioEnabled;
    });
  }
}
