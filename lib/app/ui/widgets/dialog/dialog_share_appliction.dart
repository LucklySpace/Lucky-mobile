import 'package:flutter/material.dart';
import 'package:flutter_im/constants/app_colors.dart';
import 'package:flutter_im/constants/app_sizes.dart';
import 'package:get/get.dart';
import 'dialog_base.dart';
import 'package:url_launcher/url_launcher.dart';

/// @class : ShareApplicationDialog
/// @description : 分享应用弹窗
class ShareApplicationDialog extends StatelessWidget {
  final String url;

  const ShareApplicationDialog({Key? key, this.url = 'https://www.baidu.com'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const SizedBox(height: AppSizes.spacing32),
        const Text(
          '分享应用',
          style: TextStyle(fontSize: AppSizes.font16, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSizes.spacing6),
        const Text(
          '扫描二维码下载',
          style: TextStyle(fontSize: AppSizes.font14, color: AppColors.textHint),
        ),
        const SizedBox(height: AppSizes.spacing10),
        // Use Icon instead of Image if asset is missing
        const Icon(Icons.qr_code, size: AppSizes.spacing120, color: AppColors.textPrimary),
        const SizedBox(height: AppSizes.spacing20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ///浏览器打开
            _buildShareIcon(AppColors.wechat, Icons.public,
                () => _launchUrl(url)),

            ///保存在本地
            _buildShareIcon(AppColors.warning, Icons.download, () {
               Get.snackbar('提示', '保存功能开发中');
            }),
          ],
        ),
        const SizedBox(height: AppSizes.spacing6),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ///在浏览器打开
            Text(
              '浏览器打开',
              style: TextStyle(fontSize: AppSizes.font13, color: AppColors.textHint),
            ),

            ///保存在本地
            Text(
              '保存本地',
              style: TextStyle(fontSize: AppSizes.font13, color: AppColors.textHint),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacing32),
        const Divider(height: AppSizes.spacing1, color: AppColors.divider),
        SizedBox(
          width: double.infinity,
          height: AppSizes.spacing60,
          child: TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text(
              '取消',
              style: TextStyle(fontSize: AppSizes.font16, color: AppColors.textPrimary),
            ),
          ),
        )
      ],
    ));
  }

  Widget _buildShareIcon(Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spacing10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSizes.radius30),
        ),
        child: Icon(
          icon,
          color: color,
          size: AppSizes.spacing30,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      Get.snackbar('Error', 'Could not launch $url');
    }
  }
}
