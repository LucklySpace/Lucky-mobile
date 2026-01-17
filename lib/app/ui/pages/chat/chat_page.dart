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

/// 聊天主页面，显示会话列表并支持跳转到聊天详情
class ChatPage extends GetView<ChatController> {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: Obx(() => _buildChatList(context, controller.chatList)),
    );
  }

  /// 构建 AppBar，包含头像、用户名和操作按钮
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: GetX<UserController>(
        builder: (userCtrl) {
          final userInfo = userCtrl.userInfo.value;
          final username = userInfo?.name ?? '未登录';
          final avatarUrl = userInfo?.avatar ?? '';

          return InkWell(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAvatar(avatarUrl),
                const SizedBox(width: AppSizes.spacing12),
                Text(
                  username,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppSizes.font18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Iconfont.search, color: AppColors.textPrimary, size: 22),
          onPressed: () => controller.openSearch(),
        ),
        _buildPopupMenuButton(context),
        const SizedBox(width: AppSizes.spacing8),
      ],
    );
  }

  /// 构建头像
  Widget _buildAvatar(String avatarUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radius8),
      child: avatarUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: avatarUrl,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.background,
                child:
                    Icon(Iconfont.person, size: 20, color: AppColors.textHint),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.background,
                child:
                    Icon(Iconfont.person, size: 20, color: AppColors.textHint),
              ),
            )
          : Container(
              width: 36,
              height: 36,
              color: AppColors.background,
              child: Icon(Iconfont.person, size: 20, color: AppColors.textHint),
            ),
    );
  }

  /// 构建弹出菜单按钮
  Widget _buildPopupMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Iconfont.add, color: AppColors.textPrimary, size: 26),
      tooltip: '更多操作',
      elevation: 3,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius8),
      ),
      itemBuilder: (context) => [
        _buildPopupItem('create_group', Iconfont.add, '创建群聊'),
        _buildPopupItem('scan', Iconfont.scan, '扫一扫'),
        _buildPopupItem('add_friend', Iconfont.addFriend, '加好友/群'),
      ],
      onSelected: controller.onMenuSelected,
    );
  }

  /// 构建单个弹出菜单项
  PopupMenuItem<String> _buildPopupItem(
      String value, IconData icon, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: AppColors.textPrimary),
          const SizedBox(width: AppSizes.spacing12),
          Text(text, style: const TextStyle(fontSize: AppSizes.font15)),
        ],
      ),
    );
  }

  /// 构建聊天列表
  Widget _buildChatList(BuildContext context, List<Chats> chatList) {
    if (chatList.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: chatList.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        indent: 72,
        color: AppColors.divider,
      ),
      itemBuilder: (context, index) {
        final chat = chatList[index];
        return InkWell(
          onTap: () => controller.changeCurrentChat(chat),
          child: Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing12,
              vertical: AppSizes.spacing4,
            ),
            child: ChatItem(chats: chat),
          ),
        );
      },
    );
  }

  /// 构建空状态提示
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconfont.fromName('liaotian'),
              size: 80, color: AppColors.textHint.withOpacity(0.3)),
          const SizedBox(height: AppSizes.spacing16),
          const Text(
            '暂无聊天记录',
            style: TextStyle(
              fontSize: AppSizes.font16,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
