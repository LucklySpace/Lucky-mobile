import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../routes/app_routes.dart';
import '../../../controller/contact_controller.dart';

class AddFriendPage extends StatelessWidget {
  AddFriendPage({Key? key}) : super(key: key) {
    final ContactController controller = Get.find<ContactController>();
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
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new, color: AppColors.textWhite),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          /// **优化搜索框样式**
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.spacing16,
              AppSizes.spacing8,
              AppSizes.spacing16,
              AppSizes.spacing16,
            ),
            child: Material(
              elevation: 0,
              borderRadius: BorderRadius.circular(AppSizes.radius8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '输入用户ID或手机号搜索',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textHint),
                    onPressed: () => _searchController.clear(),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing16,
                    vertical: AppSizes.spacing12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    controller.searchUser(value);
                  }
                },
              ),
            ),
          ),

          /// **搜索结果**
          Expanded(
            child: Obx(() {
              if (controller.isSearching.value) {
                return _buildSearchingWidget(context);
              }
              if (controller.searchResults.isEmpty) {
                return _buildEmptyResultWidget(context);
              }
              return _buildUserList();
            }),
          ),
        ],
      ),
    );
  }

  /// **加载中**
  Widget _buildSearchingWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: AppSizes.spacing16),
          const Text(
            '正在搜索...',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: AppSizes.font14),
          ),
        ],
      ),
    );
  }

  /// **未找到结果**
  Widget _buildEmptyResultWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.search_off_rounded,
              size: AppSizes.spacing80, color: AppColors.textDisabled),
          SizedBox(height: AppSizes.spacing12),
          Text(
            '没有找到相关用户',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppSizes.font16,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// **用户列表**
  Widget _buildUserList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
      itemCount: controller.searchResults.length,
      itemBuilder: (context, index) {
        final user = controller.searchResults[index];

        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing16,
            vertical: AppSizes.spacing6,
          ),
          color: AppColors.surface,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.surface,
              child: _isValidUrl(user.avatar)
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: user.avatar!,
                        width: AppSizes.spacing40,
                        height: AppSizes.spacing40,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Icon(Icons.person,
                            color: AppColors.textDisabled),
                        errorWidget: (context, url, error) => const Icon(
                            Icons.person,
                            color: AppColors.textDisabled),
                      ),
                    )
                  : const Icon(Icons.person, color: AppColors.textDisabled),
            ),
            title: Text(user.name ?? "",
                style: const TextStyle(fontWeight: FontWeight.w500)),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textDisabled),
            onTap: () {
              // TODO: 可添加查看详情逻辑
              Get.toNamed("${Routes.HOME}${Routes.FRIEND_PROFILE}",
                  arguments: {'userId': user.friendId});
            },
          ),
        );
      },
    );
  }

  /// 检查URL是否有效
  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final Uri uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}
