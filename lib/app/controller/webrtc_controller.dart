import 'package:flutter/foundation.dart';
import 'package:flutter_im/exceptions/app_exception.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/base/base_controller.dart';
import '../core/handlers/error_handler.dart';

/// WebRTC 控制器，管理视频通话的推流、拉流及设备配置
/// 1. 为本地预览创建仅含视频轨道的流，避免音频回路导致啸声。
/// 2. 统一音频采集参数，启用回声消除、自动增益和噪声抑制。
/// 3. 规范化错误处理和日志记录，提升代码可维护性。
class WebRtcController extends BaseController {
  // 常量定义
  static const _mediaConstraints = {
    'audio': {
      'echoCancellation': true, // 回声消除
      'autoGainControl': true, // 自动增益控制
      'noiseSuppression': true, // 噪声抑制
    },
    'video': {
      'facingMode': 'user', // 默认使用前置摄像头
      'mirror': true, // 镜像显示
    },
  };
  static const _iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'}, // STUN 服务器
  ];
  static const _maxRetries = 3; // 拉流重试次数
  static const _retryDelay = Duration(seconds: 1); // 重试间隔

  // 响应式状态
  final RxInt isConnectState = 0.obs; // 推流状态：0 未开始，1 成功，2 失败
  final RxList<Map<String, dynamic>> rtcList =
      <Map<String, dynamic>>[].obs; // 视频流列表
  String? cameraIndex; // 当前选中的视频输入设备ID
  MediaStream? _localStream; // 本地媒体流
  VideoSize? videoSize; // 视频分辨率
  List<RTCRtpSender> senders = []; // WebRTC 发送器列表
  List<webrtc.MediaDeviceInfo> devices = []; // 设备信息列表

  @override
  void onInit() {
    super.onInit();

    /// 初始化 WebRTC 控制器
  }

  // --- 视频流管理 ---

  /// 添加远程视频流
  /// @param url API 地址
  /// @param webrtcUrl WebRTC 流地址
  /// @param callback 成功或失败回调
  /// @return 是否成功添加远程流
  Future<bool> addRemoteLive(String url, String webrtcUrl,
      {Function(bool)? callback}) async {
    try {
      for (var retry = 0; retry < _maxRetries; retry++) {
        try {
          final renderId = DateTime.now().millisecondsSinceEpoch;
          final remoteRenderer = RTCVideoRenderer();
          await remoteRenderer.initialize();

          final pc = await _createPeerConnection();
          pc.onTrack = (event) {
            if (event.track.kind == 'video') {
              remoteRenderer.srcObject = event.streams[0];
            }
          };

          final offer = await pc.createOffer({
            'mandatory': {
              'OfferToReceiveAudio': true,
              'OfferToReceiveVideo': true
            },
          });
          await pc.setLocalDescription(offer);

          pc.onConnectionState = (state) => _onConnectionState(state, renderId);
          pc.onIceConnectionState =
              (state) => _onIceConnectionState(state, renderId);

          final answer =
              await apiService.webRtcHandshake(url, webrtcUrl, offer.sdp ?? '');
          // answer 已经在 ApiService 中校验并抛出异常，如果为 null 则说明某种未捕获异常
          await pc.setRemoteDescription(answer);

          rtcList.add({
            'renderId': renderId,
            'pc': pc,
            'renderer': remoteRenderer,
            'self': false,
          });

          callback?.call(true);
          return true;
        } catch (e) {
          if (retry == _maxRetries - 1) {
            showError(AppException('拉流重试失败', details: e));
            callback?.call(false);
            return false;
          }
          await Future.delayed(_retryDelay);
        }
      }
      return false;
    } catch (e) {
      showError(AppException('添加远程视频失败', details: e));
      callback?.call(false);
      return false;
    }
  }

  /// 开启本地摄像头预览
  /// 创建仅含视频轨道的流用于预览，避免音频回路啸声
  Future<void> openVideo() async {
    try {
      final renderId = DateTime.now().millisecondsSinceEpoch;
      final localRenderer = RTCVideoRenderer();
      await localRenderer.initialize();

      final pc = await _createPeerConnection();

      // 应用视频尺寸约束
      final constraints = Map<String, dynamic>.from(_mediaConstraints);
      if (videoSize != null) {
        constraints['video']['width'] = videoSize!.width;
        constraints['video']['height'] = videoSize!.height;
      }

      // 获取完整音视频流用于推流
      _localStream =
          await webrtc.navigator.mediaDevices.getUserMedia(constraints);

      // 添加轨道到 PeerConnection
      for (var track in _localStream!.getTracks()) {
        senders.add(await pc.addTrack(track, _localStream!));
      }

      // 创建仅含视频轨道的流用于本地预览
      final videoPreviewStream =
          await webrtc.createLocalMediaStream('videoPreview');
      for (var track in _localStream!.getVideoTracks()) {
        videoPreviewStream.addTrack(track);
      }
      localRenderer.srcObject = videoPreviewStream;

      rtcList.insert(0, {
        'renderId': renderId,
        'pc': pc,
        'renderer': localRenderer,
        'self': true,
      });
    } catch (e) {
      showError(AppException('开启本地摄像头失败', details: e));
    }
  }

  /// 建立本地视频推流
  /// @param url API 地址
  /// @param webrtcUrl WebRTC 流地址
  /// @param callback 成功或失败回调
  /// @return 是否成功推流
  Future<bool> addLocalMedia(String url, String webrtcUrl,
      {Function(bool)? callback}) async {
    try {
      if (rtcList.isEmpty) throw BusinessException('本地流未初始化');
      final pc = rtcList[0]['pc'] as RTCPeerConnection;
      final renderId = rtcList[0]['renderId'] as int;

      pc.onConnectionState = (state) => _onConnectionState(state, renderId);
      pc.onIceConnectionState =
          (state) => _onIceConnectionState(state, renderId);
      pc.getStats().then(_peerConnectionState);

      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      final answer = await apiService
          .webRtcHandshake(url, webrtcUrl, offer.sdp ?? '', type: 'publish');
      await pc.setRemoteDescription(answer);

      callback?.call(true);
      return true;
    } catch (e) {
      showError(AppException('开启本地推流失败', details: e));
      callback?.call(false);
      return false;
    }
  }

  /// 关闭指定视频流
  /// @param renderId 流标识
  Future<void> closeRenderId(int renderId) async {
    try {
      final index = rtcList.indexWhere((item) => item['renderId'] == renderId);
      if (index == -1) {
        showError(AppException('视频流不存在: $renderId'), silent: true);
        return;
      }

      final item = rtcList[index];
      await item['pc']?.close();
      await item['renderer']?.srcObject?.dispose();
      await item['renderer']?.dispose();
      rtcList.removeAt(index);
    } catch (e) {
      showError(AppException('关闭视频流失败', details: e), silent: true);
    }
  }

  /// 关闭所有视频流并释放资源
  Future<void> close() async {
    try {
      // 停止本地流轨道
      _localStream?.getTracks().forEach((track) => track.stop());
      _localStream?.dispose();
      _localStream = null;

      // 释放所有 PeerConnection 和渲染器
      for (var item in rtcList) {
        try {
          await item['pc']?.close();
        } catch (e) {
          showError(AppException('关闭 PeerConnection 时出错', details: e),
              silent: true);
        }

        try {
          await item['renderer']?.srcObject?.dispose();
        } catch (e) {
          showError(AppException('释放渲染器源对象时出错', details: e), silent: true);
        }

        try {
          await item['renderer']?.dispose();
        } catch (e) {
          showError(AppException('释放渲染器时出错', details: e), silent: true);
        }
      }

      rtcList.clear();
      isConnectState.value = 0;
      cameraIndex = null;
      senders.clear();

      Get.log('所有视频流和资源已成功关闭');
    } catch (e) {
      showError(AppException('关闭所有视频流失败', details: e), silent: true);
    }
  }

  // --- 设备管理 ---

  /// 加载设备列表
  Future<void> loadDevices() async {
    try {
      if (WebRTC.platformIsAndroid || WebRTC.platformIsIOS) {
        for (var permission in [
          Permission.bluetooth,
          Permission.bluetoothConnect
        ]) {
          final status = await permission.request();
          if (status.isPermanentlyDenied) {
            showError(AppException('${permission.toString()} 权限被永久拒绝'));
          }
        }
      }

      devices = await webrtc.navigator.mediaDevices.enumerateDevices();
      cameraIndex = getVideoDevice();
      Get.log('当前视频输入设备ID: $cameraIndex');
    } catch (e) {
      showError(AppException('加载设备列表失败', details: e));
    }
  }

  /// 切换摄像头
  /// @param deviceId 设备ID
  Future<void> selectVideoInput(String? deviceId) async {
    try {
      cameraIndex = deviceId;

      final mediaConstraints = {
        'audio': true,
        'video': {
          if (cameraIndex != null && kIsWeb) 'deviceId': cameraIndex,
          if (cameraIndex != null && !kIsWeb)
            'optional': [
              {'sourceId': cameraIndex}
            ],
          'frameRate': 60,
        }
      };
      await _updateLocalStream(mediaConstraints);
    } catch (e) {
      showError(AppException('切换摄像头失败', details: e));
    }
  }

  /// 设置视频分辨率
  /// @param width 宽度
  /// @param height 高度
  Future<void> setVideoSize(int width, int height) async {
    try {
      videoSize = VideoSize(width, height);
      final constraints = _buildMediaConstraints(cameraIndex, frameRate: 60);
      await _updateLocalStream(constraints);
    } catch (e) {
      showError(AppException('设置视频分辨率失败', details: e));
    }
  }

  /// 切换麦克风状态
  Future<void> toggleAudio() async {
    try {
      if (_localStream == null) return;
      final audioTracks = _localStream!.getAudioTracks();
      for (var track in audioTracks) {
        track.enabled = !track.enabled;
      }
      if (_mediaConstraints['audio'] is Map) {
        _mediaConstraints['audio']?['enabled'] = audioTracks.first.enabled;
      } else {
        _mediaConstraints['audio'] =
            audioTracks.first.enabled as Map<String, Object>;
      }
    } catch (e) {
      showError(AppException('切换麦克风状态失败', details: e));
    }
  }

  // --- 状态回调 ---

  /// WebRTC 连接状态回调
  void _onConnectionState(RTCPeerConnectionState state, int index) {
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        Get.log('$index 连接成功');
        isConnectState.value = 1;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        Get.log('$index 连接失败');
        isConnectState.value = 2;
        break;
      default:
        Get.log('$index 连接尚未建立');
    }
  }

  /// WebRTC ICE 连接状态回调
  void _onIceConnectionState(RTCIceConnectionState state, int index) {
    switch (state) {
      case RTCIceConnectionState.RTCIceConnectionStateConnected:
        Get.log('$index ICE 连接成功，开始推流');
        break;
      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        showError('$index ICE 连接失败');
        break;
      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        showError('$index ICE 连接断开，可尝试重新连接');
        break;
      default:
    }
  }

  /// 推流状态回调
  void _peerConnectionState(dynamic state) {
    Get.log('当前推流状态: $state');
  }

  // --- 辅助方法 ---

  /// 显示错误提示
  @override
  void showError(dynamic error, {bool silent = false}) {
    ErrorHandler.handle(error, silent: silent);
  }

  /// 创建 PeerConnection
  Future<RTCPeerConnection> _createPeerConnection() async {
    return createPeerConnection({
      'sdpSemantics': 'unified-plan',
      'iceServers': _iceServers,
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
    });
  }

  /// 构建媒体约束
  Map<String, dynamic> _buildMediaConstraints(String? deviceId,
      {int? frameRate}) {
    final constraints = Map<String, dynamic>.from(_mediaConstraints);
    if (deviceId != null) {
      constraints['video'][kIsWeb ? 'deviceId' : 'optional'] = kIsWeb
          ? deviceId
          : [
              {'sourceId': deviceId}
            ];
    }
    if (frameRate != null) {
      constraints['video']['frameRate'] = frameRate;
    }
    if (videoSize != null) {
      constraints['video']['width'] = videoSize!.width;
      constraints['video']['height'] = videoSize!.height;
    }
    return constraints;
  }

  /// 更新本地流
  Future<void> _updateLocalStream(Map<String, dynamic> constraints) async {
    try {
      if (rtcList.isEmpty) return;
      final localRenderer = rtcList[0]['renderer'] as RTCVideoRenderer;

      // 停止旧轨道
      _localStream?.getTracks().forEach((track) => track.stop());
      localRenderer.srcObject = null;

      // 获取新流
      _localStream =
          await webrtc.navigator.mediaDevices.getUserMedia(constraints);
      localRenderer.srcObject = _localStream;

      // 更新视频轨道
      final newTrack = _localStream?.getVideoTracks().first;
      final sender = senders.firstWhereOrNull((s) => s.track?.kind == 'video');
      if (sender != null && newTrack != null) {
        final params = sender.parameters;
        params.degradationPreference =
            RTCDegradationPreference.MAINTAIN_RESOLUTION;
        await sender.setParameters(params);
        await sender.replaceTrack(newTrack);
      }
    } catch (e) {
      showError(AppException('更新本地流失败', details: e));
    }
  }

  /// 获取视频设备（优先前置摄像头）
  String getVideoDevice({bool front = true}) {
    for (final device in devices) {
      if (device.kind == 'videoinput' &&
          device.label.contains(front ? 'front' : 'back')) {
        return device.deviceId;
      }
    }
    return devices.isNotEmpty && devices.first.kind == 'videoinput'
        ? devices.first.deviceId
        : '';
  }
}

