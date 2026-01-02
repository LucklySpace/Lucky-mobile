// badge.dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';

/// 徽章组件：支持 status/color/dot/count/max/offset 等特性
class CustomBadge extends StatefulWidget {
  /// 包裹的子组件（相当于 Vue 的 default slot）
  final Widget? child;

  /// 状态点（优先级高于 color）
  final BadgeStatus? status;

  /// 自定义颜色（当 status 为 null 时生效）
  final Color? color;

  /// 数字徽章数量
  final int? count;

  /// 数值上限，超过显示为 'max+'
  final int max;

  /// 当 count==0 时是否仍然展示
  final bool showZero;

  /// 只显示一个小圆点（不显示数字）
  final bool dot;

  /// 当 status 生效时的文本（相当于 Vue 的 text）
  final String? text;

  /// 徽章文本样式（数字）
  final TextStyle? countTextStyle;

  /// 鼠标悬停提示（Tooltip）
  final String? title;

  /// 是否开启涟漪（外圈放大）动画
  final bool ripple;

  /// 徽章偏移（像素）：Offset(dx, dy)，dx 向右为正，dy 向下为正
  final Offset offset;

  /// 徽章最小直径（px）
  final double badgeMinSize;

  /// 徽章与子元素的间隔（若 child 为空不生效）
  final double gap;

  const CustomBadge({
    Key? key,
    this.child,
    this.status,
    this.color,
    this.count,
    this.max = 99,
    this.showZero = false,
    this.dot = false,
    this.text,
    this.countTextStyle,
    this.title,
    this.ripple = false,
    this.offset = Offset.zero,
    this.badgeMinSize = AppSizes.font12 * 1.5,
    this.gap = AppSizes.spacing4,
  }) : super(key: key);

  @override
  State<CustomBadge> createState() => _BadgeState();
}

class _BadgeState extends State<CustomBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.ripple) {
      _rippleController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant CustomBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ripple && !_rippleController.isAnimating) {
      _rippleController.repeat();
    } else if (!widget.ripple && _rippleController.isAnimating) {
      _rippleController.stop();
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  // 从 status 或 color 中解析最终徽章颜色
  Color _resolveColor(BuildContext context) {
    if (widget.status != null) {
      switch (widget.status!) {
        case BadgeStatus.success:
          return AppColors.success;
        case BadgeStatus.processing:
          return AppColors.primary;
        case BadgeStatus.error:
          return AppColors.error;
        case BadgeStatus.warning:
          return AppColors.warning;
        case BadgeStatus.normal:
        default:
          return AppColors.textHint;
      }
    }
    return widget.color ?? AppColors.error; // 默认红色
  }

  bool get _shouldShowCount {
    if (widget.dot) return false;
    final c = widget.count ?? 0;
    if (c == 0 && !widget.showZero) return false;
    return true;
  }

  String get _displayText {
    final c = widget.count ?? 0;
    if (widget.max > 0 && c > widget.max) {
      return '${widget.max}+';
    }
    return '$c';
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _resolveColor(context);

    // 徽章 Widget（数字/点/状态点）
    Widget buildBadge() {
      // 状态点样式（带文本）
      if (widget.status != null ||
          (widget.color != null && widget.text != null)) {
        final dot = _dotWidget(badgeColor,
            size: widget.badgeMinSize * 0.6, ripple: widget.ripple);
        final text = widget.text ?? '';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot,
            if (text.isNotEmpty) SizedBox(width: AppSizes.spacing6),
            if (text.isNotEmpty)
              Text(
                text,
                style: TextStyle(
                    fontSize: AppSizes.font14,
                    color: widget.color ?? AppColors.textPrimary),
              ),
          ],
        );
      }

      // 仅小红点
      if (widget.dot) {
        return _dotWidget(badgeColor,
            size: widget.badgeMinSize * 0.6, ripple: widget.ripple);
      }

      // 数字徽章
      if (_shouldShowCount) {
        final content = _displayText;
        // 保证单/双位为圆形，多位为胶囊
        final bool singleOrDouble = content.length <= 2;
        final double height = widget.badgeMinSize;
        final double minWidth = widget.badgeMinSize;
        final double paddingH = singleOrDouble ? 0 : AppSizes.spacing6;
        final double width = singleOrDouble
            ? minWidth
            : max(minWidth, content.length * AppSizes.spacing8 + paddingH);

        return Container(
          constraints: BoxConstraints(minWidth: minWidth, minHeight: height),
          padding: EdgeInsets.symmetric(horizontal: paddingH),
          height: height,
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: [
              BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 2,
                  offset: const Offset(0, 1)),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            content,
            style: widget.countTextStyle ??
                const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: AppSizes.font10,
                    fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        );
      }

      // 默认没有徽章
      return const SizedBox.shrink();
    }

    // 将徽章包装成 AnimatedSwitcher，用于入场/退场动画
    final badgeWidget = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: (widget.status != null || widget.dot || _shouldShowCount)
          ? Transform.translate(
              offset: widget.offset,
              child: buildBadge(),
            )
          : const SizedBox.shrink(),
    );

    // 如果没有 child，则只渲染徽章（居中）
    if (widget.child == null) {
      return Semantics(
        label: widget.title ?? '',
        child: Tooltip(
          message: widget.title ?? '',
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // badge 位置微调：我们把徽章放在 center 上方偏右
                Positioned(
                  top: -6 + widget.offset.dy,
                  right: 0 + widget.offset.dx,
                  child: badgeWidget,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // child + 悬浮徽章（默认右上角）
    return Semantics(
      label: widget.title ?? '',
      child: Tooltip(
        message: widget.title ?? '',
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child!,
            // 徽章浮在 child 右上，一般会超出 child 区域
            Positioned(
              top: -AppSizes.spacing6,
              right: -AppSizes.spacing6,
              child: badgeWidget,
            ),
          ],
        ),
      ),
    );
  }

  /// 生成圆点 + 可选涟漪动画
  Widget _dotWidget(Color color, {double size = 8.0, bool ripple = false}) {
    if (!ripple) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }

    // 简单的涟漪效果：一个不断放大的半透明圆（注意：为了性能控制，使用一个 AnimationController）
    return SizedBox(
      width: size * 2.8,
      height: size * 2.8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 放大圈（透明）
          AnimatedBuilder(
            animation: _rippleController,
            builder: (context, child) {
              final t = _rippleController.value;
              final scale = 0.8 + t * 2.4; // 0.8 -> 3.2
              return Opacity(
                opacity: (1.0 - t).clamp(0.0, 0.8),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: color.withOpacity(0.9), width: 1.0),
                    ),
                  ),
                ),
              );
            },
          ),
          // 中心实心点
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

/// 状态枚举（与 Vue 版本保持一致的语义）
enum BadgeStatus { success, processing, normal, error, warning }
