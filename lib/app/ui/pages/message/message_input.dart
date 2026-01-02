import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../constants/app_message.dart';
import '../../../controller/chat_controller.dart';
import '../../widgets/emoji/emoji_picker.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController textController; // 外部传入的文本控制器
  final ChatController controller; // 聊天控制器

  const MessageInput({
    super.key,
    required this.textController,
    required this.controller,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  // --- 常量 ---
  static const _inputHeight = AppSizes.spacing36;
  static const _inputBorderRadius = AppSizes.radius6;
  static const _emojiPickerHeight = 250.0;
  static const _buttonWidth = AppSizes.spacing36;
  static const _sendButtonWidth = 74.0;
  static const _iconSize = AppSizes.iconLarge;
  static const _hintText = '输入消息...';
  static const _mentionTrigger = '@';
  static const _animationDuration = Duration(milliseconds: 200);

  // --- 状态 ---
  bool _showEmojiPicker = false;
  bool _hasText = false;
  bool _isReadOnly = false; // 当为 true 时：输入框可聚焦但不会唤起系统键盘

  // --- 控制器 / 焦点 ---
  late final TextEditingController _richTextController;
  final FocusNode _focusNode = FocusNode();
  TextSelection? _lastSelection; // 记录切换时的光标位置，便于恢复

  @override
  void initState() {
    super.initState();

    // 使用外部传入的 controller（不在这里 dispose）
    _richTextController = widget.textController;
    _richTextController.addListener(_onTextChanged);
    _richTextController.addListener(_checkForMentionTrigger);

    // 处理键盘 Backspace（删除 @username 的整段）
    _focusNode.onKeyEvent = _handleKeyEvent;

    // 焦点监听：如果焦点获得而表情面板处于打开状态（我们想要隐藏系统键盘），则确保键盘隐藏
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmojiPicker) {
        // 保持输入框聚焦，但隐藏系统键盘
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });
  }

  @override
  void dispose() {
    _richTextController.removeListener(_onTextChanged);
    _richTextController.removeListener(_checkForMentionTrigger);
    _focusNode.dispose();
    super.dispose();
  }

  // --- 文本监听 ---
  void _onTextChanged() {
    final hasText = _richTextController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  // --- mention 触发检测 ---
  void _checkForMentionTrigger() {
    final text = _richTextController.text;
    final selection = _richTextController.selection;

    // 只有在光标位于末尾并刚刚输入 '@' 且前面为空格或开头，且当前会话是群聊时触发
    if (selection.baseOffset > 0 &&
        selection.baseOffset == text.length &&
        text.endsWith(_mentionTrigger) &&
        (text.length == 1 || text[text.length - 2] == ' ')) {
      if (widget.controller.currentChat.value?.chatType ==
          IMessageType.groupMessage.code) {
        _showMentionDrawer();
      }
    }
  }

  void _insertMention(String username) {
    final text = _richTextController.text;
    final selection = _richTextController.selection;

    if (username.isEmpty) {
      Get.snackbar('提示', '用户名不能为空');
      return;
    }

    final mentionPattern = '@$username\\b';
    if (RegExp(mentionPattern).hasMatch(text)) {
      Get.snackbar(
        '提示',
        '已经@过该用户',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.grey[800],
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // 将刚输入的 '@' 替换为 '@username ' 并把光标放到 username 之后
    final newText = text.substring(0, selection.baseOffset - 1) +
        '@$username ' +
        text.substring(selection.baseOffset);
    final newCursorPosition = selection.baseOffset - 1 + username.length + 2;

    _richTextController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
    Navigator.pop(context);
  }

  // --- emoji 插入与删除 ---
  void _insertEmoji(String emoji) {
    String text = _richTextController.text;
    TextSelection sel = _richTextController.selection;

    // 如果当前 selection 无效，使用保留的 lastSelection 或追加到末尾
    if (!sel.isValid) {
      sel = _lastSelection ?? TextSelection.collapsed(offset: text.length);
    }

    final start = sel.baseOffset.clamp(0, text.length);
    final newText = text.substring(0, start) + emoji + text.substring(start);
    final newCursorPosition = start + emoji.length;

    _richTextController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );

    // 确保表情面板仍然显示，且系统键盘保持隐藏
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      // 将焦点保持在输入框，这样会看到光标（但是 keyboard 被隐藏）
      FocusScope.of(context).requestFocus(_focusNode);
      _lastSelection = _richTextController.selection;
    });
  }

  // Emoji 面板上的删除按钮（利用 characters 更稳健地删除 emoji/grapheme）
  void _deleteLastGrapheme() {
    final text = _richTextController.text;
    if (text.isEmpty) return;

    // 使用 characters 包的 API 更稳妥（如果项目未引入 characters，请继续使用字符串操作）
    try {
      final chars = text.characters;
      final shortened = chars.take(chars.length - 1).toString();
      _richTextController.text = shortened;
      _richTextController.selection =
          TextSelection.collapsed(offset: _richTextController.text.length);
    } catch (_) {
      // 回退到最简单的做法
      _richTextController.text =
          text.substring(0, text.length - 1).substring(0, text.length - 1);
      _richTextController.selection =
          TextSelection.collapsed(offset: _richTextController.text.length);
    }
  }

  // --- 退格特殊处理（按键事件） ---
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      return _handleBackspace()
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  bool _handleBackspace() {
    final text = _richTextController.text;
    final selection = _richTextController.selection;

    if (!selection.isValid ||
        !selection.isCollapsed ||
        selection.baseOffset <= 0) {
      return false;
    }

    final textBeforeCursor = text.substring(0, selection.baseOffset);
    // 匹配以空格或行首开头，最后是 @xxx 并可能以空格结尾
    final match = RegExp(r'(^|\s)@\S+\s*$').firstMatch(textBeforeCursor);

    if (match != null) {
      final newText = text.replaceRange(match.start, selection.baseOffset, '');
      _richTextController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: match.start),
      );
      return true;
    }
    return false;
  }

  // --- 表情面板切换逻辑（关键改动） ---
  /// 切换表情面板显示：
  /// - 打开面板：设置 readOnly=true、记录 selection、给输入框请求焦点（显示光标）但隐藏系统键盘
  /// - 关闭面板：设置 readOnly=false、恢复 selection、请求焦点并唤起系统键盘
  void _toggleEmojiPicker() {
    if (!_showEmojiPicker) {
      // 打开表情面板：记录当前 selection 并将输入框设为 readOnly（这样 requestFocus 不会弹出键盘）
      _lastSelection = _richTextController.selection;
      setState(() {
        _showEmojiPicker = true;
        _isReadOnly = true;
      });

      // 请求焦点以显示光标，但同时隐藏系统键盘以保证不会弹起
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_focusNode);
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      });
    } else {
      // 关闭表情面板：允许输入（readOnly=false），恢复 selection 并唤起键盘
      setState(() {
        _showEmojiPicker = false;
        _isReadOnly = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_focusNode);
        // 恢复 selection（如果存在）
        _richTextController.selection = _lastSelection ??
            TextSelection.collapsed(offset: _richTextController.text.length);
        SystemChannels.textInput.invokeMethod('TextInput.show');
      });
    }
  }

  /// 点击输入框的行为：
  /// - 如果当前表情面板打开，按你的实际需求我们把它关闭并唤起键盘（这是常见 UX）
  /// - 否则正常获取焦点并唤起键盘
  void _onInputTap() {
    if (_showEmojiPicker) {
      setState(() {
        _showEmojiPicker = false;
        _isReadOnly = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_focusNode);
        _richTextController.selection = _lastSelection ??
            TextSelection.collapsed(offset: _richTextController.text.length);
        SystemChannels.textInput.invokeMethod('TextInput.show');
      });
    } else {
      FocusScope.of(context).requestFocus(_focusNode);
      SystemChannels.textInput.invokeMethod('TextInput.show');
    }
  }

  // --- mention 列表底部弹窗 ---
  void _showMentionDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radius16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(AppSizes.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '选择要@的用户',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSizes.spacing16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: 20, // TODO: 替换为实际用户列表
                  itemBuilder: (context, index) {
                    final username = '用户 $index';
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(username),
                      onTap: () => _insertMention(username),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI 构建函数 ---
  Widget _buildInputField() {
    return Container(
      height: _inputHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(_inputBorderRadius),
        border:
            Border.all(color: AppColors.border, width: AppSizes.spacing1),
      ),
      child: TextField(
        controller: _richTextController,
        focusNode: _focusNode,
        readOnly: _isReadOnly,
        // 关键：true 时不会唤起系统键盘，但仍可聚焦显示光标
        showCursor: true,
        onTap: _onInputTap,
        enableInteractiveSelection: true,
        decoration: InputDecoration(
          hintText: _hintText,
          hintStyle: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textHint),
          border: InputBorder.none,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: AppSizes.spacing16, vertical: AppSizes.spacing8),
        ),
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: AppColors.textSecondary),
        maxLines: 1,
        textAlignVertical: TextAlignVertical.center,
      ),
    );
  }

  Widget _buildButtons() {
    return AnimatedSwitcher(
      duration: _animationDuration,
      transitionBuilder: (child, animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: _hasText
          ? SizedBox(
              key: const ValueKey('send'),
              width: _sendButtonWidth,
              height: _inputHeight,
              child: TextButton(
                onPressed: () {
                  final text = _richTextController.text.trim();
                  if (text.isNotEmpty) {
                    widget.controller.sendMessage(text);
                    _richTextController.clear();
                    // 保持焦点以便继续输入，不隐藏键盘
                    FocusScope.of(context).requestFocus(_focusNode);
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_inputBorderRadius),
                  ),
                ),
                child: Text(
                  '发送',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: AppColors.white),
                ),
              ),
            )
          : Row(
              key: const ValueKey('icons'),
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: _buttonWidth,
                  child: IconButton(
                    onPressed: _toggleEmojiPicker,
                    icon: Icon(
                      Icons.emoji_emotions_outlined,
                      color: AppColors.textSecondary,
                      size: _iconSize,
                    ),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: AppSizes.spacing32, minHeight: AppSizes.spacing36),
                  ),
                ),
                const SizedBox(width: AppSizes.spacing2),
                SizedBox(
                  width: _buttonWidth,
                  child: IconButton(
                    onPressed: () {
                      Get.snackbar('提示', '加号功能待实现');
                    },
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: AppColors.textSecondary,
                      size: _iconSize,
                    ),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: AppSizes.spacing32, minHeight: AppSizes.spacing36),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: _emojiPickerHeight,
      child: EmojiPicker(
        onEmojiSelected: (emoji) {
          _insertEmoji(emoji);
          // 保持面板打开且输入框处于 readOnly（这会让光标可见但不弹键盘）
          setState(() {
            _showEmojiPicker = true;
            _isReadOnly = true;
          });
        },
        onDelete: () {
          _deleteLastGrapheme();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16, vertical: AppSizes.spacing4),
          color: AppColors.surface,
          child: Row(
            children: [
              Expanded(child: _buildInputField()),
              const SizedBox(width: AppSizes.spacing8),
              _buildButtons(),
            ],
          ),
        ),
        if (_showEmojiPicker) _buildEmojiPicker(),
      ],
    );
  }
}
