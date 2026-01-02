import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../controller/contact_controller.dart';
import '../../../models/friend_request.dart';

class FriendRequestsPage extends GetView<ContactController> {
  const FriendRequestsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ContactController contactController = Get.find<ContactController>();
    contactController.fetchFriendRequests();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('新的朋友'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textWhite),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingRequests.value) {
                return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)));
              }
              if (controller.friendRequests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.person_add_disabled,
                    size: AppSizes.spacing64,
                    color: AppColors.textDisabled,
                  ),
                      SizedBox(height: AppSizes.spacing16),
                      Text(
                        '暂无好友申请',
                        style: TextStyle(
                          fontSize: AppSizes.font16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
                itemCount: controller.friendRequests.length,
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

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.spacing16,
        AppSizes.spacing8,
        AppSizes.spacing16,
        AppSizes.spacing16,
      ),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        child: TextField(
          decoration: InputDecoration(
            hintText: '搜索',
            hintStyle: const TextStyle(color: AppColors.textHint),
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing16,
              vertical: AppSizes.spacing12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radius12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radius12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radius12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestItem(BuildContext context, FriendRequest request) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing16,
        vertical: AppSizes.spacing6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing12),
        child: Row(
          children: [
            // 圆角矩形头像
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radius8),
              child: Container(
                width: AppSizes.spacing50,
                height: AppSizes.spacing50,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppSizes.radius8),
                ),
                child: request.avatar.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: request.avatar,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Icon(
                          Icons.person,
                          size: AppSizes.spacing30,
                          color: AppColors.textDisabled,
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.person,
                          size: AppSizes.spacing30,
                          color: AppColors.textDisabled,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: AppSizes.spacing30,
                        color: AppColors.textDisabled,
                      ),
              ),
            ),
            const SizedBox(width: AppSizes.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: AppSizes.font16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing4),
                  // 显示验证消息
                  Text(
                    request.message.isEmpty ? '请求添加您为好友' : request.message,
                    style: const TextStyle(
                      fontSize: AppSizes.font14,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _buildActionButtons(context, request),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, FriendRequest request) {
    if (request.approveStatus == 0) {
      // 未处理状态，显示同意和拒绝按钮
      return Row(
        children: [
          ElevatedButton(
            onPressed: () => controller.handleFriendApprove(request.id, 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius6),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing12,
                vertical: AppSizes.spacing8,
              ),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('同意'),
          ),
          const SizedBox(width: AppSizes.spacing8),
          OutlinedButton(
            onPressed: () => controller.handleFriendApprove(request.id, 2),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius6),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing12,
                vertical: AppSizes.spacing8,
              ),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '拒绝',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    } else if (request.approveStatus == 1) {
      // 已同意状态
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing12,
          vertical: AppSizes.spacing8,
        ),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radius6),
        ),
        child: const Text(
          '已同意',
          style: TextStyle(
            color: AppColors.success,
            fontSize: AppSizes.font12,
          ),
        ),
      );
    } else {
      // 已拒绝状态
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing12,
          vertical: AppSizes.spacing8,
        ),
        decoration: BoxDecoration(
          color: AppColors.textDisabled.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppSizes.radius6),
        ),
        child: const Text(
          '已拒绝',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppSizes.font12,
          ),
        ),
      );
    }
  }
}
