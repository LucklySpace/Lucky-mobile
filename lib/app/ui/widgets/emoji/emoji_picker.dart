import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

import '../../../../config/app_config.dart';
import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../utils/file.dart';
import '../../../models/expression_pack.dart';

/// EmojiPicker 组件，用于展示和管理表情选择器
/// 特性：
/// - 使用 [DefaultTabController] 动态管理表情包 Tab。
/// - 第一个 Tab 显示“最近使用”表情区域，其余 Tab 显示对应表情包内容。
/// - 支持 emoji 和图片表情，带删除按钮和渐变背景。
class EmojiPicker extends StatefulWidget {
  final ValueChanged<String> onEmojiSelected; // 表情选中回调
  final VoidCallback onDelete; // 删除按钮回调

  const EmojiPicker({
    super.key,
    required this.onEmojiSelected,
    required this.onDelete,
  });

  @override
  State<EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<EmojiPicker> {
  // 常量定义
  static const _recentKey = 'recent_emojis'; // 最近使用表情存储键
  static const _maxRecentEmojis = 8; // 最近使用表情最大数量
  static const _emojiColumns = 8; // Emoji 网格每行数量
  static const _imageColumns = 4; // 图片网格每行数量
  static const _gridPadding = EdgeInsets.all(AppSizes.spacing8); // 网格内边距
  static const _tabBarHeight = AppSizes.spacing36; // TabBar 高度
  static const _deleteButtonSize = 80.0; // 删除按钮区域大小
  static const _iconSize = AppSizes.iconMedium; // 删除按钮图标大小
  static const _sectionHeaderFontSize = AppSizes.font12; // 部分标题字体大小

  // 数据存储
  final _storage = GetStorage();
  final _expressionPacks = <ExpressionPack>[]; // 表情包列表
  var _recentEmojis = <Expression>[]; // 最近使用表情列表

  @override
  void initState() {
    super.initState();

    /// 初始化表情数据
    _initializeData();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _expressionPacks.isEmpty ? 1 : _expressionPacks.length,
      child: Stack(
        children: [
          /// 主内容：TabBar 和 TabBarView
          Column(
            children: [
              _buildTabBar(),
              Expanded(child: _buildTabBarView()),
            ],
          ),

          /// 删除按钮
          _buildDeleteButton(),
        ],
      ),
    );
  }

  // --- UI 构建方法 ---

  /// 构建 TabBar
  Widget _buildTabBar() {
    return SizedBox(
      height: _tabBarHeight,
      child: TabBar(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorWeight: 2,
        labelPadding: EdgeInsets.zero,
        tabs: _expressionPacks.isEmpty
            ? [
                const Tab(
                    child: Icon(Icons.emoji_emotions, size: AppSizes.font18))
              ]
            : List.generate(
                _expressionPacks.length, (index) => _buildTab(index)),
      ),
    );
  }

