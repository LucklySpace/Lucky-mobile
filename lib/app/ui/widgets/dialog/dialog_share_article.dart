import 'package:flutter/material.dart';
import 'package:flutter_im/constants/app_colors.dart';
import 'package:flutter_im/constants/app_sizes.dart';
import 'package:get/get.dart';

import 'dialog_base.dart';

/// @class : ShareArticleDialog
/// @description : 分享文章弹窗
class ShareArticleDialog extends StatelessWidget {
  ///分享的链接
  final String url;

  ///分享的文章标题
  final String title;

  final Function(String title)? onConfirm;

  ShareArticleDialog({
    Key? key,
    this.url = 'https://www.baidu.com',
    this.title = '',
    this.onConfirm,
  }) : super(key: key);

  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    _controller.text = title;
    return BaseDialog(
        horizontal: AppSizes.spacing50,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: AppSizes.spacing20),
              const Text(
                '分享文章',
                style: TextStyle(
                  fontSize: AppSizes.font16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.spacing20),
              Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacing20),
                  child: Text(
                    url,
                    style: const TextStyle(
                      fontSize: AppSizes.font16,
                      color: AppColors.warning,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )),
              const SizedBox(height: AppSizes.spacing20),
              Container(
                  height: AppSizes.spacing36,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacing20),
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.text,
                    textAlign: TextAlign.left,
                    autofocus: true,
                    maxLines: 1,
                    style: const TextStyle(
                        fontSize: AppSizes.font14,
                        color: AppColors.textSecondary),
                    decoration: InputDecoration(
                        fillColor: AppColors.background,
                        filled: true,
                        hintText: '请输入标题',
                        hintStyle: const TextStyle(
                            fontSize: AppSizes.font14,
                            color: AppColors.textHint),
                        border: _getEditBorder(false),
                        focusedBorder: _getEditBorder(true),
                        enabledBorder: _getEditBorder(false),
                        contentPadding: const EdgeInsets.only(
                            left: AppSizes.spacing10,
                            right: AppSizes.spacing10)),
                  )),
              const SizedBox(height: AppSizes.spacing20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                      onTap: () {
                        if (onConfirm != null) {
                          onConfirm!(_controller.text);
                        }
                        Get.back();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.spacing6,
                            horizontal: AppSizes.spacing12),
                        decoration: BoxDecoration(
                          color: AppColors.wechat,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radius20),
                        ),
                        child: const Text(
                          '分享',
                          style: TextStyle(
                              fontSize: AppSizes.font14,
                              color: AppColors.textWhite),
                        ),
                      ))
                ],
              ),
              const SizedBox(height: AppSizes.spacing20),
            ]));
  }

  OutlineInputBorder _getEditBorder(bool isEdit) {
    return OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.radius30)),
      borderSide: BorderSide(
        color: isEdit ? AppColors.wechat : AppColors.border,
        width: AppSizes.spacing1,
      ),
    );
  }
}
