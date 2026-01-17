import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../widgets/icon/icon_font.dart';

/// 存储管理页面
class StorageSettingPage extends StatefulWidget {
  const StorageSettingPage({super.key});

  @override
  State<StorageSettingPage> createState() => _StorageSettingPageState();
}

class _StorageSettingPageState extends State<StorageSettingPage> {
  // 存储使用情况（模拟数据）
  final List<Map<String, dynamic>> _storageItems = [
    {
      'title': '聊天图片',
      'size': 128.5,
    },
    {
      'title': '聊天视频',
      'size': 256.8,
    },
    {
      'title': '语音消息',
      'size': 45.2,
    },
    {
      'title': '文件',
      'size': 89.6,
    },
    {
      'title': '缓存',
      'size': 156.3,
    },
  ];

  double get _totalUsage =>
      _storageItems.map((e) => e['size'] as double).reduce((a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: AppSizes.spacing20),

          // 存储概览卡片
          _buildStorageOverview(),

          const SizedBox(height: AppSizes.spacing24),

          // 存储详情列表
          _buildSection('详情占用', [
            _buildStorageDetails(),
          ]),

          const SizedBox(height: AppSizes.spacing24),

          // 清理操作
          _buildSection('快速清理', [
            _buildActionTile(
                '一键清理缓存', '清理应用运行产生的临时文件', () => _showClearCacheDialog()),
          ]),

          const SizedBox(height: AppSizes.spacing32),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('存储管理'),
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
        ...children,
      ],
    );
  }

  /// 构建存储概览卡片
  Widget _buildStorageOverview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
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
          const Text(
            '已用存储空间',
            style: TextStyle(
              fontSize: AppSizes.font14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.spacing12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: _totalUsage.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const TextSpan(
                  text: ' MB',
                  style: TextStyle(
                    fontSize: AppSizes.font16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacing24),
          // 进度条
          Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.35, // 假设总空间为 1000MB
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF64B5F6)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '已使用 35%',
                style: TextStyle(
                  fontSize: AppSizes.font12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '可用 643.2 MB / 1000 MB',
                style: TextStyle(
                  fontSize: AppSizes.font12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建存储详情列表
  Widget _buildStorageDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
      ),
      child: Column(
        children: _storageItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _buildStorageItem(item),
              if (index < _storageItems.length - 1)
                const Divider(height: 1, indent: 20, color: AppColors.divider),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// 构建单个存储项
  Widget _buildStorageItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing16,
        vertical: AppSizes.spacing16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item['title'],
              style: const TextStyle(
                fontSize: AppSizes.font16,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '${(item['size'] as double).toStringAsFixed(1)} MB',
            style: const TextStyle(
              fontSize: AppSizes.font14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作项
  Widget _buildActionTile(String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacing16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppSizes.font16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: AppSizes.font12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Iconfont.fromName('right'),
                  size: 14, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示清理缓存对话框
  void _showClearCacheDialog() {
    final cacheItem = _storageItems.firstWhere((e) => e['title'] == '缓存');
    final cacheSize = cacheItem['size'] as double;

    if (cacheSize <= 0) {
      Get.snackbar('提示', '暂无缓存需要清理', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('清理缓存'),
        content: Text('确定要清理 ${cacheSize.toStringAsFixed(1)} MB 缓存吗？'),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius12)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _clearCache();
            },
            child: const Text('确定',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// 清理缓存
  void _clearCache() {
    setState(() {
      for (var item in _storageItems) {
        if (item['title'] == '缓存') {
          item['size'] = 0.0;
        }
      }
    });

    Get.snackbar(
      '提示',
      '缓存已清理',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface.withOpacity(0.9),
      colorText: AppColors.textPrimary,
    );
  }
}
