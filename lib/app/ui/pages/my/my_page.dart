import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../routes/app_routes.dart';
import '../../../controller/user_controller.dart';
import '../../widgets/icon/icon_font.dart';

/// 个人中心页面，展示用户信息和功能入口
/// 特性：
/// - 显示用户头像、用户名、性别和个性签名。
/// - 提供扫一扫、设置、退出登录等功能入口。
/// - 支持二维码页面导航，展示用户二维码。
class MyPage extends StatelessWidget {
  // 常量定义
  static const _userInfoPadding = EdgeInsets.symmetric(
    vertical: AppSizes.spacing20,
    horizontal: AppSizes.spacing16,
  ); // 用户信息边距
  static const _avatarSize = AppSizes.spacing50; // 头像尺寸
  static const _avatarBorderRadius = AppSizes.radius8; // 头像圆角
  static const _avatarPlaceholderColor = AppColors.textHint; // 头像占位颜色
  static const _usernameStyle = TextStyle(
    fontSize: AppSizes.font18,
    fontWeight: FontWeight.bold,
  ); // 用户名样式
  static const _signatureStyle = TextStyle(
    fontSize: AppSizes.font14,
    color: AppColors.textHint,
  ); // 个性签名样式
  static const _listSpacing = AppSizes.spacing12; // 列表间距
  static const _defaultUsername = '未登录'; // 默认用户名
  static const _defaultSignature = '这个人很神秘...'; // 默认个性签名
  static const _defaultAvatar = ''; // 默认头像 URL

  /// 性别图标映射表
  static const _genderIcons = {
    '1': Icon(Icons.male, color: AppColors.primary, size: AppSizes.font18),
    '0': Icon(Icons.female, color: AppColors.female, size: AppSizes.font18),
  };

  /// 列表项数据
  static final _listItems = [
    const _ListItemData(
      icon: Icons.account_balance_wallet,
      title: '钱包',
      route: '${Routes.HOME}${Routes.WALLET}',
    ),
    const _ListItemData(
      icon: Iconfont.search,
      title: '扫一扫',
      route: '${Routes.HOME}${Routes.SCAN}',
    ),
    const _ListItemData(
      icon: Iconfont.setting,
      title: '设置',
      route: null, // TODO: 实现设置页面路由
    ),
    const _ListItemData(
      icon: Icons.exit_to_app,
      title: '退出登录',
      action: _logout,
    ),
  ];

  const MyPage({super.key});

  /// 执行退出登录操作
  static void _logout() {
    Get.find<UserController>().logout();
    Get.offAllNamed(Routes.LOGIN);
  }

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            /// 用户信息
            _buildUserInfo(userController),
            const SizedBox(height: _listSpacing),

            /// 功能列表
            _buildListItems(),
          ],
        ),
      ),
    );
  }

  // --- UI 构建方法 ---

  /// 构建用户信息区域
  Widget _buildUserInfo(UserController controller) {
    return GetX<UserController>(
      builder: (controller) {
        final userInfo = controller.userInfo;
        final username = userInfo['name'] as String? ?? _defaultUsername;
        final signature =
            userInfo['selfSignature'] as String? ?? _defaultSignature;
        final avatarUrl = userInfo['avatar'] as String? ?? _defaultAvatar;
        final gender = userInfo['gender']?.toString();

        return Container(
          padding: _userInfoPadding,
          color: AppColors.surface,
          child: Row(
            children: [
              /// 头像
              ClipRRect(
                borderRadius: BorderRadius.circular(_avatarBorderRadius),
                child: SizedBox(
                  width: _avatarSize,
                  height: _avatarSize,
                  child: avatarUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) {
                            debugPrint('加载头像失败: $error');
                            return Container(
                              color: _avatarPlaceholderColor.withOpacity(0.3),
                              child: const Icon(Icons.person,
                                  size: AppSizes.spacing45,
                                  color: AppColors.white),
                            );
                          },
                        )
                      : Container(
                          color: _avatarPlaceholderColor.withOpacity(0.3),
                          child: const Icon(Icons.person,
                              size: AppSizes.spacing45, color: AppColors.white),
                        ),
                ),
              ),
              const SizedBox(width: AppSizes.spacing16),

              /// 用户名和个性签名
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      Get.toNamed('${Routes.HOME}${Routes.USER_PROFILE}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(username, style: _usernameStyle),
                          const SizedBox(width: AppSizes.spacing4),
                          if (_genderIcons.containsKey(gender))
                            _genderIcons[gender]!,
                        ],
                      ),
                      const SizedBox(height: AppSizes.spacing4),
                      Text(signature, style: _signatureStyle),
                    ],
                  ),
                ),
              ),

              /// 二维码按钮
              IconButton(
                icon: const Icon(Icons.qr_code, size: AppSizes.iconMedium),
                onPressed: () =>
                    Get.toNamed('${Routes.HOME}${Routes.MY_QR_CODE}'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建功能列表项
  Widget _buildListItems() {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: _listItems
            .map((item) => ListTile(
                  leading: Icon(item.icon, color: AppColors.textPrimary),
                  title: Text(item.title),
                  onTap: item.route != null
                      ? () => Get.toNamed(item.route!)
                      : item.action != null
                          ? item.action
                          : null,
                ))
            .toList(),
      ),
    );
  }
}

/// 列表项数据类
class _ListItemData {
  final IconData icon;
  final String title;
  final String? route;
  final VoidCallback? action;

  const _ListItemData({
    required this.icon,
    required this.title,
    this.route,
    this.action,
  });
}
