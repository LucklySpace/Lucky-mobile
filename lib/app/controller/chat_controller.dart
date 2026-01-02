import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_im/exceptions/app_exception.dart';
import 'package:flutter_im/utils/objects.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

import '../../constants/app_message.dart';
import '../../routes/app_routes.dart';
import '../api/api_service.dart';
import '../core/handlers/error_handler.dart';
import '../database/app_database.dart';
import '../models/chats.dart';
import '../models/friend.dart';
import '../models/message_receive.dart';
import '../services/event_bus_service.dart';
import '../services/notification_service.dart';
import '../ui/widgets/video/video_call_snackbar.dart';

/// 聊天控制器，管理会话列表、消息列表及相关操作
class ChatController extends GetxController {
  // 会话列表，存储所有聊天会话
  final RxList<Chats> chatList = <Chats>[].obs;

  // 当前会话的消息列表
  final RxList<IMessage> messageList = <IMessage>[].obs;

  // 当前选中的会话
  final Rx<Chats?> currentChat = Rx<Chats?>(null);

  // 加载状态
  final RxBool isLoading = false.obs;

  // 错误信息
  final Rx<String?> errorMessage = Rx<String?>(null);

  // 数据库实例
  final _db = GetIt.instance<AppDatabase>();

  // API 服务
  late final ApiService _apiService;
  late final LocalNotificationService _localNotificationService;

  final _storage = GetStorage();

  // 常量定义
  static const int _successCode = 200;
  static const String _keyUserId = 'userId';

  // 当前用户ID
  final userId = ''.obs;

