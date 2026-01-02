import 'package:flutter/material.dart';
import 'package:flutter_im/constants/app_colors.dart';
import 'package:flutter_im/constants/app_sizes.dart';


/// @class : BaseDialog
/// @description : 弹窗基类
class BaseDialog extends StatefulWidget {
  ///child
  final Widget child;

  ///圆角
  final double shape;

  ///左右边距
  final double horizontal;

  const BaseDialog({
    Key? key,
    this.shape = AppSizes.radius12,
    this.horizontal = AppSizes.spacing24,
    required this.child,
  }) : super(key: key);

  @override
  State<BaseDialog> createState() => _BaseDialogState();
}

class _BaseDialogState extends State<BaseDialog> with SingleTickerProviderStateMixin {
  ///动画加载控制器
  late AnimationController scaleController;
  late Animation<double> scaleAnimation;

  ///初始化动画控制器
  @override
  void initState() {
    super.initState();
    scaleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    scaleAnimation = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: scaleController, curve: Curves.easeOutBack));
    scaleController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        ///透明样式
        type: MaterialType.transparency,
        ///dialog居中
        child: Center(
            ///取消ListView滑动阴影
            child: ScrollConfiguration(
                behavior: const ScrollBehavior(),
                ///ListView 的shrinkWrap属性可适应高度（有多少占多少）
                child: ScaleTransition(
                    alignment: Alignment.center,
                    scale: scaleAnimation,
                    child: ListView(shrinkWrap: true, children: [
                      ///背景及内容、边距、圆角等，必须包裹在ListView中
                      Container(
                          width: double.infinity,
                          margin: EdgeInsets.symmetric(horizontal: widget.horizontal),
                          child: Container(
                            decoration: ShapeDecoration(
                              color: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(widget.shape),
                                ),
                              ),
                            ),
                            child: widget.child,
                          ))
                    ])))));
  }

  @override
  void dispose() {
    scaleController.dispose();
    super.dispose();
  }
}
