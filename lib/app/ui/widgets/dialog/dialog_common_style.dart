import 'package:flutter/material.dart';
import 'package:flutter_im/constants/app_colors.dart';
import 'package:flutter_im/constants/app_sizes.dart';
import 'package:get/get.dart';

import 'dialog_base.dart';

/// @class : DialogCommonStyle
/// @description : 公共确认弹窗
class DialogCommonStyle extends StatelessWidget {
  final String title;
  final String content;
  final String? backText; // Cancel text
  final String? nextText; // Confirm text
  final VoidCallback? backTap;
  final VoidCallback? nextTap;
  final bool backVisible;
  final bool nextVisible;

  const DialogCommonStyle({
    Key? key,
    this.title = '',
    this.content = '',
    this.backText,
    this.nextText,
    this.backTap,
    this.nextTap,
    this.backVisible = true,
    this.nextVisible = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: AppSizes.spacing16),
          Text(
            title,
            style: const TextStyle(
              fontSize: AppSizes.font18,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing16, vertical: AppSizes.spacing12),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: AppSizes.font16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: AppSizes.spacing1, color: AppColors.divider),
          SizedBox(
            height: AppSizes.spacing48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (backVisible)
                  Expanded(
                    child: _buildTextButton(
                      context,
                      backTap ?? () => Get.back(),
                      backText ?? '取消',
                      AppColors.textSecondary,
                    ),
                  ),
                if (backVisible && nextVisible)
                  const VerticalDivider(
                      width: AppSizes.spacing1, color: AppColors.divider),
                if (nextVisible)
                  Expanded(
                    child: _buildTextButton(
                      context,
                      nextTap,
                      nextText ?? '确定',
                      AppColors.primary,
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextButton(
      BuildContext context, VoidCallback? onTap, String text, Color color) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        padding: EdgeInsets.zero,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppSizes.font16,
          color: color,
        ),
      ),
    );
  }
}
