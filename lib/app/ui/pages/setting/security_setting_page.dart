import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../widgets/icon/icon_font.dart';

/// 账号与安全页面
class SecuritySettingPage extends StatelessWidget {
  const SecuritySettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: AppSizes.spacing12),

          // 账号安全
          _buildSection('账号安全', [
            _buildSettingTile('修改密码'),
            _buildSettingTile('绑定手机'),
            _buildSettingTile('绑定邮箱'),
            _buildSettingTile('账号注销'),
          ]),

          // 登录安全
          _buildSection('登录安全', [
            _buildSwitchTile('指纹登录', true),
            _buildSwitchTile('面容登录', false),
          ]),

          // 隐私设置
          _buildSection('隐私设置', [
            _buildSettingTile('加好友设置'),
            _buildSettingTile('加群设置'),
            _buildSwitchTile('显示在线状态', true),
          ]),

          // 黑名单管理
          _buildSection('黑名单', [
            _buildBlackListTile(),
          ]),

          const SizedBox(height: AppSizes.spacing32),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('账号与安全'),
      centerTitle: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: AppColors.textPrimary, size: 20),
        onPressed: () => Get.back(),
      ),
    );
  }

  /// 构建设置分组
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.spacing20,
              AppSizes.spacing16, AppSizes.spacing20, AppSizes.spacing8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: AppSizes.font13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radius12),
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              return Column(
                children: [
                  entry.value,
                  if (entry.key < children.length - 1)
                    const Divider(
                        height: 1, indent: 20, color: AppColors.divider),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 构建普通设置项
  Widget _buildSettingTile(String title) {
    return InkWell(
      onTap: () {
        Get.snackbar('提示', '功能开发中',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.surface.withOpacity(0.9),
            colorText: AppColors.textPrimary);
      },
      borderRadius: BorderRadius.circular(AppSizes.radius12),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing16, vertical: AppSizes.spacing16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: AppSizes.font16, color: AppColors.textPrimary),
              ),
            ),
            Icon(Iconfont.fromName('right'),
                size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  /// 构建开关设置项
  Widget _buildSwitchTile(String title, bool value) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing16, vertical: AppSizes.spacing8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: AppSizes.font16, color: AppColors.textPrimary),
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {},
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  /// 构建黑名单项
  Widget _buildBlackListTile() {
    return InkWell(
      onTap: () =>
          Get.to(() => const BlacklistPage(), transition: Transition.cupertino),
      borderRadius: BorderRadius.circular(AppSizes.radius12),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing16, vertical: AppSizes.spacing16),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                '黑名单',
                style: TextStyle(
                    fontSize: AppSizes.font16, color: AppColors.textPrimary),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '3',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Iconfont.fromName('right'),
                size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

/// 黑名单管理页面
class BlacklistPage extends StatelessWidget {
  const BlacklistPage({super.key});

  final List<Map<String, dynamic>> _blacklist = const [
    {'name': '用户A', 'reason': '骚扰消息', 'time': '2024-01-10'},
    {'name': '用户B', 'reason': '不当言论', 'time': '2024-01-08'},
    {'name': '用户C', 'reason': '广告推销', 'time': '2024-01-05'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('黑名单'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: _blacklist.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing12),
              itemCount: _blacklist.length,
              itemBuilder: (context, index) {
                final user = _blacklist[index];
                return Column(
                  children: [
                    _buildBlacklistItem(context, user),
                    if (index < _blacklist.length - 1)
                      const Divider(
                          height: 1, indent: 76, color: AppColors.divider),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconfont.fromName('71shibai'),
              size: 80, color: AppColors.textHint.withOpacity(0.3)),
          const SizedBox(height: AppSizes.spacing16),
          const Text('暂无黑名单用户',
              style: TextStyle(
                  fontSize: AppSizes.font15, color: AppColors.textHint)),
        ],
      ),
    );
  }

  Widget _buildBlacklistItem(BuildContext context, Map<String, dynamic> user) {
    return Container(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing20, vertical: AppSizes.spacing12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radius8),
              ),
              alignment: Alignment.center,
              child: Text(
                user['name'][0],
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            ),
            const SizedBox(width: AppSizes.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name'],
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('原因: ${user['reason']}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _showUnblockDialog(user['name']),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.background,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius16)),
              ),
              child: const Text('解除',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnblockDialog(String name) {
    Get.dialog(
      AlertDialog(
        title: const Text('解除拉黑'),
        content: Text('确定要将 $name 移出黑名单吗？'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar('提示', '已解除拉黑', snackPosition: SnackPosition.BOTTOM);
            },
            child: const Text('确定', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
