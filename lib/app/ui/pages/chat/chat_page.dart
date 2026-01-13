import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../controller/chat_controller.dart';
import '../../../controller/user_controller.dart';
import '../../../models/chats.dart';
import '../../widgets/chat/chat_item.dart';
import '../../widgets/icon/icon_font.dart';

/// 聊天页面，显示会话列表并支持跳转到聊天详情
/// 特性：
/// - 显示用户头像、用户名及 WebSocket 连接状态。
/// - 支持搜索、创建群聊、扫一扫和添加好友功能。
/// - 使用 [ChatItem] 显示会话，支持点击进入聊天详情。
/// - 使用 [PopupMenuButton] 实现带箭头的弹出菜单。
class ChatPage extends GetView<ChatController> {
  const ChatPage({super.key});

  // 常量定义
  static const _avatarSize = AppSizes.spacing40; // 头像尺寸
  static const _avatarBorderRadius = AppSizes.radius8; // 头像圆角
  static const _appBarHeight = kToolbarHeight; // AppBar 高度
  static const _chatItemPadding = EdgeInsets.symmetric(
    horizontal: AppSizes.spacing12,
    vertical: AppSizes.spacing8,
  ); // 聊天项外边距
  static const _emptyText = '暂无聊天记录'; // 空状态提示

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: Obx(() => _buildChatList(context, controller.chatList)),
    );
  }

  // --- UI 构建方法 ---

  /// 构建 AppBar，包含头像、用户名和操作按钮
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: GetX<UserController>(
        builder: (controller) {
          final userInfo = controller.userInfo;
          final username = userInfo['name'] ?? '未登录';
          final avatarUrl = userInfo['avatar'] ?? '';

          return Row(
            children: [
              _buildAvatar(context, username, avatarUrl),
              _buildUserInfo(context, username),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: Iconfont.buildIcon(
              icon: Iconfont.search, size: AppSizes.iconMedium),
          onPressed: () => controller.openSearch(),
          tooltip: '搜索',
        ),
        _buildPopupMenuButton(context),
        const SizedBox(width: AppSizes.spacing8),
      ],
    );
  }

  /// 构建头像
  Widget _buildAvatar(BuildContext context, String username, String avatarUrl) {
    return GestureDetector(
      onTap: () => Scaffold.of(context).openDrawer(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_avatarBorderRadius),
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: _avatarSize,
          height: _avatarSize,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: AppColors.border,
            child: Iconfont.buildIcon(
                icon: Iconfont.person,
                size: AppSizes.iconMedium,
                color: AppColors.textHint),
          ),
          errorWidget: (context, url, error) {
            debugPrint('加载头像失败: $error');
            return Container(
              color: AppColors.border,
              child: Iconfont.buildIcon(
                  icon: Iconfont.person,
                  size: AppSizes.iconMedium,
                  color: AppColors.textHint),
            );
          },
        ),
      ),
    );
  }

  /// 构建用户名和连接状态
  Widget _buildUserInfo(BuildContext context, String username) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left: AppSizes.spacing12),
        child: Text(
          username,
          style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold) ??
              const TextStyle(
                  fontSize: AppSizes.font20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// 构建弹出菜单按钮
  Widget _buildPopupMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Iconfont.buildIcon(icon: Iconfont.add, size: AppSizes.iconLarge),
      tooltip: '更多操作',
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.radius8)),
      ),
      offset: const Offset(0, kToolbarHeight),
      itemBuilder: (context) => _buildMenuItems(),
      onSelected: controller.onMenuSelected,
    );
  }

  /// 构建弹出菜单项
  List<PopupMenuItem<String>> _buildMenuItems() {
    return [
      PopupMenuItem<String>(
        value: 'create_group',
        child: Row(
          children: [
            Iconfont.buildIcon(
                icon: Iconfont.add,
                size: AppSizes.font20,
                color: AppColors.textSecondary),
            const SizedBox(width: AppSizes.spacing12),
            const Text('创建群聊'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'scan',
        child: Row(
          children: [
            Iconfont.buildIcon(
                icon: Iconfont.scan,
                size: AppSizes.font20,
                color: AppColors.textSecondary),
            const SizedBox(width: AppSizes.spacing12),
            const Text('扫一扫'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'add_friend',
        child: Row(
          children: [
            Iconfont.buildIcon(
                icon: Iconfont.addFriend,
                size: AppSizes.font20,
                color: AppColors.textSecondary),
            const SizedBox(width: AppSizes.spacing12),
            const Text('加好友/群'),
          ],
        ),
      ),
    ];
  }

  /// 构建聊天列表
  Widget _buildChatList(BuildContext context, List<Chats> chatList) {
    if (chatList.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      cacheExtent: 1000, // 缓存 1000 像素，优化滚动性能
      itemCount: chatList.length,
      itemBuilder: (context, index) {
        final chat = chatList[index];
        return GestureDetector(
          onTap: () => controller.changeCurrentChat(chat),
          child: Container(
            color: AppColors.surface,
            child: Padding(
              padding: _chatItemPadding,
              child: ChatItem(chats: chat),
            ),
          ),
        );
      },
    );
  }

  /// 构建空状态提示
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Text(
        _emptyText,
        style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.textSecondary) ??
            const TextStyle(
                fontSize: AppSizes.font16, color: AppColors.textSecondary),
      ),
    );
  }
}