  // 分页参数
  final int pageSize = 20;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreMessages = true.obs;
  var _currentPage = 0;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _localNotificationService = Get.find<LocalNotificationService>();
  }

  void getUserId() {
    final storedUserId = _storage.read(_keyUserId);
    if (storedUserId != null) {
      userId.value = storedUserId.toString();
    }
  }

  /// 创建或更新会话
  Future<void> handleCreateOrUpdateChat(
      IMessage dto, String targetId, bool isMe) async {
    final chats =
        await _db.chatsDao.getChatByOwnerIdAndToId(userId.value!, targetId!);
    if (chats?.isNotEmpty ?? false) {
      await _updateChat(chats!.first, dto, isMe);
    } else {
      await _createChat(userId.value!, targetId!, dto);
    }
  }

  /// 更新现有会话
  Future<void> _updateChat(Chats chat, IMessage dto, bool isMe) async {
    chat
      ..message = Chats.toChatMessage(dto)
      ..unread = !isMe && currentChat.value?.toId != chat.toId
          ? chat.unread + 1
          : chat.unread
      ..messageTime = dto.messageTime!;

    await _db.chatsDao.updateChat(chat);

    // 优化：移除旧会话并插入到顶部，避免全量排序
    final index = chatList.indexWhere((c) => c.id == chat.id);
    if (index != -1) {
      chatList.removeAt(index);
    }
    chatList.insert(0, chat);

    await _addMessage(dto, chat);
  }

  /// 创建新会话
  Future<void> _createChat(String ownerId, String id, IMessage dto) async {
    final res = await _apiService.getChat({'ownerId': ownerId, 'toId': id});

    await _handleApiResponse(res, onSuccess: (data) async {
      if (data == null) return;

      final chat = Chats.fromJson(data)
        ..message = Chats.toChatMessage(dto)
        ..messageTime = dto.messageTime!;
      if (chat.ownerId == userId.value) {
        await _db.chatsDao.insertChat(chat);
        chatList.insert(0, chat); // 直接插入顶部
      }
      await _addMessage(dto, chat);
    }, errorMessage: '获取会话失败');
  }

  /// 添加消息到数据库和列表
  Future<void> _addMessage(IMessage dto, Chats chat) async {
    if (dto.isSingleMessage) {
      await _db.singleMessageDao
          .insertMessage(IMessage.toSingleMessage(dto, userId.value));
    } else if (dto.isGroupMessage) {
      await _db.groupMessageDao
          .insertMessage(IMessage.toGroupMessage(dto, userId.value));
    }

    if (currentChat.value?.id == chat.id) {
      // 优化：如果是最新消息直接插入头部，否则重新排序
      if (messageList.isEmpty ||
          (dto.messageTime ?? 0) >= (messageList.first.messageTime ?? 0)) {
        messageList.insert(0, dto);
      } else {
        messageList.add(dto);
        messageList
            .sort((a, b) => (b.messageTime ?? 0).compareTo(a.messageTime ?? 0));
      }
    }
  }

  /// 按时间降序排序会话列表
  void _sortChatList() {
    chatList.sort((a, b) => b.messageTime.compareTo(a.messageTime));
    chatList.refresh();
  }

  /// 初始化会话列表
  Future<void> fetchChats() async {
    if (userId.isEmpty) {
      getUserId();
    }

    try {
      isLoading.value = true;
      chatList.clear();

      // final res = await _apiService
      //     .getChatList({'fromId': userId.value, 'sequence': 0});
      // _handleApiResponse(res, onSuccess: (data) {
      //   final chats = data ?? {};
      //   if (chats is List<dynamic>) {
      //
      //     for (var dynamic in chats) {
      //       Chats chat = Chats.fromJson(dynamic);
      //       chatList.add(chat);
      //     }
      //     _sortChatList();
      //   }
      //   // 成功标记已读
      // }, errorMessage: '获取会话列表失败');

      final chats = await _db.chatsDao.getAllChats(userId.value);
      if (chats?.isNotEmpty ?? false) {
        chatList.addAll(chats as Iterable<Chats>);
        _sortChatList();
      }
    } catch (e) {
      ErrorHandler.handle(AppException('加载聊天列表失败', details: e));
    } finally {
      isLoading.value = false;
    }
  }

  /// 加载消息列表，支持分页
  Future<void> handleSetMessageList(Chats chat, {bool loadMore = false}) async {
    if (!loadMore) {
      messageList.clear();
      _currentPage = 0;
      hasMoreMessages.value = true;
    }
    if (!hasMoreMessages.value) return;

    try {
      isLoadingMore.value = true;
      final messageType = IMessageType.fromCode(chat.chatType);
      List<IMessage> newMessages = [];

      if (messageType == IMessageType.singleMessage) {
        final messages = await _db.singleMessageDao.getMessagesByPage(
          chat.id,
          chat.ownerId,
          pageSize,
          _currentPage * pageSize,
        );
        newMessages = messages?.map(IMessage.fromSingleMessage).toList() ?? [];
      } else if (messageType == IMessageType.groupMessage) {
        final messages = await _db.groupMessageDao.getMessagesByPage(
          userId.value,
          pageSize,
          _currentPage * pageSize,
        );
        newMessages = messages?.map(IMessage.fromGroupMessage).toList() ?? [];
      }

      hasMoreMessages.value = newMessages.length >= pageSize;
      messageList.addAll(newMessages);
      _currentPage++;
      messageList.refresh();
    } catch (e) {
      ErrorHandler.handle(AppException('加载消息列表失败', details: e));
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// 删除会话
  Future<void> removeChat(Chats chat) async {
    try {
      chatList.remove(chat);
      await _db.chatsDao.deleteChat(chat.id);
    } catch (e) {
      ErrorHandler.handle(AppException('删除聊天失败', details: e));
    } finally {
      await fetchChats();
    }
  }

  /// 发送文本消息
  Future<void> sendMessage(String text) async {
    if (text.isEmpty || currentChat.value == null) return;
    final chat = currentChat.value!;
    try {
      final messageTime = DateTime.now().millisecondsSinceEpoch;
      final messageBody = {'text': text};
      final params = _buildMessageBody(chat, messageBody, messageTime);
      final res = chat.chatType == IMessageType.singleMessage.code
          ? await _apiService.sendSingleMessage(params)
          : await _apiService.sendGroupMessage(params);

      await _handleApiResponse(res, onSuccess: (data) async {
        IMessage parsedMessage = IMessage.fromJson(data);
        await handleCreateOrUpdateChat(parsedMessage, chat.toId, true);
      }, errorMessage: '发送消息失败');
    } catch (e) {
      _showError('发送消息失败: $e');
    }
  }

  /// 构建消息参数
  Map<String, dynamic> _buildMessageBody(
      Chats chat, Map<String, dynamic> messageBody, int messageTime) {
    if (chat.chatType == IMessageType.singleMessage.code) {
      return {
        'fromId': userId.value,
        'toId': chat.id,
        'messageBody': messageBody,
        'messageTempId': Uuid().v4(),
        'messageContentType': IMessageContentType.text.code,
        'messageTime': messageTime.toString(),
        'messageType': IMessageType.singleMessage.code,
      };
    } else if (chat.chatType == IMessageType.groupMessage.code) {
      return {
        'fromId': userId.value,
        'groupId': chat.id,
        'messageBody': messageBody,
        'messageTempId': Uuid().v4(),
        'messageContentType': IMessageContentType.text.code,
        'messageTime': messageTime.toString(),
        'messageType': IMessageType.groupMessage.code,
      };
    }
    throw Exception('不支持的消息类型');
  }

  /// 设置当前会话并标记已读
  Future<void> setCurrentChat(Chats chat) async {
    currentChat.value = chat;
    chat.unread = 0;
    await _db.chatsDao.updateChat(chat);
    chatList.refresh();
    messageList.clear();
    try {
      final res = await _apiService.readChat({
        'chatType': chat.chatType,
        'fromId': chat.ownerId,
        'toId': chat.id,
      });

      // 使用统一处理方法，但忽略成功回调，仅用于错误检查
      // 由于 _handleApiResponse 会抛出异常，我们需要捕获它来实现 silent 效果
      _handleApiResponse(res, onSuccess: (_) {
        // 成功标记已读
      }, errorMessage: '标记消息已读失败');
    } catch (e) {
      // 标记已读失败不阻断流程，仅记录
      ErrorHandler.handle(AppException('标记消息已读失败', details: e), silent: true);
    }

    await handleSetMessageList(chat);
  }

  /// 发起视频通话
  Future<bool> handleCallVideo(Friend friend) async {
    try {
      final res = await _apiService.sendCallMessage({
        'fromId': userId.value,
        'toId': friend.friendId,
        'type': IMessageContentType.rtcCall.code,
      });

      return await _handleApiResponse(res, onSuccess: (data) {
            Get.toNamed('${Routes.HOME}${Routes.VIDEO_CALL}', arguments: {
              'userId': userId.value,
              'friendId': friend.friendId,
              'isInitiator': true,
            });
            return true;
          }, errorMessage: '发起通话失败') ??
          false;
    } catch (e) {
      _showError('发起通话失败: $e');
      return false;
    }
  }

  /// 处理视频通话消息
  Future<void> handleCallMessage(MessageVideoCallDto dto) async {
    if (dto.type == IMessageContentType.rtcCall.code) {
      final response = await _apiService
          .getFriendInfo({'fromId': userId.value, 'toId': dto.fromId});

      _handleApiResponse(response, onSuccess: (data) {
        final friend = Friend.fromJson(data);

        VideoCallSnackbar.show(
          avatar: friend.avatar ?? '',
          username: friend.name ?? '',
          onAccept: () async {
            final res = await _apiService.sendCallMessage({
              'fromId': userId.value,
              'toId': dto.fromId,
              'type': IMessageContentType.rtcAccept.code,
            });

            _handleApiResponse(res, onSuccess: (_) {
              Get.toNamed('${Routes.HOME}${Routes.VIDEO_CALL}', arguments: {
                'userId': userId.value,
                'friendId': dto.fromId,
                'isInitiator': false,
              });
            }, errorMessage: '接受通话失败');
          },
          onReject: () => _apiService.sendCallMessage({
            'fromId': userId.value,
            'toId': dto.fromId,
            'type': IMessageContentType.rtcReject.code,
          }),
        );
      }, errorMessage: '获取用户信息失败');
    } else if (dto.type == IMessageContentType.rtcAccept.code) {
      Get.find<EventBus>()
          .emit('call_accept', {'fromId': dto.fromId, 'toId': userId.value});
    } else if (dto.type == IMessageContentType.rtcReject.code) {
      Get.snackbar('通话提示', '对方已拒绝通话');
      Get.find<EventBus>().emit('call_reject', dto);
    } else if (dto.type == IMessageContentType.rtcCancel.code) {
      Get.snackbar('通话提示', '对方已取消通话');
      Get.find<EventBus>().emit('call_cancel', dto);
    } else if (dto.type == IMessageContentType.rtcHangup.code) {
      Get.snackbar('通话提示', '通话已结束');
      Get.find<EventBus>().emit('call_hangup', dto);
    }
  }

  /// 同步会话和消息
  Future<void> fetchMessages() async {
    if (userId.isEmpty) {
      getUserId();
    }

    try {
      final lastMessageTime = await _getLastMessageTimestamp();
      final response = await _apiService.getMessageList({
        'fromId': userId.value,
        'sequence': lastMessageTime,
      });

      await _handleApiResponse(response, onSuccess: (data) async {
        final messages = data ?? {};
        // 这里 messages 是 Map<String, dynamic>，但 data 是 dynamic
        if (messages is Map<String, dynamic>) {
          await _processSyncedMessages(
              messages, IMessageType.singleMessage.code);
          await _processSyncedMessages(
              messages, IMessageType.groupMessage.code);
        }
      }, errorMessage: '同步消息失败');
    } catch (e) {
      // 同步失败不应该打断用户，使用 silent logging
      ErrorHandler.handle(AppException('同步会话和消息失败', details: e), silent: true);
    }
  }

  /// 处理同步消息
  Future<void> _processSyncedMessages(
      Map<String, dynamic> messages, int messageType) async {
    final messagesList = messages[messageType.toString()] ?? [];

    // 如果没有消息需要处理，直接返回
    if (messagesList.isEmpty) return;

    // 使用compute函数在isolate中处理消息解析，避免阻塞UI线程
    final List<IMessage> parsedMessages = await compute(_parseMessages, {
      'messagesList': messagesList,
      'messageType': messageType,
    });

    // 分批处理解析后的消息，避免阻塞UI线程
    const batchSize = 50;
    for (int i = 0; i < parsedMessages.length; i += batchSize) {
      final end = (i + batchSize < parsedMessages.length)
          ? i + batchSize
          : parsedMessages.length;
      final batch = parsedMessages.sublist(i, end);

      for (final message in batch) {
        var id = message.messageType == IMessageType.singleMessage.code
            ? (IMessage.toSingleMessage(message, userId.value)).fromId ==
                    userId.value
                ? message.toId
                : message.fromId
            : (IMessage.toGroupMessage(message, userId.value)).groupId;

        await handleCreateOrUpdateChat(message, id!, false);
      }

      // 每处理一批就让出控制权，避免阻塞UI线程
      await Future.delayed(Duration.zero);
    }
  }

  /// 在isolate中执行的消息解析函数
  static List<IMessage> _parseMessages(Map<String, dynamic> params) {
    final messagesList = params['messagesList'] as List;
    final messageType = params['messageType'] as int;

    return messagesList.map((message) {
      final clonedMessage = Map<String, dynamic>.from(message);
      clonedMessage['messageType'] = messageType;
      clonedMessage['messageBody'] = jsonDecode(clonedMessage['messageBody']);
      return IMessage.fromJson(clonedMessage);
    }).toList();
  }

  /// 获取最后消息时间戳
  Future<int> _getLastMessageTimestamp() async {
    final lastSingle = await _db.singleMessageDao.getLastMessage(userId.value);
    final lastGroup = await _db.groupMessageDao.getLastMessage(userId.value);
    return (lastSingle?.messageTime ?? 0) > (lastGroup?.messageTime ?? 0)
        ? lastSingle?.messageTime ?? 0
        : lastGroup?.messageTime ?? 0;
  }

  /// 根据好友设置当前会话
  Future<bool> setCurrentChatByFriend(Friend friend) async {
    try {
      final chats = chatList
          .where((c) => c.ownerId == userId.value && c.toId == friend.friendId)
          .toList();
      if (chats.isNotEmpty) {
        await setCurrentChat(chats.first);
        return true;
      }

      final res = await _apiService.createChat({
        'fromId': userId.value,
        'toId': friend.friendId,
        'chatType': IMessageType.singleMessage.code,
      });

      return await _handleApiResponse(res, onSuccess: (data) async {
            final chat = Chats.fromJson(data);
            await _db.chatsDao.insertChat(chat);
            chatList.add(chat);
            await setCurrentChat(chat);
            return true;
          }, errorMessage: '创建会话失败') ??
          false;
    } catch (e) {
      _showError('创建会话失败: $e');
      return false;
    }
  }

  /// 撤回消息
  Future<void> recallMessage(String messageId, int messageType) async {
    try {
      final res = await _apiService.recallMessage({
        'fromId': userId.value,
        'messageId': messageId,
        'messageType': messageType,
      });

      _handleApiResponse(res, onSuccess: (_) {
        Get.snackbar('成功', '消息已撤回');
        // TODO: 更新消息列表以显示撤回状态
        messageList.removeWhere((m) => m.messageId == messageId);
        messageList.refresh();
      }, errorMessage: '撤回消息失败');
    } catch (e) {
      _showError('撤回消息失败: $e');
    }
  }

  // --- 页面交互逻辑 ---

  /// 处理菜单选择
  void onMenuSelected(String value) {
    switch (value) {
      case 'create_group':
        // TODO: 实现创建群聊
        Get.snackbar('提示', '创建群聊功能待实现');
        break;
      case 'scan':
        Get.toNamed('${Routes.HOME}${Routes.SCAN}');
        break;
      case 'add_friend':
        Get.toNamed('${Routes.HOME}${Routes.ADD_FRIEND}');
        break;
    }
  }

  /// 打开聊天详情
  void openChat(Chats chat) {
    setCurrentChat(chat);
    Get.toNamed('${Routes.HOME}${Routes.MESSAGE}');
  }

  /// 打开搜索页面
  void openSearch() {
    Get.toNamed('${Routes.HOME}${Routes.SEARCH}');
  }

  /// 统一处理 API 响应
  dynamic _handleApiResponse(
    Map<String, dynamic>? response, {
    required dynamic Function(dynamic) onSuccess,
    required String errorMessage,
  }) {
    final code = Objects.safeGet<int>(response, 'code');
    if (code == _successCode) {
      return onSuccess(response?['data']);
    }
    final msg = Objects.safeGet<String>(response, 'message', errorMessage);
    throw BusinessException(msg.toString());
  }

  /// 显示错误提示
  void _showError(dynamic error) {
    ErrorHandler.handle(error);
  }
}
