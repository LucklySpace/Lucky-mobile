import 'package:get/get.dart';

import '../../../constants/app_message.dart';
import '../../../exceptions/app_exception.dart';
import '../../../routes/app_routes.dart';
import '../../core/handlers/error_handler.dart';
import '../../models/chats.dart';
import '../../models/friend.dart';
import '../../models/message_receive.dart';
import 'chat_base_controller.dart';

/// 聊天会话控制器
///
/// 职责：
/// - 管理会话列表（CRUD）
/// - 处理会话的创建、更新、删除
/// - 切换当前会话
/// - 同步会话数据
///
/// 设计原则：
/// - 单一职责：只负责会话管理，不涉及消息操作
/// - 接口隔离：提供最小必要的公共接口
/// - 依赖注入：通过构造函数注入依赖
class ChatSessionController extends ChatBaseController {
  // ==================== 响应式状态 ====================

  /// 会话列表
  final RxList<Chats> chatList = <Chats>[].obs;

  /// 当前选中的会话
  final Rx<Chats?> currentChat = Rx<Chats?>(null);

  // ==================== 公共方法 ====================

  /// 初始化会话列表
  ///
  /// 从本地数据库加载所有会话并按时间排序
  Future<void> fetchChats() async {
    // 确保userId已加载
    if (userId.isEmpty) {
      getUserId();
    }

    // userId仍为空，无法继续
    if (userId.isEmpty) {
      showError('用户ID未初始化，无法加载会话列表');
      return;
    }

    try {
      isLoading.value = true;
      chatList.clear();

      // 从本地数据库加载会话列表
      final chats = await db.chatsDao.getAllChats(userId.value);

      if (chats != null && chats.isNotEmpty) {
        chatList.addAll(chats);
        sortChatList();
        Get.log('✅ 已加载 ${chats.length} 个会话');
      } else {
        Get.log('📭 暂无会话记录');
      }
    } catch (e) {
      ErrorHandler.handle(AppException('加载聊天列表失败', details: e));
    } finally {
      isLoading.value = false;
    }
  }

  /// 设置当前会话
  ///
  /// 参数：
  /// - [chat] 要设置的会话
  ///
  /// 功能：
  /// - 切换当前会话
  /// - 标记消息已读
  /// - 触发消息加载回调
  Future<void> setCurrentChat(Chats chat) async {
    currentChat.value = chat;
    chat.unread = 0;
    await db.chatsDao.updateChat(chat);
    chatList.refresh();

    try {
      final res = await apiService.readChat({
        'chatId': chat.id,
      });

      if (res.isSuccess) {
        // 成功标记已读
      } else {
        throw BusinessException(res.message);
      }
    } catch (e) {
      // 标记已读失败不阻断流程，仅记录
      ErrorHandler.handle(
        AppException('标记消息已读失败', details: e),
        silent: true,
      );
    }

    // 通知外部加载消息
    onChatChanged?.call(chat);
  }

  /// 根据好友设置当前会话
  ///
  /// 参数：
  /// - [friend] 好友信息
  ///
  /// 返回：
  /// - 是否成功设置会话
  Future<bool> setCurrentChatByFriend(Friend friend) async {
    try {
      final chats = chatList
          .where((c) => c.ownerId == userId.value && c.toId == friend.friendId)
          .toList();
      if (chats.isNotEmpty) {
        await setCurrentChat(chats.first);
        return true;
      }

      final res = await apiService.createChat({
        'targetId': friend.friendId,
        'type': MessageType.singleMessage.code,
      });

      if (res.isSuccess && res.data != null) {
        final chat = res.data!;
        await db.chatsDao.insertChat(chat);
        chatList.add(chat);
        await setCurrentChat(chat);
        return true;
      } else {
        throw BusinessException(res.message);
      }
    } catch (e) {
      showError('创建会话失败: $e');
      return false;
    }
  }

  /// 删除会话
  ///
  /// 参数：
  /// - [chat] 要删除的会话
  Future<void> removeChat(Chats chat) async {
    try {
      chatList.remove(chat);
      await db.chatsDao.deleteChat(chat.id);
    } catch (e) {
      ErrorHandler.handle(AppException('删除聊天失败', details: e));
    } finally {
      await fetchChats();
    }
  }

  /// 创建或更新会话
  ///
  /// 参数：
  /// - [dto] 消息数据
  /// - [targetId] 目标ID（对方ID或群组ID）
  /// - [isMe] 是否为自己发送的消息
  Future<void> handleCreateOrUpdateChat(
    IMessage dto,
    String targetId,
    bool isMe,
  ) async {
    final chats = await db.chatsDao.getChatByOwnerIdAndToId(
      userId.value,
      targetId,
    );

    if (chats != null && chats.isNotEmpty) {
      await _updateChat(chats.first, dto, isMe);
    } else {
      await _createChat(userId.value, targetId, dto);
    }
  }

  /// 跳转到聊天详情页
  void changeCurrentChat(Chats chat) {
    setCurrentChat(chat);
    Get.toNamed('${Routes.HOME}${Routes.MESSAGE}');
  }

  /// 更新草稿
  ///
  /// 参数：
  /// - [chatId] 会话ID
  /// - [draft] 草稿内容
  Future<void> updateDraft(String chatId, String? draft) async {
    final index = chatList.indexWhere((c) => c.chatId == chatId);
    if (index != -1) {
      final chat = chatList[index];
      if (chat.draft == draft) return;

      chat.draft = draft;
      await db.chatsDao.updateChat(chat);
      chatList[index] = chat;
      chatList.refresh();
      Get.log('📝 更新草稿 [$chatId]: $draft');
    }
  }

  // ==================== 私有方法 ====================

  /// 更新现有会话
  Future<void> _updateChat(Chats chat, IMessage dto, bool isMe) async {
    chat
      ..message = Chats.toChatMessage(dto)
      ..unread = !isMe && currentChat.value?.toId != chat.toId
          ? chat.unread + 1
          : chat.unread
      ..sequence = dto.sequence
      ..messageTime = dto.messageTime;

    await db.chatsDao.updateChat(chat);

    // 优化：移除旧会话并插入到顶部，避免全量排序
    final index = chatList.indexWhere((c) => c.id == chat.id);
    if (index != -1) {
      chatList.removeAt(index);
    }
    chatList.insert(0, chat);

    // 通知外部添加消息
    onMessageReceived?.call(dto, chat);
  }

  /// 创建新会话
  Future<void> _createChat(String ownerId, String id, IMessage dto) async {
    final res = await apiService.createChat({
      'targetId': id,
      'type': dto.messageType,
    });

    if (res.isSuccess && res.data != null) {
      final chat = res.data!
        ..message = Chats.toChatMessage(dto)
        ..messageTime = dto.messageTime;
      if (chat.ownerId == userId.value) {
        await db.chatsDao.insertChat(chat);
        chatList.insert(0, chat); // 直接插入顶部
      }
      await onMessageReceived?.call(dto, chat);
    } else {
      Get.log('❌ 获取会话失败: ${res.message}');
    }
  }

  /// 按时间降序排序会话列表
  void sortChatList() {
    chatList.sort((a, b) => b.messageTime.compareTo(a.messageTime));
    chatList.refresh();
  }

  // ==================== 回调 ====================

  /// 会话切换回调（用于触发消息加载）
  void Function(Chats chat)? onChatChanged;

  /// 消息接收回调（用于添加消息到列表）
  Future<void> Function(IMessage message, Chats chat)? onMessageReceived;
}
