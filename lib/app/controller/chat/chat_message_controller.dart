import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_im/exceptions/app_exception.dart';
import 'package:get/get.dart';

import '../../../constants/app_constant.dart';
import '../../../constants/app_message.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/validator.dart';
import '../../core/handlers/error_handler.dart';
import '../../models/chats.dart';
import '../../models/message_receive.dart';
import 'chat_base_controller.dart';

/// 聊天消息控制器
///
/// 职责：
/// - 管理消息列表（加载、分页）
/// - 发送消息（文本、图片、视频等）
/// - 接收和同步消息
/// - 撤回消息
/// - 消息预览
///
/// 设计原则：
/// - 单一职责：只负责消息管理，不涉及会话操作
/// - 性能优化：分页加载、消息批量处理
/// - 线程安全：使用Isolate处理消息解析
class ChatMessageController extends ChatBaseController {
  // ==================== 响应式状态 ====================

  /// 当前会话的消息列表
  final RxList<IMessage> messageList = <IMessage>[].obs;

  /// 加载更多状态
  final RxBool isLoadingMore = false.obs;

  /// 是否还有更多消息
  final RxBool hasMoreMessages = true.obs;

  /// 消息同步状态
  final RxBool isSyncing = false.obs;

  // ==================== 私有状态 ====================

  /// 分页参数
  final int pageSize = AppConstants.defaultPageSize;
  int _currentPage = 0;

  // ==================== 公共方法 ====================

  void clear() {
    messageList.clear();
    _currentPage = 0;
  }

