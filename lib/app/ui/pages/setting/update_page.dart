import 'package:flutter/material.dart';
import 'package:flutter_im/config/app_config.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../widgets/icon/icon_font.dart';

/// 检查更新页面
class UpdatePage extends StatefulWidget {
  const UpdatePage({super.key});

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  bool _isChecking = false;
  bool _hasUpdate = false;
  String? _newVersion;
  String? _updateSize;
  List<String> _updateLog = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: AppSizes.spacing20),

          // 应用信息卡片
          _buildAppInfoCard(),

          const SizedBox(height: AppSizes.spacing24),

          // 更新设置
          _buildSettingGroup('设置', [
            _buildSwitchItem('自动检查更新', true, (value) {}),
            _buildSwitchItem('仅 Wi-Fi 下更新', true, (value) {}),
            _buildCheckUpdateItem(),
          ]),

          // 更新信息
          if (_hasUpdate) ...[
            const SizedBox(height: AppSizes.spacing24),
            _buildUpdateInfo(),
          ],

          const SizedBox(height: AppSizes.spacing32),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('检查更新'),
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

  /// 构建应用信息卡片
  Widget _buildAppInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.spacing20),
      padding: const EdgeInsets.all(AppSizes.spacing24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // App 图标
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing4),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSizes.radius20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radius16),
              child: Image.asset(
                'assets/logo/app_icon.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF64B5F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radius16),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      size: 40,
                      color: AppColors.white,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacing16),

          // 应用信息
          Text(
            AppConfig.appName,
            style: const TextStyle(
              fontSize: AppSizes.font20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spacing4),
          Text(
            '当前版本 ${AppConfig.version}',
            style: const TextStyle(
              fontSize: AppSizes.font14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.spacing12),

          // 状态行
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (_hasUpdate && !_isChecking)
                  ? AppColors.error.withOpacity(0.1)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(AppSizes.radius20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_hasUpdate && !_isChecking)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  _isChecking
                      ? '正在检查更新...'
                      : (_hasUpdate ? '发现新版本 V$_newVersion' : '已是最新版本'),
                  style: TextStyle(
                    fontSize: AppSizes.font12,
                    color:
                        _hasUpdate ? AppColors.error : AppColors.textSecondary,
                    fontWeight:
                        _hasUpdate ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建检查更新项
  Widget _buildCheckUpdateItem() {
    return InkWell(
      onTap: _isChecking ? null : _checkUpdate,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing16, vertical: AppSizes.spacing16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '检查更新',
                style: const TextStyle(
                    fontSize: AppSizes.font16, color: AppColors.textPrimary),
              ),
            ),
            if (_isChecking)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            else
              Icon(Iconfont.fromName('right'),
                  size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  /// 构建更新信息卡片
  Widget _buildUpdateInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      padding: const EdgeInsets.all(AppSizes.spacing24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF64B5F6)],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radius4),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacing8),
              Text(
                '版本 V$_newVersion',
                style: const TextStyle(
                  fontSize: AppSizes.font18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (_updateSize != null)
                Text(
                  _updateSize!,
                  style: const TextStyle(
                    fontSize: AppSizes.font14,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing20),
          const Text(
            '更新日志',
            style: TextStyle(
              fontSize: AppSizes.font15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spacing12),
          ...(_updateLog.map((log) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spacing8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8, right: 10),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        log,
                        style: const TextStyle(
                          fontSize: AppSizes.font14,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ))),
          const SizedBox(height: AppSizes.spacing24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _downloadUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius24),
                ),
              ),
              child: const Text(
                '立即更新',
                style: TextStyle(
                  fontSize: AppSizes.font16,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSizes.spacing20, 0, AppSizes.spacing20, AppSizes.spacing8),
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

  /// 构建开关设置项
  Widget _buildSwitchItem(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
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
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _checkUpdate() async {
    setState(() {
      _isChecking = true;
    });

    // 模拟实际的版本检查逻辑
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isChecking = false;
      // 模拟有新版本
      _hasUpdate = true;
      _newVersion = '2.0.0';
      _updateSize = '25.6 MB';
      _updateLog = [
        '新增视频通话功能，支持多人在线视频',
        '优化消息推送性能，消息送达更及时',
        '修复已知问题，提升系统稳定性',
        '全新设计的 UI 界面，带来更流畅的视觉体验',
      ];
    });
  }

  void _downloadUpdate() {
    Get.snackbar(
      '提示',
      '正在下载更新...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface.withOpacity(0.9),
      colorText: AppColors.textPrimary,
    );
    // TODO: 实现实际的下载更新逻辑
  }
}
