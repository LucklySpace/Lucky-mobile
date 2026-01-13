import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_message.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../routes/app_routes.dart';
import '../../../../utils/date.dart';
import '../../../controller/chat_controller.dart';
import '../../../controller/user_controller.dart';
import '../../../models/message_receive.dart';
import '../../widgets/bubble/file_bubble.dart';
import '../../widgets/bubble/image_bubble.dart';
import '../../widgets/bubble/system_bubble.dart';
import '../../widgets/bubble/text_bubble.dart';
import '../../widgets/bubble/video_bubble.dart';
import 'message_input.dart';

/// 消息页面，展示聊天消息列表和输入框
/// 特性：
/// - 显示会话名称、头像及消息气泡（文本、图片、视频、系统消息）。
/// - 支持滑动加载更多消息，自动滚动到最新消息。
/// - 上下消息时间差小于 5 分钟不显示时间标签，时间标签统一在列表中展示。
/// - 提供返回按钮和聊天信息跳转功能。
class MessagePage extends GetView<ChatController> {
  // 常量定义
  static const _appBarTitleStyle = TextStyle(
    fontSize: AppSizes.font16,
    fontWeight: FontWeight.w600,
  );
  static const _loadingPadding = EdgeInsets.all(AppSizes.spacing10);
  static const _noMoreMessagesPadding =
      EdgeInsets.symmetric(vertical: AppSizes.spacing16);
  static const _noMoreMessagesStyle = TextStyle(
    fontSize: AppSizes.font12,
    color: AppColors.textHint,
  );
  static const _timeStyle =
      TextStyle(fontSize: AppSizes.font12, color: AppColors.textHint); // 时间标签样式
  static const _defaultName = '未知用户'; // 默认用户名
  static const _defaultAvatar = ''; // 默认头像 URL
  static const _timeDiffThreshold = Duration(minutes: 5); // 时间差阈值（5分钟）
  static const _timeFormat = 'yy/MM/dd'; // 时间格式
  static const _timePadding =
      EdgeInsets.symmetric(vertical: AppSizes.spacing8); // 时间标签边距

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  MessagePage({super.key});