  /// 加载消息列表，支持分页
  ///
  /// 参数：
  /// - [chat] 会话信息
  /// - [loadMore] 是否加载更多
  Future<void> loadMessages(Chats chat, {bool loadMore = false}) async {
    if (!loadMore) {
      messageList.clear();
      _currentPage = 0;
      hasMoreMessages.value = true;
    }
    if (!hasMoreMessages.value) return;

    try {
      isLoadingMore.value = true;
      final messageType = MessageType.fromCode(chat.chatType);
      List<IMessage> newMessages = [];

      if (messageType == MessageType.singleMessage) {
        final messages = await db.singleMessageDao.getMessagesByPage(
          chat.id,
          chat.ownerId,
          pageSize,
          _currentPage * pageSize,
        );
        newMessages = messages?.map(IMessage.fromSingleMessage).toList() ?? [];
      } else if (messageType == MessageType.groupMessage) {
        final messages = await db.groupMessageDao.getMessagesByPage(
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

  /// 发送文本消息
  ///
  /// 参数：
  /// - [text] 消息内容
  /// - [chat] 当前会话（如果为null，使用回调获取）
  Future<void> sendTextMessage(String text, [Chats? chat]) async {
    // 验证消息内容
    final trimmedText = text.trim();
    final validationError = Validator.validateMessageLength(trimmedText);
    if (validationError != null) {
      showError(ValidationException(validationError));
      return;
    }

    // 获取当前会话
    final currentChat = chat ?? getCurrentChat?.call();
    if (currentChat == null) {
      showError(BusinessException('请先选择会话'));
      return;
    }

    try {
      final messageBody = TextMessageBody(text: trimmedText);
      final params = IMessage.buildRequest(
        fromId: userId.value,
        targetId: currentChat.id,
        messageType: currentChat.chatType,
        body: messageBody,
        contentType: MessageContentType.text.code,
      );

      // 根据聊天类型发送消息
      final res = currentChat.chatType == MessageType.singleMessage.code
          ? await apiService.sendSingleMessage(params)
          : await apiService.sendGroupMessage(params);

      if (res.isSuccess && res.data != null) {
        final parsedMessage = res.data!;
        await onMessageCreated?.call(parsedMessage, currentChat.toId, true);
        Get.log('✅ 消息发送成功');
      } else {
        throw BusinessException(res.message);
      }
    } catch (e) {
      showError(e);
    }
  }

  /// 撤回消息
  Future<void> recallMessage(String messageId, int messageType) async {
    try {
      final res = await apiService.recallMessage({'messageId': messageId});

      if (res.isSuccess) {
        Get.snackbar('成功', '消息已撤回');
        messageList.removeWhere((m) => m.messageId == messageId);
        messageList.refresh();
      } else {
        throw BusinessException(res.message);
      }
    } catch (e) {
      showError('撤回消息失败: $e');
    }
  }

  /// 同步消息
  ///
  /// 从服务器拉取最新消息并更新到本地数据库
  Future<void> syncMessages() async {
    if (userId.isEmpty) {
      getUserId();
    }
    if (isSyncing.value) {
      Get.log('⏳ 消息同步中，跳过本次同步');
      return;
    }
    try {
      isSyncing.value = true;
      Chats? chat = await db.chatsDao.getLastChat(userId.value);
      // 注意：这里的 API 调用需要根据后端实际定义的“全量同步”或“会话同步”来调整
      // 目前传入空 chatId 代表获取所有相关消息
      final response = await apiService.getMessageList({
        'fromId': userId.value,
        'sequence': chat?.sequence ?? 0,
      });

      handleApiResponse(response, onSuccess: (data) async {
        final messages = response.data!;
        await _processSyncedMessages(
          messages,
          MessageType.singleMessage.code,
        );
        await _processSyncedMessages(
          messages,
          MessageType.groupMessage.code,
        );
      }, onError: (code, message) {
        throw BusinessException(message);
      });
    } finally {
      isSyncing.value = false;
    }
  }

  /// 添加消息到列表
  ///
  /// 参数：
  /// - [dto] 消息数据
  /// - [chat] 会话信息
  Future<void> addMessageToList(IMessage dto, Chats chat) async {
    // 保存到数据库

    try {
      if (dto.isSingleMessage) {
        await db.singleMessageDao.insertMessage(
          IMessage.toSingleMessage(dto, userId.value),
        );
      } else if (dto.isGroupMessage) {
        await db.groupMessageDao.insertMessage(
          IMessage.toGroupMessage(dto, userId.value),
        );
      }
    } catch (err) {
      Get.log("消息添加失败:${err.toString()}");
    }

    // 如果是当前会话，添加到消息列表
    final currentChat = getCurrentChat?.call();
    if (currentChat?.id == chat.id) {
      // 优化：如果是最新消息直接插入头部，否则重新排序
      if (messageList.isEmpty ||
          dto.messageTime >= messageList.first.messageTime) {
        messageList.insert(0, dto);
      } else {
        messageList.add(dto);
        messageList.sort(
          (a, b) => b.messageTime.compareTo(a.messageTime),
        );
      }
    }
  }

  /// 预览图片
  ///
  /// 参数：
  /// - [currentUrl] 当前图片URL
  void previewImage(String currentUrl) {
    if (currentUrl.isEmpty) return;

    // 1. 筛选出所有图片消息
    final imageMessages = messageList
        .where((m) => m.messageContentType == MessageContentType.image.code)
        .toList();

    // 2. 提取图片URL并按时间正序排序 (旧 -> 新)
    final imageUrls = imageMessages.reversed
        .map((m) => ImageMessageBody.fromMessageBody(m.messageBody)?.path ?? '')
        .where((url) => url.isNotEmpty)
        .toList();

    // 3. 找到当前图片的索引
    final initialIndex = imageUrls.indexOf(currentUrl);

    if (initialIndex != -1) {
      Get.toNamed(
        '${Routes.HOME}${Routes.PHOTO_PREVIEW}',
        arguments: {
          'images': imageUrls,
          'index': initialIndex,
        },
      );
    }
  }

  // ==================== 私有方法 ====================

  /// 处理同步消息
  Future<void> _processSyncedMessages(
    Map<String, dynamic> messages,
    int messageType,
  ) async {
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
        final targetId = getMessageTargetId(message);
        if (targetId != null) {
          // 从服务拉取消息  非本地创建消息统一设为 false
          await onMessageCreated?.call(message, targetId, false);
        }
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

  // ==================== 回调 ====================

  /// 获取当前会话（由协调器注入）
  Chats? Function()? getCurrentChat;

  /// 消息创建回调（通知会话控制器更新）
  Future<void> Function(IMessage message, String targetId, bool isMe)?
      onMessageCreated;
}
