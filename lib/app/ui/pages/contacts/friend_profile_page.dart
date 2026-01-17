import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../routes/app_routes.dart';
import '../../../controller/chat_controller.dart';
import '../../../controller/contact_controller.dart';
import '../../../models/friend.dart';
import '../../widgets/icon/icon_font.dart';

/// 好友资料页面，展示好友或非好友的个人信息及操作按钮
/// 特性：
/// - 显示用户头像、名称、ID、所在地等信息。
/// - 根据好友状态（flag）显示不同操作按钮（发消息、音视频通话或添加好友）。
/// - 使用 FutureBuilder 异步加载好友信息，支持加载和错误状态。
class FriendProfilePage extends StatelessWidget {
  // 常量定义
  static const _avatarSize = 100.0; // 增大头像尺寸
  static const _avatarBorderRadius = AppSizes.radius12;
  static const _keyUserId = 'userId';

  const FriendProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = GetStorage();
    final userId = storage.read(_keyUserId) ?? '';
    final friendId =
        (Get.arguments is Map ? Get.arguments[_keyUserId] as String? : null) ??
            Get.parameters[_keyUserId] ??
            '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary),
          onPressed: Get.back,
        ),
        actions: [
          if (userId != friendId)
            _buildPopupMenuButton(context, userId, friendId),
        ],
      ),
      body: FutureBuilder<Friend>(
        future: _getFriendInfo(userId, friendId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildErrorState(context, snapshot.error.toString());
          }

          final friend = snapshot.data ??
              Friend(userId: userId, friendId: friendId, name: '');

          return SingleChildScrollView(
            child: Column(
              children: [
                /// 用户信息头部
                _buildHeader(context, friend),
                const SizedBox(height: AppSizes.spacing12),

                /// 信息列表
                _buildInfoSection(context, friend),
                const SizedBox(height: AppSizes.spacing12),

                /// 操作按钮区域
                _buildActions(context, userId, friend),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconfont.fromName('71shibai'),
              size: 60, color: AppColors.textHint),
          const SizedBox(height: AppSizes.spacing16),
          Text(
            '加载失败: $error',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: AppSizes.font14),
          ),
          const SizedBox(height: AppSizes.spacing24),
          ElevatedButton(
            onPressed: () => Get.forceAppUpdate(), // 简单的重试逻辑
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 构建弹出菜单按钮
  Widget _buildPopupMenuButton(
      BuildContext context, String userId, String friendId) {
    return PopupMenuButton<String>(
      icon: Icon(Iconfont.fromName('sandian'), color: AppColors.textPrimary),
      onSelected: (String value) async {
        switch (value) {
          case 'delete':
            _handleDeleteFriend(context, userId, friendId);
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline, color: AppColors.error),
            title: Text('删除好友', style: TextStyle(color: AppColors.error)),
          ),
        ),
      ],
    );
  }

  /// 构建用户信息头部
  Widget _buildHeader(BuildContext context, Friend friend) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing20,
        vertical: AppSizes.spacing24,
      ),
      color: AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// 头像
          Hero(
            tag: 'avatar_${friend.friendId}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_avatarBorderRadius),
              child: CachedNetworkImage(
                imageUrl: friend.fullAvatar,
                width: _avatarSize,
                height: _avatarSize,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.background,
                  child: Icon(Iconfont.person,
                      size: AppSizes.spacing40, color: AppColors.textHint),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.background,
                  child: Icon(Iconfont.person,
                      size: AppSizes.spacing40, color: AppColors.textHint),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spacing20),

          /// 用户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: const TextStyle(
                    fontSize: AppSizes.font22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing8),
                Text(
                  'ID: ${friend.friendId}',
                  style: const TextStyle(
                    fontSize: AppSizes.font14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息详情区域（地区等）
  Widget _buildInfoSection(BuildContext context, Friend friend) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          _buildInfoTile(
            label: '地区',
            value: friend.location ?? '未知地点',
            icon: Iconfont.location,
          ),
          // 这里可以根据需要添加更多信息行，如个性签名等
        ],
      ),
    );
  }

  /// 构建单个信息行
  Widget _buildInfoTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing20,
        vertical: AppSizes.spacing16,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: AppSizes.font16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSizes.spacing24),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppSizes.font16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Icon(icon, size: AppSizes.iconSmall, color: AppColors.textHint),
        ],
      ),
    );
  }

  /// 构建操作按钮区域
  Widget _buildActions(BuildContext context, String userId, Friend friend) {
    final List<Widget> actionButtons = [];

    if (friend.flag == 1) {
      // 已是好友
      actionButtons.add(
        _buildActionButton(
          text: '发消息',
          icon: Iconfont.message,
          onPressed: () => _handleMessage(context, friend),
          primary: true,
        ),
      );
      actionButtons
          .add(const Divider(height: 1, indent: 60, color: AppColors.divider));
      actionButtons.add(
        _buildActionButton(
          text: '音视频通话',
          icon: Iconfont.videoCall,
          onPressed: () => _handleVideoCall(context, userId, friend),
        ),
      );
    } else {
      // 非好友
      actionButtons.add(
        _buildActionButton(
          text: '添加到通讯录',
          icon: Iconfont.addFriend,
          onPressed: () => _handleAddFriend(context, friend),
          primary: true,
        ),
      );
    }

    return Container(
      color: AppColors.surface,
      child: Column(children: actionButtons),
    );
  }

  /// 构建单个操作按钮（列表样式）
  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    bool primary = false,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppSizes.iconMedium, color: AppColors.primary),
            const SizedBox(width: AppSizes.spacing12),
            Text(
              text,
              style: const TextStyle(
                fontSize: AppSizes.font16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 逻辑处理方法 ---

  /// 获取好友信息
  Future<Friend> _getFriendInfo(String userId, String friendId) async {
    final contactController = Get.find<ContactController>();
    if (userId.isNotEmpty && friendId.isNotEmpty) {
      try {
        return await contactController.getFriend(userId, friendId);
      } catch (e) {
        debugPrint('获取好友信息失败: $e');
      }
    }
    return Friend(userId: userId, friendId: friendId, name: '');
  }

  /// 处理发送消息
  Future<void> _handleMessage(BuildContext context, Friend friend) async {
    final chatController = Get.find<ChatController>();
    final isSuccess = await chatController.setCurrentChatByFriend(friend);
    if (isSuccess) {
      // 这里的路由跳转逻辑根据你的应用实际路径调整
      Get.toNamed('${Routes.HOME}${Routes.MESSAGE}');
    } else {
      Get.snackbar('提示', '无法打开聊天', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// 处理音视频通话
  Future<void> _handleVideoCall(
      BuildContext context, String userId, Friend friend) async {
    final chatController = Get.find<ChatController>();
    final isSuccess = await chatController.handleCallVideo(friend);
    if (isSuccess) {
      Get.toNamed('${Routes.HOME}${Routes.VIDEO_CALL}',
          arguments: {'userId': userId, 'friend': friend});
    } else {
      Get.snackbar('提示', '无法发起通话', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// 处理添加好友
  Future<void> _handleAddFriend(BuildContext context, Friend friend) async {
    final contactController = Get.find<ContactController>();
    final friendId = friend.friendId;
    if (friendId.isEmpty) {
      Get.snackbar('错误', '好友 ID 为空', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    try {
      await contactController.sendFriendRequest(friendId, "");
    } catch (e) {
      Get.snackbar('错误', '添加好友失败: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// 处理删除好友
  Future<void> _handleDeleteFriend(
      BuildContext context, String userId, String friendId) async {
    final contactController = Get.find<ContactController>();

    // 显示确认对话框
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('删除好友'),
        content: const Text('确定要删除该好友吗？此操作不可撤销。'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('删除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await contactController.deleteFriend(friendId);
        Get.back(); // 返回上一页
      } catch (e) {
        Get.snackbar('错误', '删除失败: $e', snackPosition: SnackPosition.BOTTOM);
      }
    }
  }
}
