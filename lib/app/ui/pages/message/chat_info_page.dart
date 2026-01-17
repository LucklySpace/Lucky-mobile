import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../widgets/icon/icon_font.dart';

/// 聊天信息页面
/// 功能：
/// - 展示聊天对象的头像和名称
/// - 提供聊天设置（搜索聊天记录、免打扰等）
/// - 提供清除聊天记录的操作
class ChatInfoPage extends StatelessWidget {
  const ChatInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final String avatarUrl = args['avatar'] ?? '';
    final String name = args['name'] ?? '未知用户';
    final String friendId = args['friendId'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('聊天信息'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: AppSizes.spacing12),

            /// 用户信息头部
            _buildHeader(avatarUrl, name, friendId),
            const SizedBox(height: AppSizes.spacing12),

            /// 聊天设置区域
            _buildSettingsSection(context),
            const SizedBox(height: AppSizes.spacing12),

            /// 操作区域
            _buildActionsSection(context),
          ],
        ),
      ),
    );
  }

  /// 构建用户信息头部
  Widget _buildHeader(String avatarUrl, String name, String friendId) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing20,
        vertical: AppSizes.spacing20,
      ),
      child: Row(
        children: [
          // 头像展示，支持点击查看大图或跳转资料页
          GestureDetector(
            onTap: () {
              if (friendId.isNotEmpty) {
                // 如果有 friendId，可以跳转到好友资料页
                // Get.toNamed(Routes.FRIEND_PROFILE, arguments: {'userId': friendId});
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radius8),
              child: avatarUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.background,
                        child: Icon(Iconfont.person,
                            size: 30, color: AppColors.textHint),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.background,
                        child: Icon(Iconfont.person,
                            size: 30, color: AppColors.textHint),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: AppColors.background,
                      child: Icon(Iconfont.person,
                          size: 30, color: AppColors.textHint),
                    ),
            ),
          ),
          const SizedBox(width: AppSizes.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: AppSizes.font18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (friendId.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.spacing4),
                  Text(
                    'ID: $friendId',
                    style: const TextStyle(
                      fontSize: AppSizes.font12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Iconfont.fromName('right'), size: 16, color: AppColors.textHint),
        ],
      ),
    );
  }

  /// 构建设置选项区域
  Widget _buildSettingsSection(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          _buildSettingItem(
            title: '查找聊天记录',
            icon: Iconfont.search,
            onTap: () {
              Get.snackbar('提示', '搜索功能开发中',
                  snackPosition: SnackPosition.BOTTOM);
            },
          ),
          const Divider(height: 1, indent: 56, color: AppColors.divider),
          _buildSwitchItem(
            title: '消息免打扰',
            value: false, // 实际应从控制器获取状态
            onChanged: (val) {
              // TODO: 处理免打扰逻辑
            },
          ),
          const Divider(height: 1, indent: 20, color: AppColors.divider),
          _buildSwitchItem(
            title: '置顶聊天',
            value: false, // 实际应从控制器获取状态
            onChanged: (val) {
              // TODO: 处理置顶逻辑
            },
          ),
        ],
      ),
    );
  }

  /// 构建操作项区域
  Widget _buildActionsSection(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: _buildSettingItem(
        title: '清空聊天记录',
        showArrow: false,
        textColor: AppColors.error,
        onTap: () => _handleClearHistory(context),
      ),
    );
  }

  /// 构建普通设置项
  Widget _buildSettingItem({
    required String title,
    IconData? icon,
    required VoidCallback onTap,
    bool showArrow = true,
    Color textColor = AppColors.textPrimary,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing20,
          vertical: AppSizes.spacing16,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: AppSizes.spacing16),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: AppSizes.font16,
                  color: textColor,
                ),
              ),
            ),
            if (showArrow)
              Icon(Iconfont.fromName('right'),
                  size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  /// 构建开关设置项
  Widget _buildSwitchItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing20,
        vertical: AppSizes.spacing4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: AppSizes.font16,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  /// 处理清空聊天记录
  Future<void> _handleClearHistory(BuildContext context) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('清空聊天记录'),
        content: const Text('确定要清空与该聊天的所有记录吗？'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('清空', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: 调用控制器清空记录
      Get.snackbar('提示', '聊天记录已清空', snackPosition: SnackPosition.BOTTOM);
    }
  }
}
