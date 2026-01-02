import 'package:flutter/material.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../models/chats.dart';
import '../../widgets/badge/badge.dart';

/// 聊天头像组件，显示用户或群聊头像及未读消息徽章
/// 支持自定义头像形状、徽章样式及大小
class ChatAvatar extends StatelessWidget {
  // 常量定义
  static const _defaultAvatarSize = AppSizes.spacing48; // 默认头像大小
  static const _defaultIconSize = AppSizes.iconLarge; // 默认占位图标大小
  static const _defaultBorderRadius = AppSizes.radius8; // 默认矩形头像圆角

  final Chats chats; // 聊天数据
  final BoxShape avatarShape; // 头像形状

  /// 构造函数
  const ChatAvatar({
    super.key,
    required this.chats,
    this.avatarShape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return CustomBadge(
      count: chats.unread,
      max: 99,
      offset: const Offset(0, 0),
      child: _buildAvatar(),
    );
  }

  /// 构建头像
  Widget _buildAvatar() {
    return Container(
      width: _defaultAvatarSize,
      height: _defaultAvatarSize,
      decoration: BoxDecoration(
        color: AppColors.border, // 默认背景色
        shape: avatarShape,
        borderRadius: avatarShape == BoxShape.rectangle
            ? BorderRadius.circular(_defaultBorderRadius)
            : null,
        image: chats.avatar.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(chats.avatar),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  // 头像加载失败时记录日志
                  debugPrint('头像加载失败: $exception');
                },
              )
            : null,
      ),
      child: chats.avatar.isEmpty
          ? const Icon(
              Icons.person,
              size: _defaultIconSize,
              color: AppColors.textSecondary,
            )
          : null,
    );
  }
}
