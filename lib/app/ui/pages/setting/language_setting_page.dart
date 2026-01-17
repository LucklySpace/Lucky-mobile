import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../widgets/icon/icon_font.dart';

/// 多语言设置页面
class LanguageSettingPage extends StatefulWidget {
  const LanguageSettingPage({super.key});

  @override
  State<LanguageSettingPage> createState() => _LanguageSettingPageState();
}

class _LanguageSettingPageState extends State<LanguageSettingPage> {
  // 当前选择的语言
  String _selectedLanguage = 'zh_CN';

  // 支持的语言列表
  final List<Map<String, String>> _languages = [
    {'code': 'zh_CN', 'name': '简体中文'},
    {'code': 'zh_TW', 'name': '繁體中文'},
    {'code': 'en_US', 'name': 'English'},
    {'code': 'ja_JP', 'name': '日本語'},
    {'code': 'ko_KR', 'name': '한국어'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing12),
        children: [
          _buildLanguageGroup(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('多语言设置'),
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

  Widget _buildLanguageGroup() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
      ),
      child: Column(
        children: _languages.asMap().entries.map((entry) {
          final index = entry.key;
          final language = entry.value;
          final isSelected = language['code'] == _selectedLanguage;

          return Column(
            children: [
              _buildLanguageItem(language, isSelected),
              if (index < _languages.length - 1)
                const Divider(height: 1, indent: 20, color: AppColors.divider),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLanguageItem(Map<String, String> language, bool isSelected) {
    return InkWell(
      onTap: () => _selectLanguage(language['code']!),
      borderRadius: BorderRadius.circular(AppSizes.radius12),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing16, vertical: AppSizes.spacing16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                language['name']!,
                style: TextStyle(
                  fontSize: AppSizes.font16,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Iconfont.fromName('chenggong'),
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _selectLanguage(String code) {
    setState(() {
      _selectedLanguage = code;
    });

    // TODO: 实现语言切换逻辑
    Get.snackbar(
      '提示',
      '语言已切换',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface.withOpacity(0.9),
      colorText: AppColors.textPrimary,
    );
  }
}
