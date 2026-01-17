import 'package:get/get.dart';

import '../../../constants/app_message.dart';
import '../../../routes/app_routes.dart';
import '../../models/chats.dart';
import '../../models/friend.dart';
import '../../models/group_member.dart';
import '../../models/message_receive.dart';
import '../../services/notification_service.dart';
import 'chat_base_controller.dart';
import 'chat_group_controller.dart';
import 'chat_message_controller.dart';
import 'chat_session_controller.dart';
import 'chat_video_controller.dart';

/// 聊天协调器控制器
///
/// 职责：
/// - 协调各个子控制器的工作
/// - 提供统一的对外接口（向后兼容）
/// - 处理子控制器之间的通信
/// - 管理控制器的生命周期
///
/// 设计原则：
/// - 单一职责：只负责协调，不包含业务逻辑
/// - 开闭原则：对扩展开放，对修改关闭
/// - 里氏替换：可以完全替代原有的ChatController
/// - 依赖倒置：依赖抽象而非具体实现
///
/// 架构优势：
/// - 避免循环依赖：子控制器之间通过协调器通信
/// - 易于测试：可以单独测试每个子控制器
/// - 易于维护：每个控制器职责清晰
/// - 易于扩展：新增功能只需添加新的子控制器
class ChatCoordinatorController extends ChatBaseController {
  // ==================== 子控制器 ====================

  /// 会话管理控制器
  late final ChatSessionController session;

  /// 消息管理控制器
  late final ChatMessageController message;

  /// 群组管理控制器
  late final ChatGroupController group;

  /// 视频通话控制器
  late final ChatVideoController video;

  // ==================== 向后兼容的属性 ====================

  /// 会话列表（代理到session）
  RxList<Chats> get chatList => session.chatList;

  /// 消息列表（代理到message）
  RxList<IMessage> get messageList => message.messageList;

  /// 群成员列表（代理到group）
  RxMap<String, Map<String, GroupMember>> get groupMembers =>
      group.groupMembers;

  /// 当前会话（代理到session）
  Rx<Chats?> get currentChat => session.currentChat;

  /// 加载状态（聚合所有子控制器的状态）
  RxBool get isLoading =>
      RxBool(session.isLoading.value || message.isSyncing.value);

  /// 加载更多状态（代理到message）
  RxBool get isLoadingMore => message.isLoadingMore;

  /// 是否还有更多消息（代理到message）
  RxBool get hasMoreMessages => message.hasMoreMessages;

  /// 分页大小（代理到message）
  int get pageSize => message.pageSize;

  // ==================== 生命周期 ====================

  @override
  void onInit() {
    super.onInit();

    // 创建子控制器
    _initControllers();

    // 建立子控制器之间的连接
    _setupConnections();

    Get.log('✅ ChatCoordinator 初始化完成');
  }

  @override
  void onClose() {
    // 清理子控制器
    session.onClose();
    message.onClose();
    group.onClose();
    video.onClose();

    super.onClose();
    Get.log('✅ ChatCoordinator 已清理');
  }

  // ==================== 初始化方法 ====================

  /// 初始化子控制器
  void _initControllers() {
    // 会话控制器
    session = ChatSessionController();
    session.onInit();

    // 消息控制器
    message = ChatMessageController();
    message.onInit();

    // 群组控制器
    group = ChatGroupController();
    group.onInit();

    // 视频控制器
    video = ChatVideoController();
    video.onInit();
  }

