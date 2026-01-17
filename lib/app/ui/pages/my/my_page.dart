import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../routes/app_routes.dart';
import '../../../controller/user_controller.dart';
import '../../widgets/icon/icon_font.dart';

/// 个人中心页面，展示用户信息和功能入口
class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            /// 用户信息头部
            _buildHeader(context, userController),

            const SizedBox(height: AppSizes.spacing12),

            /// 功能列表区域
            _buildListSection(context),

            const SizedBox(height: AppSizes.spacing12),

            /// 退出登录
            _buildLogoutButton(context),

            const SizedBox(height: AppSizes.spacing32),
          ],
        ),
      ),
    );
  }

  /// 构建用户信息头部
  Widget _buildHeader(BuildContext context, UserController controller) {
    return Obx(() {
      final userInfo = controller.userInfo.value;
      final username = userInfo?.name ?? '未登录';
      final signature = userInfo?.selfSignature ?? '连接你我，沟通无限';
      final avatarUrl = userInfo?.avatar ?? '';
      final gender = userInfo?.gender?.toString();

      return Container(
        padding: EdgeInsets.fromLTRB(
          AppSizes.spacing20,
          MediaQuery.of(context).padding.top + AppSizes.spacing32,
          AppSizes.spacing20,
          AppSizes.spacing32,
        ),
        color: AppColors.surface,
        child: Row(
          children: [
            /// 头像
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radius12),
              child: Container(
                width: 72,
                height: 72,
                color: AppColors.background,
                child: avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Icon(Iconfont.person,
                            size: 36, color: AppColors.textHint),
                        errorWidget: (context, url, error) => Icon(
                            Iconfont.person,
                            size: 36,
                            color: AppColors.textHint),
                      )
                    : Icon(Iconfont.person,
                        size: 36, color: AppColors.textHint),
              ),
            ),
            const SizedBox(width: AppSizes.spacing16),

            /// 用户名和个性签名
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    Get.toNamed('${Routes.HOME}${Routes.USER_PROFILE}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            username,
                            style: const TextStyle(
                              fontSize: AppSizes.font22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSizes.spacing8),
                        _buildGenderIcon(gender),
                      ],
                    ),
                    const SizedBox(height: AppSizes.spacing8),
                    Text(
                      signature,
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
            ),

            /// 二维码入口
            IconButton(
              icon:
                  Icon(Iconfont.scan, size: 24, color: AppColors.textSecondary),
              onPressed: () =>
                  Get.toNamed('${Routes.HOME}${Routes.MY_QR_CODE}'),
            ),
            Icon(Iconfont.fromName('right'),
                size: 14, color: AppColors.textHint),
          ],
        ),
      );
    });
  }

  /// 构建性别图标
  Widget _buildGenderIcon(String? gender) {
    if (gender == '1') {
      return const Icon(Icons.male, color: AppColors.primary, size: 18);
    } else if (gender == '2' || gender == '0') {
      return const Icon(Icons.female, color: AppColors.female, size: 18);
    }
    return const SizedBox.shrink();
  }

  /// 构建功能列表区域
  Widget _buildListSection(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          _buildListItem(
            icon: Iconfont.fromName('wenjian'), // 临时使用文件图标代表钱包或资产
            iconColor: Colors.blue,
            title: '钱包',
            onTap: () => Get.toNamed('${Routes.HOME}${Routes.WALLET}'),
          ),
          const Divider(height: 1, indent: 56, color: AppColors.divider),
          _buildListItem(
            icon: Iconfont.scan,
            iconColor: Colors.green,
            title: '扫一扫',
            onTap: () => Get.toNamed('${Routes.HOME}${Routes.SCAN}'),
          ),
          const Divider(height: 1, indent: 56, color: AppColors.divider),
          _buildListItem(
            icon: Iconfont.setting,
            iconColor: AppColors.primary,
            title: '设置',
            onTap: () => Get.toNamed('${Routes.HOME}${Routes.SETTING}'),
          ),
        ],
      ),
    );
  }

  /// 构建退出登录按钮
  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: _buildListItem(
        icon: Icons.power_settings_new_rounded,
        iconColor: AppColors.error,
        title: '退出登录',
        showArrow: false,
        centerTitle: true,
        onTap: () => _handleLogout(context),
      ),
    );
  }

  /// 构建单个列表项
  Widget _buildListItem({
    required dynamic icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    bool showArrow = true,
    bool centerTitle = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing20, vertical: AppSizes.spacing16),
        child: Row(
          mainAxisAlignment:
              centerTitle ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            if (!centerTitle) ...[
              icon is IconData
                  ? Icon(icon, size: 22, color: iconColor)
                  : Icon(icon as IconData, size: 22, color: iconColor),
              const SizedBox(width: AppSizes.spacing16),
            ],
            Expanded(
              child: Text(
                title,
                textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  fontSize: AppSizes.font16,
                  color: centerTitle ? AppColors.error : AppColors.textPrimary,
                  fontWeight: centerTitle ? FontWeight.w600 : FontWeight.normal,
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

  /// 处理退出登录
  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('确定退出', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      Get.find<UserController>().logout();
      Get.offAllNamed(Routes.LOGIN);
    }
  }
}