  /// 构建 TabBarView
  Widget _buildTabBarView() {
    if (_expressionPacks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.spacing16),
          child: Text('正在加载表情...'),
        ),
      );
    }
    return TabBarView(
      children: List.generate(
        _expressionPacks.length,
        (index) => _buildTabView(index),
      ),
    );
  }

  /// 构建删除按钮
  Widget _buildDeleteButton() {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        width: _deleteButtonSize,
        height: _deleteButtonSize,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.7, 0.7),
            radius: 1.2,
            colors: [
              AppColors.surface.withOpacity(0.9),
              AppColors.surface.withOpacity(0.0)
            ],
          ),
        ),
        child: Align(
          alignment: const Alignment(0.7, 0.7),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onDelete,
              borderRadius: BorderRadius.circular(AppSizes.radius24),
              child: Container(
                padding: const EdgeInsets.all(AppSizes.spacing8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.radius24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.backspace_rounded,
                  color: AppColors.textWhite,
                  size: _iconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建单个 Tab
  Widget _buildTab(int index) {
    final pack = _expressionPacks[index];
    if (pack.type == ExpressionType.emoji) {
      final emoji = pack.expressions.isNotEmpty
          ? pack.expressions.first.unicode ?? '😀'
          : '😀';
      return Tab(
          child: Text(emoji, style: const TextStyle(fontSize: AppSizes.font18)));
    }
    final imagePath =
        pack.expressions.isNotEmpty ? pack.expressions.first.imageURL : null;
    return Tab(
      child: imagePath != null
          ? SizedBox(
              width: AppSizes.spacing24,
              height: AppSizes.spacing24,
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  _logError('加载图片表情失败: $error, 路径: $imagePath');
                  return const Icon(Icons.error_outline,
                      color: AppColors.textSecondary, size: AppSizes.font24);
                },
              ),
            )
          : const Icon(Icons.image, size: AppSizes.font18),
    );
  }

  /// 构建 Tab 页面
  Widget _buildTabView(int index) {
    final pack = _expressionPacks[index];
    final grid = pack.type == ExpressionType.emoji
        ? _buildEmojiGrid(pack.expressions, _emojiColumns)
        : _buildImageGrid(pack.expressions, _imageColumns);
    return index == 0
        ? ListView(
            children: [
              _buildSectionHeader('最近使用'),
              _buildRecentEmojis(),
              _buildSectionHeader('全部表情'),
              grid,
            ],
          )
        : ListView(children: [grid]);
  }

  /// 构建部分标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: _sectionHeaderFontSize,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  /// 构建最近使用表情区域
  Widget _buildRecentEmojis() {
    return _recentEmojis.isEmpty
        ? const SizedBox(
            height: 80,
            child: Center(child: Text('暂无最近使用的表情')),
          )
        : _buildEmojiGrid(_recentEmojis, _emojiColumns);
  }

  /// 构建 Emoji 网格
  Widget _buildEmojiGrid(List<Expression> emojis, int crossAxisCount) {
    return GridView.builder(
      padding: _gridPadding,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: emojis.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) => _buildEmojiItem(emojis[index]),
    );
  }

  /// 构建图片网格
  Widget _buildImageGrid(List<Expression> images, int crossAxisCount) {
    return GridView.builder(
      padding: _gridPadding,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) => _buildImageItem(images[index]),
    );
  }

  /// 构建单个 Emoji 表情项
  Widget _buildEmojiItem(Expression expression) {
    if (expression.unicode == null || expression.unicode!.isEmpty) {
      _logError('无效的 Emoji 数据: ${expression.id}');
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () => _onEmojiTap(expression, ExpressionType.emoji),
      behavior: HitTestBehavior.opaque,
      child: Center(
          child:
              Text(expression.unicode!, style: const TextStyle(fontSize: AppSizes.font24))),
    );
  }

  /// 构建单个图片表情项
  Widget _buildImageItem(Expression expression) {
    if (expression.imageURL == null || expression.imageURL!.isEmpty) {
      _logError('无效的图片表情数据: ${expression.id}');
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () => _onEmojiTap(expression, ExpressionType.image),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spacing4),
        child: Image.file(
          File(expression.imageURL!),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            _logError('加载图片表情失败: $error, 路径: ${expression.imageURL}');
            return const Icon(Icons.error_outline,
                color: AppColors.textHint, size: AppSizes.iconMedium);
          },
        ),
      ),
    );
  }

  // --- 数据处理方法 ---

  /// 初始化数据：加载表情包和最近使用表情
  Future<void> _initializeData() async {
    await Future.wait([
      _loadRecentEmojis(),
      _loadExpressionPacks(),
      _loadLocalExpressionPacks(),
    ]);
    setState(() {}); // 更新 UI
  }

  /// 加载网络或资源中的表情包
  Future<void> _loadExpressionPacks() async {
    try {
      final jsonString = await rootBundle.loadString(AppConfig.emojiPath);
      final jsonData = jsonDecode(jsonString);
      setState(() {
        _expressionPacks.add(ExpressionPack.fromJson(jsonData));
      });
      _logInfo('加载表情包数量: ${_expressionPacks.length}');
    } catch (e, stackTrace) {
      _logError('加载表情包失败: $e\n堆栈: $stackTrace');
    }
  }

  /// 加载本地图片表情包
  Future<void> _loadLocalExpressionPacks() async {
    try {
      final files = await FileUtils.scanFilesWithExtension(
          AppConfig.pickerPath, ['json']);
      for (var file in files) {
        final jsonString = await File(file.filePath).readAsString();
        final jsonData = jsonDecode(jsonString);
        final expressionPack = ExpressionPack.fromJson(jsonData);
        if (expressionPack.type == ExpressionType.image) {
          for (var expression in expressionPack.expressions) {
            expression.imageURL = '${file.dirPath}/${expression.imageURL!}';
          }
        }
        setState(() {
          _expressionPacks.add(expressionPack);
        });
      }
      _logInfo('加载本地表情包: ${files.length} 个');
    } catch (e) {
      _logError('加载本地表情包失败: $e');
    }
  }

  /// 加载最近使用表情
  Future<void> _loadRecentEmojis() async {
    try {
      final storedEmojis = _storage.read<List>(_recentKey);
      if (storedEmojis != null) {
        setState(() {
          _recentEmojis.addAll(
            storedEmojis
                .map((e) => Expression.fromJson(e))
                .where((e) => e.unicode != null && e.unicode!.isNotEmpty),
          );
        });
      }
    } catch (e) {
      _logError('加载最近使用表情失败: $e');
      setState(() => _recentEmojis.clear());
    }
  }

  /// 保存最近使用表情
  Future<void> _saveRecentEmojis() async {
    try {
      await _storage.write(
          _recentKey, _recentEmojis.map((e) => e.toJson()).toList());
    } catch (e) {
      _logError('保存最近使用表情失败: $e');
    }
  }

  /// 处理表情点击事件
  void _onEmojiTap(Expression expression, ExpressionType type) {
    setState(() {
      _recentEmojis.remove(expression);
      _recentEmojis.insert(0, expression);
      if (_recentEmojis.length > _maxRecentEmojis) {
        _recentEmojis = _recentEmojis.sublist(0, _maxRecentEmojis);
      }
    });
    _saveRecentEmojis();
    final value = type == ExpressionType.emoji
        ? expression.unicode ?? ''
        : expression.imageURL ?? '';
    widget.onEmojiSelected(value);
  }

  // --- 辅助方法 ---

  /// 记录信息日志
  void _logInfo(String message) => debugPrint(message);

  /// 记录错误日志
  void _logError(String message) => debugPrint('❌ $message');
}
