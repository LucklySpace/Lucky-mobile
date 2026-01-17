import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../routes/app_routes.dart';
import '../../../controller/contact_controller.dart';
import '../../widgets/icon/icon_font.dart';

/// 添加好友页面
class AddFriendPage extends StatelessWidget {
  AddFriendPage({super.key}) {
    // 进入页面时清空之前的搜索结果
    controller.searchResults.clear();
    controller.isSearching.value = false;
  }

  final TextEditingController _searchController = TextEditingController();
  final ContactController controller = Get.find<ContactController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('添加好友'),
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          /// 搜索区域
          _buildSearchSection(context),

          /// 我的 ID 展示
          _buildMyIdSection(),

          const SizedBox(height: AppSizes.spacing12),

          /// 搜索结果列表
          Expanded(
            child: Obx(() {
              if (controller.isSearching.value) {
                return _buildSearchingWidget();
              }
              if (controller.searchResults.isEmpty) {
                // 如果搜索框为空，不显示“未找到”，显示一些引导
                if (_searchController.text.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _buildEmptyResultWidget();
              }
              return _buildUserList();
            }),
          ),
        ],
      ),
    );
  }

  /// 构建搜索区域
  Widget _buildSearchSection(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.spacing16,
        AppSizes.spacing10,
        AppSizes.spacing16,
        AppSizes.spacing16,
      ),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
        ),
        child: TextField(
          controller: _searchController,
          textAlignVertical: TextAlignVertical.center,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            isDense: true,
            hintText: '输入用户ID或手机号搜索',
            hintStyle: const TextStyle(
                color: AppColors.textHint, fontSize: AppSizes.font14),
            prefixIcon:
                Icon(Iconfont.search, color: AppColors.textHint, size: 18),
            suffixIcon: Obx(() => _searchController.text.isNotEmpty ||
                    controller.isSearching.value
                ? IconButton(
                    icon: const Icon(Icons.cancel,
                        color: AppColors.textHint, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      controller.searchResults.clear();
                    },
                  )
                : const SizedBox.shrink()),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            // 触发 Obx 更新 suffixIcon
            controller.isSearching.refresh();
          },
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              controller.searchUser(value.trim());
            }
          },
        ),
      ),
    );
  }

  /// 构建“我的 ID”展示区
  Widget _buildMyIdSection() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(bottom: AppSizes.spacing16),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '我的 ID: ',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: AppSizes.font14),
            ),
            Obx(() => Text(
                  controller.userId.value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppSizes.font14,
                    fontWeight: FontWeight.bold,
                  ),
                )),
            const SizedBox(width: AppSizes.spacing8),
            Icon(Iconfont.scan, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  /// 加载中状态
  Widget _buildSearchingWidget() {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  /// 未找到结果状态
  Widget _buildEmptyResultWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconfont.fromName('71shibai'),
              size: 70, color: AppColors.textHint.withOpacity(0.5)),
          const SizedBox(height: AppSizes.spacing16),
          const Text(
            '没有找到相关用户',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: AppSizes.font15),
          ),
        ],
      ),
    );
  }

  /// 搜索结果用户列表
  Widget _buildUserList() {
    return Container(
      color: AppColors.surface,
      child: ListView.separated(
        itemCount: controller.searchResults.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, indent: 72, color: AppColors.divider),
        itemBuilder: (context, index) {
          final user = controller.searchResults[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing16, vertical: AppSizes.spacing4),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radius8),
              child: Container(
                width: 44,
                height: 44,
                color: AppColors.background,
                child: (user.avatar != null && user.avatar!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: user.fullAvatar,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Icon(Iconfont.person,
                            color: AppColors.textHint, size: 24),
                        errorWidget: (context, url, error) => Icon(
                            Iconfont.person,
                            color: AppColors.textHint,
                            size: 24),
                      )
                    : Icon(Iconfont.person,
                        color: AppColors.textHint, size: 24),
              ),
            ),
            title: Text(
              user.name,
              style: const TextStyle(
                fontSize: AppSizes.font16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'ID: ${user.friendId}',
              style: const TextStyle(
                  fontSize: AppSizes.font13, color: AppColors.textSecondary),
            ),
            trailing: Icon(Iconfont.fromName('right'),
                size: 14, color: AppColors.textHint),
            onTap: () {
              Get.toNamed("${Routes.HOME}${Routes.FRIEND_PROFILE}",
                  arguments: {'userId': user.friendId});
            },
          );
        },
      ),
    );
  }
}
