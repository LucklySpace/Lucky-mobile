import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../routes/app_routes.dart';
import '../../../models/message_receive.dart';
import '../icon/icon_font.dart';

class ImageBubble extends StatelessWidget {
  final IMessage message;
  final bool isMe;
  final String name;
  final String avatar;

  const ImageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.name,
    required this.avatar,
  }) : super(key: key);

  static const _maxSize = AppSizes.spacing200;
  static const _avatarSize = AppSizes.spacing40;
  static const _avatarBorderRadius = AppSizes.radius8;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing16, vertical: AppSizes.spacing8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _buildAvatar(context),
            const SizedBox(width: AppSizes.spacing8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildTimeAndName(context),
                const SizedBox(height: AppSizes.spacing4),
                GestureDetector(
                  onTap: () {
                    // 点击查看大图
                  },
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: _maxSize,
                      maxHeight: _maxSize,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSizes.radius12),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadow,
                          spreadRadius: AppSizes.spacing1,
                          blurRadius: AppSizes.spacing3,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radius12),
                      child: CachedNetworkImage(
                        imageUrl: message.messageBody.toString(),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.error,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: AppSizes.spacing8),
            _buildAvatar(context),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeAndName(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isMe) ...[
          Text(
            name,
            style: const TextStyle(
              fontSize: AppSizes.font12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppSizes.spacing8),
        ],
        Text(
          _formatTime(message.messageTime ?? 0),
          style: const TextStyle(
            fontSize: AppSizes.font12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return GestureDetector(
      onTap: isMe
          ? null
          : () => Get.toNamed('${Routes.HOME}${Routes.FRIEND_PROFILE}',
              arguments: {'userId': message.fromId}),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_avatarBorderRadius),
        child: CachedNetworkImage(
          imageUrl: avatar,
          width: _avatarSize,
          height: _avatarSize,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: AppColors.border,
            child: Iconfont.buildIcon(
                icon: Iconfont.person,
                size: AppSizes.iconMedium,
                color: AppColors.textHint),
          ),
          errorWidget: (context, url, error) => Container(
            color: AppColors.border,
            child: Iconfont.buildIcon(
                icon: Iconfont.person,
                size: AppSizes.iconMedium,
                color: AppColors.textHint),
          ),
        ),
      ),
    );
  }

  String _formatTime(int timestamp) {
    final DateTime time = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
