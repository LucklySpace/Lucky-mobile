import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../controller/contact_controller.dart';
import '../../../models/friend_request.dart';
import '../../widgets/icon/icon_font.dart';

/// 新的好友申请页面
class FriendRequestsPage extends GetView<ContactController> {
  const FriendRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 页面进入时刷新申请列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchFriendRequests();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('新的朋友'),
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
          _buildSearchBar(context),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingRequests.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                );
              }

              if (controller.friendRequests.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.separated(
                padding: const EdgeInsets.only(bottom: AppSizes.spacing20),
                itemCount: controller.friendRequests.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 80,
                  color: AppColors.divider,
                ),
                itemBuilder: (context, index) {
                  return _buildRequestItem(
                      context, controller.friendRequests[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing16,
        vertical: AppSizes.spacing10,
      ),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSizes.radius8),
        ),
        child: TextField(
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            isDense: true,
            hintText: '搜索好友',
            hintStyle: const TextStyle(
                color: AppColors.textHint, fontSize: AppSizes.font14),
            prefixIcon:
                Icon(Iconfont.search, color: AppColors.textHint, size: 18),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconfont.fromName('lianxiren3'),
            size: 80,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: AppSizes.spacing16),
          const Text(
            '暂无好友申请',
            style: TextStyle(
              fontSize: AppSizes.font15,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个申请项
  Widget _buildRequestItem(BuildContext context, FriendRequest request) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing16,
        vertical: AppSizes.spacing12,
      ),
      child: Row(
        children: [
          // 头像
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radius8),
            child: Container(
              width: 50,
              height: 50,
              color: AppColors.background,
              child: request.avatar != null && request.avatar!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: request.avatar!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Icon(Iconfont.person,
                          color: AppColors.textHint, size: 30),
                      errorWidget: (context, url, error) => Icon(
                          Iconfont.person,
                          color: AppColors.textHint,
                          size: 30),
                    )
                  : Icon(Iconfont.person, color: AppColors.textHint, size: 30),
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          // 名称与消息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: AppSizes.font16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing4),
                Text(
                  request.message?.isNotEmpty == true
                      ? request.message!
                      : '请求添加您为好友',
                  style: const TextStyle(
                    fontSize: AppSizes.font13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          // 按钮或状态
          _buildActionButtons(request),
        ],
      ),
    );
  }

  /// 构建操作按钮或状态文字
  Widget _buildActionButtons(FriendRequest request) {
    if (request.approveStatus == 0) {
      // 待处理
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => controller.handleFriendApprove(request.id, true),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
              minimumSize: const Size(60, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius4),
              ),
            ),
            child:
                const Text('接受', style: TextStyle(fontSize: AppSizes.font14)),
          ),
          const SizedBox(width: AppSizes.spacing8),
          TextButton(
            onPressed: () => controller.handleFriendApprove(request.id, false),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.textSecondary,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSizes.spacing12),
              minimumSize: const Size(60, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius4),
              ),
            ),
            child:
                const Text('拒绝', style: TextStyle(fontSize: AppSizes.font14)),
          ),
        ],
      );
    } else if (request.approveStatus == 1) {
      // 已接受
      return const Text(
        '已添加',
        style: TextStyle(
          color: AppColors.textHint,
          fontSize: AppSizes.font14,
        ),
      );
    } else {
      // 已拒绝
      return const Text(
        '已拒绝',
        style: TextStyle(
          color: AppColors.textHint,
          fontSize: AppSizes.font14,
        ),
      );
    }
  }
}
