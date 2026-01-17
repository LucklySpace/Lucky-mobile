import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../routes/app_routes.dart';
import '../../../controller/contact_controller.dart';
import '../../widgets/contacts/user_avatar_name.dart';
import '../../widgets/icon/icon_font.dart';

/// 通讯录页面
/// 展示好友列表、新的朋友、群聊等入口
class ContactsPage extends GetView<ContactController> {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 确保进入页面时刷新状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchContacts();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (controller.isLoading.value && controller.contactsList.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchContacts,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              /// 顶部功能项
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  child: Column(
                    children: [
                      _buildFuncItem(
                        icon: Iconfont.addFriend,
                        color: Colors.orange,
                        title: '新的朋友',
                        badgeCount: controller.newFriendRequestCount.value,
                        onTap: () => Get.toNamed(
                            "${Routes.HOME}${Routes.FRIEND_REQUESTS}"),
                      ),
                      const Divider(
                          height: 1, indent: 60, color: AppColors.divider),
                      _buildFuncItem(
                        icon: Iconfont.contacts,
                        color: Colors.green,
                        title: '群聊',
                        onTap: () {
                          Get.snackbar('提示', '功能开发中',
                              snackPosition: SnackPosition.BOTTOM);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                  child: SizedBox(height: AppSizes.spacing12)),

              /// 好友列表
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final friend = controller.contactsList[index];
                    return Container(
                      color: AppColors.surface,
                      child: Column(
                        children: [
                          UserAvatarName(
                            avatar: friend.fullAvatar,
                            name: friend.displayName,
                            onTap: () {
                              Get.toNamed(
                                  "${Routes.HOME}${Routes.FRIEND_PROFILE}",
                                  arguments: {'userId': friend.friendId});
                            },
                          ),
                          if (index < controller.contactsList.length - 1)
                            const Divider(
                                height: 1,
                                indent: 60,
                                color: AppColors.divider),
                        ],
                      ),
                    );
                  },
                  childCount: controller.contactsList.length,
                ),
              ),

              if (controller.contactsList.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.spacing20),
                    alignment: Alignment.center,
                    child: Text(
                      '${controller.contactsList.length} 位联系人',
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: AppSizes.font14),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  /// 构建 AppBar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('通讯录'),
      centerTitle: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      // 移除返回箭头
      actions: [
        IconButton(
          icon: Icon(Iconfont.search, color: AppColors.textPrimary, size: 22),
          onPressed: () => Get.toNamed("${Routes.HOME}${Routes.SEARCH}"),
        ),
        IconButton(
          icon: Icon(Iconfont.add, color: AppColors.textPrimary, size: 22),
          onPressed: () => Get.toNamed("${Routes.HOME}${Routes.ADD_FRIEND}"),
        ),
        const SizedBox(width: AppSizes.spacing8),
      ],
    );
  }

  /// 构建功能项（新的朋友、群聊等）
  Widget _buildFuncItem({
    required IconData icon,
    required Color color,
    required String title,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing16, vertical: AppSizes.spacing12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppSizes.radius8),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: AppSizes.spacing12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: AppSizes.font16,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(width: 4),
            Icon(Iconfont.fromName('right'),
                size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
