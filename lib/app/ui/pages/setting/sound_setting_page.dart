import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../widgets/icon/icon_font.dart';

/// 声音与振动设置页面
class SoundSettingPage extends StatefulWidget {
  const SoundSettingPage({super.key});

  @override
  State<SoundSettingPage> createState() => _SoundSettingPageState();
}

class _SoundSettingPageState extends State<SoundSettingPage> {
  // 声音和振动设置
  bool _messageSound = true;
  bool _groupSound = true;
  bool _callSound = true;
  bool _vibrate = true;
  String _ringtone = 'default';
  int _vibrateIntensity = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSection('提示音设置', [
            _buildSwitchTile(
              '私聊消息提示音',
              _messageSound,
              (value) => setState(() => _messageSound = value),
            ),
            _buildSwitchTile(
              '群聊消息提示音',
              _groupSound,
              (value) => setState(() => _groupSound = value),
            ),
            _buildSwitchTile(
              '通话铃声',
              _callSound,
              (value) => setState(() => _callSound = value),
            ),
          ]),
          const SizedBox(height: AppSizes.spacing20),
          _buildSection('铃声选择', [
            _buildSettingTile(
              '消息铃声',
              _getRingtoneName(_ringtone),
              _showRingtoneSelector,
            ),
          ]),
          const SizedBox(height: AppSizes.spacing20),
          _buildSection('振动设置', [
            _buildSwitchTile(
              '启用振动',
              _vibrate,
              (value) => setState(() => _vibrate = value),
            ),
            if (_vibrate) _buildVibrateIntensitySelector(),
          ]),
          const SizedBox(height: AppSizes.spacing32),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('声音与振动'),
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

  Widget _buildSwitchTile(
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

  Widget _buildSettingTile(
    String title,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
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
            Text(
              value,
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

  Widget _buildVibrateIntensitySelector() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '振动强度',
            style: TextStyle(
              fontSize: AppSizes.font14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.spacing16),
          Row(
            children: List.generate(5, (index) {
              final intensity = index + 1;
              final isSelected = _vibrateIntensity >= intensity;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _vibrateIntensity = intensity),
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < 4 ? AppSizes.spacing8 : 0,
                    ),
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [AppColors.primary, Color(0xFF64B5F6)])
                          : null,
                      color: isSelected ? null : AppColors.background,
                      borderRadius: BorderRadius.circular(AppSizes.radius16),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        intensity.toString(),
                        style: TextStyle(
                          color:
                              isSelected ? AppColors.white : AppColors.textHint,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getRingtoneName(String code) {
    switch (code) {
      case 'default':
        return '默认铃声';
      case 'silent':
        return '静音';
      case 'classic':
        return '经典';
      case 'modern':
        return '现代';
      default:
        return '默认铃声';
    }
  }

  void _showRingtoneSelector() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppSizes.spacing20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppSizes.radius20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '选择铃声',
              style: TextStyle(
                  fontSize: AppSizes.font18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.spacing16),
            ...['default', 'silent', 'classic', 'modern'].map((type) {
              final isSelected = _ringtone == type;
              return ListTile(
                title: Text(_getRingtoneName(type)),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _ringtone = type);
                  Get.back();
                },
              );
            }).toList(),
            const SizedBox(height: AppSizes.spacing20),
          ],
        ),
      ),
    );
  }
}
