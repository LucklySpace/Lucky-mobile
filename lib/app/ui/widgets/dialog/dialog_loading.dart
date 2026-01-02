import 'package:flutter/material.dart';
import 'package:flutter_im/constants/app_colors.dart';
import 'package:flutter_im/constants/app_sizes.dart';


/// @class : LoadingDialog
/// @description : 公共加载弹窗
class LoadingDialog extends StatelessWidget {
  final String text;

  const LoadingDialog({
    Key? key,
    this.text = '加载中...',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material( //创建透明层
      type: MaterialType.transparency, //透明类型
      child: Center( //保证控件居中效果
        child: SizedBox(
          width: AppSizes.spacing120,
          height: AppSizes.spacing120,
          child: Container(
            decoration: ShapeDecoration(
              color: AppColors.mask,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(AppSizes.radius8),
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(
                  width: AppSizes.spacing40,
                  height: AppSizes.spacing40,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.spacing3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                ),
                const SizedBox(height: AppSizes.spacing16),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: AppSizes.font14,
                    color: AppColors.white,
                  ),
                )
              ],
            ),
          ),
        ),
      )
    );
  }
}