  /// 建立子控制器之间的连接
  ///
  /// 这里通过回调注入的方式，避免子控制器之间的直接依赖
  void _setupConnections() {
    // 当会话切换时，通知消息控制器加载消息
    session.onChatChanged = (Chats chat) async {
      await message.loadMessages(chat);

      // 进入聊天时，清理该会话的通知
      Get.find<LocalNotificationService>().cancelChatNotifications(chat.chatId);

      // 如果是群聊，加载群成员
      if (chat.chatType == MessageType.groupMessage.code) {
        await group.getGroupMembers(chat.toId);
      }
    };

    // 当消息创建时，通知会话控制器更新
    message.onMessageCreated =
        (IMessage msg, String targetId, bool isMe) async {
      await session.handleCreateOrUpdateChat(msg, targetId, isMe);
    };

    // 当会话需要添加消息时，调用消息控制器
    session.onMessageReceived = (IMessage dto, Chats chat) async {
      await message.addMessageToList(dto, chat);

      // --- 消息通知逻辑 ---
      final isMe = dto.fromId.toString() == userId.value;
      final isCurrentChat = session.currentChat.value?.chatId == chat.chatId;

      // 只有不是自己发送的消息，且不在当前聊天界面时，才触发通知
      if (!isMe && !isCurrentChat) {
        // 检查会话是否免打扰 (isMute)
        if (chat.isMute == 1) return;

        Get.find<LocalNotificationService>().showMessageNotification(
          chatId: chat.chatId,
          senderName: chat.name,
          content: Chats.toChatMessage(dto),
        );
      }
    };

    // 注入获取当前会话的回调
    message.getCurrentChat = () => session.currentChat.value;
  }

  // ==================== 会话管理（代理到session） ====================

  /// 加载会话列表
  Future<void> fetchChats() => session.fetchChats();

  /// 设置当前会话
  Future<void> setCurrentChat(Chats chat) => session.setCurrentChat(chat);

  /// 根据好友设置当前会话
  Future<bool> setCurrentChatByFriend(Friend friend) =>
      session.setCurrentChatByFriend(friend);

  /// 删除会话
  Future<void> removeChat(Chats chat) => session.removeChat(chat);

  /// 创建或更新会话
  Future<void> handleCreateOrUpdateChat(
    IMessage dto,
    String targetId,
    bool isMe,
  ) =>
      session.handleCreateOrUpdateChat(dto, targetId, isMe);

  // ==================== 消息管理（代理到message） ====================

  /// 加载消息列表
  Future<void> handleSetMessageList(Chats chat, {bool loadMore = false}) =>
      message.loadMessages(chat, loadMore: loadMore);

  /// 发送消息
  Future<void> sendMessage(String text) => message.sendTextMessage(text);

  /// 撤回消息
  Future<void> recallMessage(String messageId, int messageType) =>
      message.recallMessage(messageId, messageType);

  /// 同步消息
  Future<void> fetchMessages() => message.syncMessages();

  /// 预览图片
  void previewImage(String currentUrl) => message.previewImage(currentUrl);

  // ==================== 群组管理（代理到group） ====================

  /// 获取群成员列表
  Future<Map<String, GroupMember>?> getGroupMembers(
    String groupId, {
    bool forceRefresh = false,
  }) =>
      group.getGroupMembers(groupId, forceRefresh: forceRefresh);

  /// 获取单个群成员
  GroupMember? getGroupMember(String groupId, String userId) =>
      group.getGroupMember(groupId, userId);

  /// 加载群成员
  Future<void> fetchGroupMembers(String groupId) =>
      group.fetchGroupMembers(groupId);

  // ==================== 视频通话（代理到video） ====================

  /// 发起视频通话
  Future<bool> handleCallVideo(Friend friend) => video.initiateCall(friend);

  /// 处理视频通话消息
  Future<void> handleCallMessage(MessageVideoCallDto dto) =>
      video.handleCallMessage(dto);

  // ==================== 页面交互 ====================

  /// 处理菜单选择
  void onMenuSelected(String value) {
    switch (value) {
      case 'create_group':
        Get.snackbar('提示', '创建群聊功能待实现');
        break;
      case 'scan':
        openScan();
        break;
      case 'add_friend':
        openAddFriend();
        break;
    }
  }

  /// 打开聊天详情
  Future<void> changeCurrentChat(Chats chat) async {
    setCurrentChat(chat);
    Get.toNamed('${Routes.HOME}${Routes.MESSAGE}');
  }
}