/// WebRTC 流地址解析器
class WebRTCUri {
  late String api; // API 地址
  late String streamUrl; // 流地址

  /// 解析 WebRTC 流地址
  /// @param url 原始地址
  /// @param type 流类型（play 或 publish）
  static WebRTCUri parse(String url, {String type = 'play'}) {
    final uri = Uri.parse(url);
    var schema = uri.queryParameters['schema'] ?? 'https';
    var port = uri.port > 0 ? uri.port : (schema == 'https' ? 443 : 1985);
    var apiPath = uri.queryParameters['play'] ??
        (type == 'publish' ? '/rtc/v1/publish/' : '/rtc/v1/play/');

    final apiParams = uri.queryParameters.entries
        .where((e) => !['api', 'play', 'schema'].contains(e.key))
        .map((e) => '${e.key}=${e.value}')
        .toList();

    final apiUrl =
        '$schema://${uri.host}:$port$apiPath${apiParams.isNotEmpty ? '?' + apiParams.join('&') : ''}';

    final result = WebRTCUri()
      ..api = apiUrl
      ..streamUrl = url;
    Get.log('解析 URL: $url -> api=$apiUrl, stream=${result.streamUrl}');
    return result;
  }
}

/// 视频分辨率辅助类
class VideoSize {
  const VideoSize(this.width, this.height);

  factory VideoSize.fromString(String size) {
    final parts = size.split('x');
    return VideoSize(int.parse(parts[0]), int.parse(parts[1]));
  }

  final int width;
  final int height;

  @override
  String toString() => '$width x $height';
}