  @override
  void dispose() {
    /// 释放控制器资源
    _textController.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = Get.find<UserController>().userInfo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(userInfo),
      body: Column(
        children: [
          /// 消息列表
          Expanded(child: _buildMessageList(userInfo)),

          /// 输入框
          MessageInput(
            textController: _textController,
            controller: controller,
          ),
        ],
      ),
    );
  }

  // --- UI 构建方法 ---

  /// 构建 AppBar
  PreferredSizeWidget _buildAppBar(Map<dynamic, dynamic> userInfo) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: () => Get.toNamed('${Routes.HOME}'),
      ),
      title: Obx(() => Text(
            controller.currentChat.value?.name ?? _defaultName,
            style: _appBarTitleStyle,
          )),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            final chat = controller.currentChat.value;
            if (chat != null) {
              Get.toNamed(
                '${Routes.HOME}${Routes.CHAT_INFO}',
                arguments: {
                  'avatar': chat.avatar ?? _defaultAvatar,
                  'name': chat.name ?? _defaultName
                },
              );
            }
          },
        ),
      ],
    );
  }

  /// 构建消息列表
  Widget _buildMessageList(Map<dynamic, dynamic> userInfo) {
    return Obx(() => NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.pixels ==
                    scrollInfo.metrics.maxScrollExtent &&
                !controller.isLoadingMore.value &&
                controller.hasMoreMessages.value) {
              final chat = controller.currentChat.value;
              if (chat != null) {
                controller.handleSetMessageList(chat, loadMore: true);
              }
            }
            return true;
          },
          child: ListView.builder(
            controller: _scrollController,
            reverse: true,
            itemCount: controller.messageList.length + 1,
            itemBuilder: (context, index) {
              if (index == controller.messageList.length) {
                return _buildListFooter();
              }
              return _buildMessageItem(index, userInfo);
            },
          ),
        ));
  }

  /// 构建列表底部（加载状态或无更多消息提示）
  Widget _buildListFooter() {
    return Obx(() {
      if (controller.isLoadingMore.value) {
        return const Center(
          child: Padding(
            padding: _loadingPadding,
            child: CircularProgressIndicator(),
          ),
        );
      }
      if (!controller.hasMoreMessages.value &&
          controller.messageList.length >= controller.pageSize) {
        return const Center(
          child: Padding(
            padding: _noMoreMessagesPadding,
            child: Text('没有更多消息了', style: _noMoreMessagesStyle),
          ),
        );
      }
      return const SizedBox();
    });
  }

  /// 构建消息项（包括时间标签和气泡）
  Widget _buildMessageItem(int index, Map<dynamic, dynamic> userInfo) {
    final message = controller.messageList[index];
    final isMe = message.fromId == controller.userId.value;
    final chat = controller.currentChat.value;

    var name = "";
    var avatar = "";

    if (chat?.chatType == MessageType.singleMessage.code) {
      name =
          isMe ? userInfo['name'] ?? _defaultName : chat?.name ?? _defaultName;
      avatar = isMe
          ? userInfo['avatar'] ?? _defaultAvatar
          : chat?.avatar ?? _defaultAvatar;
    }

    if (chat?.chatType == MessageType.groupMessage.code) {
      final groupMembers = controller.groupMembers[chat?.toId ?? ''];
      final member = groupMembers?[message.fromId ?? ''];
      name = isMe
          ? userInfo['name'] ?? _defaultName
          : member?.name ?? _defaultName;
      avatar = isMe
          ? userInfo['avatar'] ?? _defaultAvatar
          : member?.avatar ?? _defaultAvatar;
    }

    // 计算是否显示时间（与上一条消息时间差小于 5 分钟不显示）
    final showTime = _shouldShowTime(index, message);

    // 构建消息气泡
    final contentType =
        MessageContentType.fromCode(message.messageContentType ?? 1);
    final bubble = _messageBubbleMap[contentType]?.call(
          message: message,
          isMe: isMe,
          name: name,
          avatar: avatar,
        ) ??
        _buildTextBubble(
          message: message,
          isMe: isMe,
          name: name,
          avatar: avatar,
        );

    // 如果需要显示时间，添加时间标签
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTime)
          Padding(
            padding: _timePadding,
            child: Text(
              DateUtil.getTimeToDisplay(
                  message.messageTime ?? 0, _timeFormat, true),
              style: _timeStyle,
              textAlign: TextAlign.center,
            ),
          ),
        bubble,
      ],
    );
  }

  // --- 辅助方法 ---

  /// 判断是否显示时间（与上一条消息时间差小于 5 分钟不显示）
  bool _shouldShowTime(int index, IMessage message) {
    if (index == controller.messageList.length - 1) {
      return true; // 最后一条消息（时间线上最早）始终显示时间
    }
    final prevMessage = controller.messageList[index + 1];
    return DateUtil.shouldDisplayTime(
        message.messageTime, prevMessage.messageTime);
  }

  /// 消息气泡映射表
  static const _messageBubbleMap = {
    MessageContentType.file: _buildFileBubble,
    MessageContentType.image: _buildImageBubble,
    MessageContentType.video: _buildVideoBubble,
    MessageContentType.text: _buildTextBubble,
    MessageContentType.tip: _buildSystemBubble,
  };

  /// 构建图片气泡
  static Widget _buildImageBubble({
    required IMessage message,
    required bool isMe,
    required String name,
    required String avatar,
  }) =>
      ImageBubble(
        message: message,
        isMe: isMe,
        name: name,
        avatar: avatar,
      );

  /// 构建视频气泡
  static Widget _buildVideoBubble({
    required IMessage message,
    required bool isMe,
    required String name,
    required String avatar,
  }) =>
      VideoBubble(
        message: message,
        isMe: isMe,
        name: name,
        avatar: avatar,
      );

  /// 构建文本气泡
  static Widget _buildTextBubble({
    required IMessage message,
    required bool isMe,
    required String name,
    required String avatar,
  }) =>
      MessageBubble(
        message: message,
        isMe: isMe,
        name: name,
        avatar: avatar,
      );

  /// 构建文件气泡
  static Widget _buildFileBubble({
    required IMessage message,
    required bool isMe,
    required String name,
    required String avatar,
  }) =>
      FileBubble(
        message: message,
        isMe: isMe,
        name: name,
        avatar: avatar,
      );

  /// 构建系统消息气泡
  static Widget _buildSystemBubble({
    required IMessage message,
    required bool isMe,
    required String name,
    required String avatar,
  }) =>
      SystemMessageBubble(message: message);
}
