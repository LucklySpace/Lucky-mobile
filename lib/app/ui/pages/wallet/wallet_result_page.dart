import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_im/constants/app_colors.dart';
import 'package:flutter_im/constants/app_sizes.dart';
import 'package:get/get.dart';

import '../../../../routes/app_routes.dart';

class WalletResultPage extends StatelessWidget {
  const WalletResultPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>;
    final bool isSuccess = args['success'] ?? false;
    final String title = args['title'] ?? (isSuccess ? '操作成功' : '操作失败');
    final String amount = args['amount'] ?? '0.00';
    final String? toAddress = args['toAddress'];
    final String? errorMessage = args['errorMessage'];
    final String? transactionId = args['transactionId'];

    FocusManager.instance.primaryFocus?.unfocus();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.toNamed('${Routes.HOME}'),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 1),
            // Status Icon
            Container(
              width: AppSizes.spacing80,
              height: AppSizes.spacing80,
              decoration: BoxDecoration(
                color: isSuccess
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check : Icons.close,
                size: AppSizes.spacing48,
                color: isSuccess ? AppColors.success : AppColors.error,
              ),
            ),
            const SizedBox(height: AppSizes.spacing24),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: AppSizes.font20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.spacing8),
            // Amount or Error Message
            if (isSuccess) ...[
              Text(
                '-$amount',
                style: const TextStyle(
                  fontSize: AppSizes.font32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ] else ...[
              Text(
                errorMessage ?? '未知错误',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: AppSizes.font16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSizes.spacing48),

            // Details Card (Only if success)
            if (isSuccess) ...[
              Container(
                padding: const EdgeInsets.all(AppSizes.spacing16),
                // decoration: const BoxDecoration(
                //     // color: AppColors.background,
                //     // borderRadius: BorderRadius.circular(AppSizes.radius16),
                //     // border: Border.all(color: AppColors.border),
                //     ),
                child: Column(
                  children: [
                    if (toAddress != null)
                      _buildDetailRow('接收方:', toAddress, copyable: true),
                    if (toAddress != null && transactionId != null)
                      const SizedBox(height: AppSizes.spacing16),
                    const Divider(height: AppSizes.spacing24),
                    const SizedBox(height: AppSizes.spacing16),
                    if (transactionId != null)
                      _buildDetailRow('交易ID:', transactionId, copyable: true),
                  ],
                ),
              ),
            ],

            const Spacer(flex: 2),

            // Done Button
            SizedBox(
              width: double.infinity,
              height: AppSizes.spacing50,
              child: ElevatedButton(
                onPressed: () => Get.toNamed('${Routes.HOME}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '完成',
                  style: TextStyle(
                      fontSize: AppSizes.font16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spacing40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool copyable = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppSizes.spacing70,
          child: Text(
            label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: AppSizes.font14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: AppSizes.font14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (copyable)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              Get.showSnackbar(const GetSnackBar(
                message: '已复制',
                duration: Duration(seconds: 1),
              ));
            },
            child: const Padding(
              padding: EdgeInsets.only(left: AppSizes.spacing8),
              child: Icon(Icons.copy,
                  size: AppSizes.iconSmall, color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}
