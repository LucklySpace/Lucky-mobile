import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';

class UserAvatarName extends StatelessWidget {
  final String? avatar;
  final String? name;
  final VoidCallback? onTap;
  final double avatarSize;
  final double borderRadius;

  const UserAvatarName({
    Key? key,
    this.avatar,
    this.name,
    this.onTap,
    this.avatarSize = AppSizes.spacing40,
    this.borderRadius = AppSizes.radius8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: avatarSize,
        height: avatarSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: AppColors.background,
        ),
        clipBehavior: Clip.hardEdge,
        child: avatar != null
            ? CachedNetworkImage(
                imageUrl: avatar!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    width: AppSizes.spacing20,
                    height: AppSizes.spacing20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.person,
                  color: AppColors.textHint,
                ),
              )
            : const Icon(
                Icons.person,
                color: AppColors.textHint,
              ),
      ),
      title: Text(
        name ?? '',
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      onTap: onTap,
    );
  }
}
