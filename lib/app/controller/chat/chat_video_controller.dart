import 'package:get/get.dart';

import '../../../constants/app_message.dart';
import '../../../exceptions/app_exception.dart';
import '../../../routes/app_routes.dart';
import '../../core/handlers/error_handler.dart';
import '../../models/friend.dart';
import '../../models/message_receive.dart';
import '../../services/event_bus_service.dart';
import '../../ui/widgets/video/video_call_snackbar.dart';
import 'chat_base_controller.dart';

/// 聊天视频通话控制器
///
/// 职责：
/// - 发起视频通话
/// - 处理视频通话消息（接受、拒绝、取消、挂断）
/// - 管理通话状态
///
/// 设计原则：
/// - 单一职责：只负责视频通话相关功能
/// - 事件驱动：通过EventBus处理通话状态变化
/// - 状态管理：使用响应式变量跟踪通话状态
class ChatVideoController extends ChatBaseController {
  // ==================== 响应式状态 ====================

  /// 是否正在通话
  final RxBool isInCall = false.obs;

  /// 通话状态
  final Rx<CallStatus> callStatus = CallStatus.idle.obs;

  /// 当前通话的好友信息
  final Rx<Friend?> currentCallFriend = Rx<Friend?>(null);

  // ==================== 公共方法 ====================

  /// 发起视频通话
  ///
  /// 参数：
  /// - [friend] 要通话的好友
  ///
  /// 返回：
  /// - 是否成功发起通话
  Future<bool> initiateCall(Friend friend) async {
    if (isInCall.value) {
      Get.snackbar('提示', '当前正在通话中');
      return false;
    }

    final res = await apiService.sendCallMessage({
      'fromId': userId.value,
      'toId': friend.friendId,
      'type': MessageType.rtcStartVideoCall.code,
    });

    bool success = false;
    handleApiResponse(res, onSuccess: (data) {
      Get.toNamed(
        '${Routes.HOME}${Routes.VIDEO_CALL}',
        arguments: {
          'userId': userId.value,
          'friendId': friend.friendId,
          'isInitiator': true,
        },
      );
      success = true;
    });
    return success;
  }

  /// 处理视频通话消息
  ///
  /// 参数：
  /// - [dto] 视频通话消息数据
  Future<void> handleCallMessage(MessageVideoCallDto dto) async {
    final code = MessageType.fromCode(dto.type ?? 0);

    switch (code) {
      case MessageType.rtcStartVideoCall:
        await _handleIncomingCall(dto);
        break;

      case MessageType.rtcAccept:
        _handleCallAccepted(dto);
        break;

      case MessageType.rtcReject:
        _handleCallRejected(dto);
        break;

      case MessageType.rtcCancel:
        _handleCallCanceled(dto);
        break;

      case MessageType.rtcHangup:
        _handleCallHungUp(dto);
        break;

      default:
        Get.log('⚠️ 未知的通话消息类型: ${dto.type}');
    }
  }

  /// 接受通话
  ///
  /// 参数：
  /// - [fromId] 发起者ID
  Future<void> acceptCall(String fromId) async {
    final res = await apiService.sendCallMessage({
      'fromId': userId.value,
      'toId': fromId,
      'type': MessageType.rtcAccept.code,
    });

    handleApiResponse(res, onSuccess: (_) {
      Get.toNamed(
        '${Routes.HOME}${Routes.VIDEO_CALL}',
        arguments: {
          'userId': userId.value,
          'friendId': fromId,
          'isInitiator': false,
        },
      );
    });
  }

  /// 拒绝通话
  ///
  /// 参数：
  /// - [fromId] 发起者ID
  Future<void> rejectCall(String fromId) async {
    try {
      await apiService.sendCallMessage({
        'fromId': userId.value,
        'toId': fromId,
        'type': MessageType.rtcReject.code,
      });
      Get.log('✅ 已拒绝通话');
    } catch (e) {
      ErrorHandler.handle(
        AppException('拒绝通话失败', details: e),
        silent: true,
      );
    }
  }

  /// 取消通话
  ///
  /// 参数：
  /// - [toId] 接收者ID
  Future<void> cancelCall(String toId) async {
    try {
      await apiService.sendCallMessage({
        'fromId': userId.value,
        'toId': toId,
        'type': MessageType.rtcCancel.code,
      });
      Get.log('✅ 已取消通话');
    } catch (e) {
      ErrorHandler.handle(
        AppException('取消通话失败', details: e),
        silent: true,
      );
    }
  }

  /// 挂断通话
  ///
  /// 参数：
  /// - [toId] 对方ID
  Future<void> hangupCall(String toId) async {
    try {
      await apiService.sendCallMessage({
        'fromId': userId.value,
        'toId': toId,
        'type': MessageType.rtcHangup.code,
      });
      Get.log('✅ 已挂断通话');
    } catch (e) {
      ErrorHandler.handle(
        AppException('挂断通话失败', details: e),
        silent: true,
      );
    }
  }

  // ==================== 私有方法 ====================

  /// 处理来电
  Future<void> _handleIncomingCall(MessageVideoCallDto dto) async {
    final response = await apiService.getFriendInfo({"friendId": dto.fromId});

    handleApiResponse(response, onSuccess: (data) {
      final friend = data;
      currentCallFriend.value = friend;

      VideoCallSnackbar.show(
        avatar: friend.avatar ?? '',
        username: friend.name ?? '',
        onAccept: () => acceptCall(dto.fromId ?? ""),
        onReject: () => rejectCall(dto.fromId ?? ""),
      );
    });
  }

  /// 处理通话被接受
  void _handleCallAccepted(MessageVideoCallDto dto) {
    Get.find<EventBus>().emit('call_accept', {
      'fromId': dto.fromId,
      'toId': userId.value,
    });
  }

  /// 处理通话被拒绝
  void _handleCallRejected(MessageVideoCallDto dto) {
    Get.snackbar('通话提示', '对方已拒绝通话');
    Get.find<EventBus>().emit('call_reject', dto);
  }

  /// 处理通话被取消
  void _handleCallCanceled(MessageVideoCallDto dto) {
    Get.snackbar('通话提示', '对方已取消通话');
    Get.find<EventBus>().emit('call_cancel', dto);
  }

  /// 处理通话已挂断
  void _handleCallHungUp(MessageVideoCallDto dto) {
    Get.snackbar('通话提示', '通话已结束');
    Get.find<EventBus>().emit('call_hangup', dto);
  }
}

/// 通话状态枚举
enum CallStatus {
  /// 空闲
  idle,

  /// 呼叫中
  calling,

  /// 通话中
  inCall,

  /// 结束中
  ending,
}
