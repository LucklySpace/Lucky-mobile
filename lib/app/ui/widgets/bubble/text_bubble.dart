import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 用于Clipboard
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../routes/app_routes.dart';
import '../../../models/message_receive.dart';
import '../icon/icon_font.dart';

class MessageBubble extends StatefulWidget {
  final IMessage message;
  final bool isMe;
  final String name;
  final String avatar;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.name,
    required this.avatar,
  }) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  // 管理所有 link recognizers，以便在 dispose 时释放（避免内存泄漏）
  final List<TapGestureRecognizer> _recognizers = [];

  static final _textStyle = const TextStyle(
    fontSize: AppSizes.font16,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static final _linkStyle = const TextStyle(
    fontSize: AppSizes.font16,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
  );

  // 更通用的 URL 正则（支持可选 scheme、可选 www、匹配二级及以上域名和端口与路径）
  static final RegExp _urlRegex = RegExp(
    r'((?:https?:\/\/)?(?:www\.)?[A-Za-z0-9\-._~%]+\.[A-Za-z]{2,}(?::\d{1,5})?(?:[\/?#][^\s]*)?)',
    caseSensitive: false,
  );

  @override
  void dispose() {
    // 释放所有 recognizers
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isMe;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing16, vertical: AppSizes.spacing8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) _buildAvatar(),
          const SizedBox(width: AppSizes.spacing8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildNameRow(),
                const SizedBox(height: AppSizes.spacing4),
                GestureDetector(
                  onLongPress: () {
                    _showPopupMenu(context);
                  },
                  child: Container(
                    key: _containerKey, // 添加key以便获取容器位置
                    padding: const EdgeInsets.all(AppSizes.spacing8),
                    decoration: BoxDecoration(
                      color: isMe
                          ? AppColors.primary.withOpacity(0.2)
                          : AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(AppSizes.radius16),
                        topRight: const Radius.circular(AppSizes.radius16),
                        bottomLeft: Radius.circular(
                            isMe ? AppSizes.radius16 : AppSizes.radius4),
                        bottomRight: Radius.circular(
                            isMe ? AppSizes.radius4 : AppSizes.radius16),
                      ),
                    ),
                    child: _buildMessageContent(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.spacing8),
          if (isMe) _buildAvatar(),
        ],
      ),
    );
  }

  // 添加一个GlobalKey用于获取Container的位置
  final GlobalKey _containerKey = GlobalKey();

  /// 改为底部横向菜单（每个 item：icon 在上，文字在下）
  /// 菜单宽度自适应项目数量，位置避免超出屏幕边界
  /// 调整了菜单高度以适应更小的菜单项
  void _showPopupMenu(BuildContext context) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox containerBox =
        _containerKey.currentContext!.findRenderObject() as RenderBox;
    final Offset position = containerBox.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );

    // 构建菜单项列表
    List<Widget> menuItems = [
      _buildPopupMenuItem('copy', Icons.copy, '复制'),
      _buildVerticalDivider(),
      _buildPopupMenuItem('delete', Icons.delete, '删除'),
      _buildVerticalDivider(),
      _buildPopupMenuItem('forward', Icons.forward, '转发'),
    ];

    // 如果是自己的消息，添加撤回选项
    if (widget.isMe) {
      menuItems.insert(3, _buildVerticalDivider());
      menuItems.insert(4, _buildPopupMenuItem('retract', Icons.undo, '撤回'));
    }

    // 计算菜单宽度：每个项目40px宽 + 分割线1px宽 + 项目间间距
    final double itemWidth = AppSizes.spacing40; // 从60减少到40
    final double dividerWidth = AppSizes.spacing1;
    final double menuWidth = ((menuItems.length + 1) ~/ 2) * itemWidth +
        (menuItems.length ~/ 2) * dividerWidth;

    // 确保菜单位置不会超出屏幕边界
    double leftPosition =
        position.dx + containerBox.size.width / 2 - menuWidth / 2;

    // 避免左侧超出屏幕
    if (leftPosition < AppSizes.spacing10) {
      leftPosition = AppSizes.spacing10;
    }

    // 避免右侧超出屏幕
    if (leftPosition + menuWidth > overlay.size.width - AppSizes.spacing10) {
      leftPosition = overlay.size.width - menuWidth - AppSizes.spacing10;
    }

    // 创建一个自定义的菜单界面，带有小箭头指向消息气泡
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // 透明遮罩
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pop(); // 点击任意位置关闭菜单
          },
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned(
                  left: leftPosition,
                  top: position.dy - AppSizes.spacing80, // 从100减少到80以适应更小的菜单项
                  child: CustomPaint(
                    painter: BubbleMenuPainter(),
                    child: Container(
                      width: menuWidth, // 自适应宽度
                      height: AppSizes.spacing60, // 从80减少到60以适应更小的菜单项
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radius8),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: AppSizes.radius8,
                            offset: Offset(0, AppSizes.spacing2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 2), // 为小箭头留出空间
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: menuItems,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建垂直分割线
  /// 用于分隔不同的菜单项，提高视觉清晰度
  /// 调整了高度以适应更小的菜单项
  Widget _buildVerticalDivider() {
    return Container(
      width: AppSizes.spacing1,
      height: AppSizes.spacing20, // 从30减少到20以适应更小的菜单项
      color: AppColors.divider,
    );
  }

  /// 构建自定义样式的菜单项
  /// 包含图标和文字标签，采用垂直布局（图标在上，文字在下）
  /// 调整了尺寸使其更紧凑
  Widget _buildPopupMenuItem(String value, IconData icon, String text) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(); // 关闭菜单
        // 延迟执行操作，确保菜单已关闭
        Future.delayed(const Duration(milliseconds: 100), () {
          switch (value) {
            case 'copy':
              _copyMessage();
              break;
            case 'delete':
              _deleteMessage();
              break;
            case 'retract':
              _retractMessage();
              break;
            case 'forward':
              _forwardMessage();
              break;
          }
        });
      },
      child: Container(
        width: AppSizes.spacing40, // 从60减少到40
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppSizes.iconSmall, color: AppColors.primary),
            // 图标从20减少到16
            const SizedBox(height: AppSizes.spacing2),
            // 间距从3减少到2
            Text(
              text,
              style: const TextStyle(
                fontSize: AppSizes.font10, // 字体从12减少到10
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyMessage() {
    final text =
        TextMessageBody.fromMessageBody(widget.message.messageBody)?.text ?? '';
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      Get.snackbar('提示', '消息已复制到剪贴板');
    }
  }

  void _deleteMessage() {
    // 实际项目中需要调用删除消息的API或方法
    Get.snackbar('提示', '消息已删除');
  }

  void _retractMessage() {
    // 实际项目中需要调用撤回消息的API或方法
    Get.snackbar('提示', '消息已撤回');
  }

  void _forwardMessage() {
    // 实际项目中需要跳转到转发页面
    Get.snackbar('提示', '转发功能');
  }

  Widget _buildNameRow() {
    final nameStyle = TextStyle(
      fontSize: AppSizes.font12,
      color: widget.isMe ? AppColors.textSecondary : AppColors.textHint,
      fontWeight: FontWeight.w500,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.isMe) ...[
          Text(widget.name, style: nameStyle),
          const SizedBox(width: AppSizes.spacing8),
        ],
        if (widget.isMe) ...[
          const SizedBox(width: AppSizes.spacing8),
          Text(widget.name, style: nameStyle),
        ],
      ],
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    final text =
        TextMessageBody.fromMessageBody(widget.message.messageBody)?.text ?? '';

    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    // 优先使用快速判断（性能优化）
    if (!containsUrl(text)) {
      return Text(text, style: _textStyle);
    }

    // 否则拆分并构造 RichText spans
    final spans = _parseTextToSpans(text);
    return RichText(
      text: TextSpan(children: spans, style: _textStyle),
    );
  }

  /// -------------------------
  /// URL 相关独立方法（入口/工具）
  /// -------------------------

  /// 快速判断文本中是否含有 URL（基于正则）
  static bool containsUrl(String text) {
    if (text.isEmpty) return false;
    return _urlRegex.hasMatch(text);
  }

  /// 提取文本中所有可能的 URL（未归一化）
  static List<String> extractUrls(String text) {
    final List<String> urls = [];
    if (text.isEmpty) return urls;

    final matches = _urlRegex.allMatches(text);
    for (final match in matches) {
      var raw = match.group(0) ?? '';
      if (raw.isEmpty) continue;

      // 清理前导和尾随常见符号，例如括号、句号、逗号、分号、冒号、感叹号、问号
      raw = _trimEnclosingPunctuation(raw);

      if (raw.isNotEmpty) {
        urls.add(raw);
      }
    }
    return urls;
  }

  /// 归一化 URL：若缺少 scheme，则自动补 https://
  static String normalizeUrl(String url) {
    if (url.isEmpty) return url;
    final trimmed = url.trim();

    // 如果已有 scheme
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      return trimmed;
    }

    // 否则补 https://
    return 'https://$trimmed';
  }

  /// 辅助：去掉前后的包裹符与尾部常见句末标点
  static String _trimEnclosingPunctuation(String s) {
    var t = s.trim();

    // 去掉前导左括号或引号
    while (t.isNotEmpty &&
        (t.codeUnitAt(0) == '('.codeUnitAt(0) ||
            t.codeUnitAt(0) == '"'.codeUnitAt(0) ||
            t.codeUnitAt(0) == '\''.codeUnitAt(0))) {
      t = t.substring(1).trim();
    }

    // 去掉尾部常见的标点 ) . , ; : ! ? " '
    while (t.isNotEmpty && _isTrailingPunctuation(t.codeUnitAt(t.length - 1))) {
      t = t.substring(0, t.length - 1).trim();
    }

    return t;
  }

  static bool _isTrailingPunctuation(int codeUnit) {
    const trailing = [
      41, // )
      46, // .
      44, // ,
      59, // ;
      58, // :
      33, // !
      63, // ?
      34, // "
      39, // '
    ];
    return trailing.contains(codeUnit);
  }

  /// -------------------------
  /// 文本 -> InlineSpan 解析
  /// -------------------------
  List<InlineSpan> _parseTextToSpans(String text) {
    // 释放旧 recognizers（如果有）并清空
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final List<InlineSpan> spans = [];

    // 使用正则匹配到所有 URL，循环拼接文本片段
    final matches = _urlRegex.allMatches(text).toList();
    if (matches.isEmpty) {
      // 防护：若正则没匹配到，直接返回整段文本
      spans.add(TextSpan(text: text));
      return spans;
    }

    int lastEnd = 0;
    for (final match in matches) {
      final start = match.start;
      final end = match.end;

      // 前半段普通文本
      if (start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, start)));
      }

      // raw url 可能包含末尾标点或前导括号，清理后再使用
      var rawUrl = match.group(0) ?? '';
      final cleaned = _trimEnclosingPunctuation(rawUrl);

      // 基本校验：Uri.tryParse 且含点（确保不是孤立的单词）
      final candidate = cleaned;
      final uri = Uri.tryParse(candidate);
      final hasDot = candidate.contains('.');
      final isValid =
          candidate.isNotEmpty && uri != null && (uri.hasScheme || hasDot);

      if (isValid) {
        // 点击打开：先 normalize，再跳转到 WebView 页面（你也可以直接 launch 外部浏览器）
        final recognizer = TapGestureRecognizer()
          ..onTap = () {
            final link = normalizeUrl(candidate);
            // 使用 Get 跳转到 WebView 页面，传入归一化链接
            Get.toNamed(Routes.WEB_VIEW, arguments: {'url': link});
          };
        _recognizers.add(recognizer);

        spans.add(TextSpan(
            text: candidate, style: _linkStyle, recognizer: recognizer));
      } else {
        // 非合法 URL，作为普通文本渲染
        spans.add(TextSpan(text: rawUrl));
      }

      lastEnd = end;
    }

    // 尾部普通文本
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return spans;
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: () {
        if (!widget.isMe) {
          Get.toNamed("${Routes.HOME}${Routes.FRIEND_PROFILE}",
              arguments: {'userId': widget.message.fromId});
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radius8),
        child: CachedNetworkImage(
          imageUrl: widget.avatar,
          width: AppSizes.spacing40,
          height: AppSizes.spacing40,
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
}

/// 内部：表示底部菜单的一个 action
class _PopupAction {
  final String key;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  _PopupAction({
    required this.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });
}

/// 自定义绘制类，用于绘制带小箭头的菜单背景
/// 箭头位置会根据菜单宽度自动居中
/// 调整了箭头大小以适应更小的菜单
class BubbleMenuPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;

    final path = Path();

    // 绘制气泡菜单主体（圆角矩形）
    final rect = Rect.fromLTWH(
        0, 0, size.width, size.height - AppSizes.spacing6); // 从8减少到6
    final rrect =
        RRect.fromRectAndRadius(rect, const Radius.circular(AppSizes.radius10));
    path.addRRect(rrect);

    // 绘制小箭头（指向消息气泡），位置根据菜单宽度自动居中
    // 调整了箭头大小以适应更小的菜单
    final arrowPath = Path();
    final centerX = size.width / 2;
    arrowPath.moveTo(
        centerX - AppSizes.spacing6, size.height - AppSizes.spacing6); // 从8减少到6
    arrowPath.lineTo(centerX, size.height);
    arrowPath.lineTo(
        centerX + AppSizes.spacing6, size.height - AppSizes.spacing6); // 从8减少到6
    arrowPath.lineTo(
        centerX - AppSizes.spacing6, size.height - AppSizes.spacing6); // 从8减少到6
    path.addPath(arrowPath, const Offset(0, 0));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
