import 'package:flutter/material.dart';
import 'package:flutter_im/config/app_config.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../routes/app_routes.dart';
import '../../widgets/icon/icon_font.dart';

/// 关于页面
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: AppSizes.spacing20),
                      // 应用信息卡片
                      _buildAppInfoCard(),

                      // const SizedBox(height: AppSizes.spacing20),

                      // 产品信息
                      _buildSettingGroup('', [
                        _buildSettingItem('官方网站', ''),
                        _buildSettingItem('开源许可', ''),
                      ]),

                      // 自动撑开中间剩余空间
                      const Spacer(),

                      // 底部版权信息
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.spacing24),
                        child: Center(
                          child: Text(
                            '© ${DateTime.now().year} ${AppConfig.companyName}\nAll Rights Reserved',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: AppSizes.font12,
                              color: AppColors.textHint,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('关于我们'),
      centerTitle: true,
      elevation: 0,
    );
  }

  /// 构建应用信息卡片
  Widget _buildAppInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      padding: const EdgeInsets.all(AppSizes.spacing24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
      ),
      child: Row(
        children: [
          // App 图标
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radius12),
            child: Image.asset(
              'assets/logo/app_icon.png',
              width: AppSizes.spacing64,
              height: AppSizes.spacing64,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: AppSizes.spacing64,
                  height: AppSizes.spacing64,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                  ),
                  child: const Icon(
                    Icons.chat_bubble,
                    size: AppSizes.spacing36,
                    color: AppColors.white,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: AppSizes.spacing16),

          // 应用信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConfig.appName,
                  style: const TextStyle(
                    fontSize: AppSizes.font18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing4),
                Text(
                  '版本 ${AppConfig.version}',
                  style: TextStyle(
                    fontSize: AppSizes.font14,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建设置分组
  Widget _buildSettingGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing20,
              vertical: AppSizes.spacing12,
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppSizes.font14,
                color: AppColors.textHint,
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
              final index = entry.key;
              final child = entry.value;
              return Column(
                children: [
                  child,
                  if (index < children.length - 1)
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

  /// 构建设置项
  Widget _buildSettingItem(String title, String content) {
    return InkWell(
      onTap: () {
        if (title == "官方网站") {
          _navigateTo(Routes.WEB_VIEW, arguments: {'url': AppConfig.website});
        } else if (title == '服务条款' || title == '隐私政策') {
          // TODO: 显示服务条款或隐私政策
        } else if (title == '开源许可') {
          _showOpenSourceLicenses();
        }
      },
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
            if (content.isNotEmpty)
              Text(
                content,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppSizes.font14,
                ),
              ),
            const SizedBox(width: AppSizes.spacing4),
            Icon(Iconfont.fromName('right'),
                size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  /// 页面跳转并处理返回
  Future<void> _navigateTo(String route,
      {Map<String, dynamic>? arguments}) async {
    try {
      await Get.toNamed(route, arguments: arguments);
    } catch (err) {
      debugPrint('❌ 页面跳转失败: $err');
      Get.back();
    }
  }

  void _showOpenSourceLicenses() {
    Get.to(
      () => Scaffold(
        appBar: AppBar(
          title: const Text('开源许可'),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSizes.spacing16),
          children: [
            Text(
              '本项目使用的开源库：\n\n'
              '- Flutter\n'
              '- GetX\n'
              '- Dio\n'
              '- Cached Network Image\n'
              '- Photo View\n'
              '- Image Picker\n'
              '- Get Storage\n'
              '- Flutter Secure Storage\n'
              '\n感谢所有开源贡献者！',
              style: TextStyle(
                fontSize: AppSizes.font14,
                height: 1.8,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
