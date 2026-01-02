import 'package:flutter/material.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';

/// 自定义 Iconfont 图标组件，封装基于自定义字体文件的图标
/// 特性：
/// - 提供静态 [IconData] 属性，基于自定义字体文件（如 iconfont.ttf）。
/// - 支持主题化配置（如大小、颜色）。
/// - 易于扩展，可添加新的图标代码点。
class Iconfont {
  // 常量定义：字体家族名称
  static const String _fontFamily = 'Iconfont';

  // 图标代码点（从 iconfont 平台获取）
  static const IconData message = IconData(0xe650, fontFamily: _fontFamily);
  static const IconData person = IconData(0xe602, fontFamily: _fontFamily);
  static const IconData videoCall = IconData(0xe603, fontFamily: _fontFamily);
  static const IconData addFriend = IconData(0xe604, fontFamily: _fontFamily);
  static const IconData location = IconData(0xe605, fontFamily: _fontFamily);
  static const IconData download = IconData(0xe65c, fontFamily: _fontFamily);
  static const IconData my = IconData(0xe60a, fontFamily: _fontFamily);
  static const IconData add = IconData(0xe608, fontFamily: _fontFamily);
  static const IconData scan = IconData(0xe749, fontFamily: _fontFamily);
  static const IconData search = IconData(0xe699, fontFamily: _fontFamily);
  static const IconData setting = IconData(0xe60c, fontFamily: _fontFamily);
  static const IconData contacts = IconData(0xe607, fontFamily: _fontFamily);

  // 获取文件图标
  static const Map<String, String> _fileIconMap = {
    'md': '#icon-Markdown',
    '7z': '#icon-file_rar',
    'rar': '#icon-file_rar',
    'zip': '#icon-file_rar',
    'pdf': '#icon-file-b-3',
    'doc': '#icon-file-b-5',
    'docx': '#icon-file-b-5',
    'xls': '#icon-file-b-9',
    'xlsx': '#icon-file-b-9',
    'ppt': '#icon-file-b-4',
    'pptx': '#icon-file-b-4',
    'txt': '#icon-file-b-2',
  };

  /// 根据图标名称获取 IconData
  /// 如果找不到对应图标，则返回默认图标
  static IconData fromName(String name, {IconData? defaultValue}) {
    // 解析 iconfont.json 文件中的数据，获取对应名称的图标
    // 这里我们使用一个映射来简化实现
    const Map<String, int> iconNameToCodePoint = {
      'Markdown': 0xe6db,
      'file_rar': 0xe72b,
      'file-b-3': 0xe656,
      'file-b-5': 0xe658,
      'file-b-9': 0xe660,
      'file-b-4': 0xe652,
      'file-b-2': 0xe654,
    };

    // 处理带有前缀的名称
    String iconName = name;
    if (name.startsWith('#icon-')) {
      iconName = name.substring(6); // 移除 '#icon-' 前缀
    }

    int? codePoint = iconNameToCodePoint[iconName];
    if (codePoint != null) {
      return IconData(codePoint, fontFamily: _fontFamily);
    }

    // 如果提供了默认值，则返回默认值
    if (defaultValue != null) {
      return defaultValue;
    }

    // 否则返回一个默认图标
    return IconData(0xe72b, fontFamily: _fontFamily); // 默认使用压缩文件图标
  }

  /// 根据文件扩展名获取对应的图标
  /// 如果找不到对应扩展名的图标，则返回默认图标
  static IconData fromFileExtension(String extension) {
    String? iconKey = _fileIconMap[extension.toLowerCase()];
    if (iconKey != null) {
      return fromName(iconKey);
    }

    // 返回默认图标
    return fromName('file_rar');
  }

  /// 构建自定义图标 Widget
  /// 参数：
  /// - [icon]：图标的 [IconData]，如 [Iconfont.message]。
  /// - [size]：图标大小，默认 24.0。
  /// - [color]：图标颜色，默认为主题的 [onSurface] 颜色。
  static Widget buildIcon({
    required IconData icon,
    double size = AppSizes.iconMedium,
    Color? color,
  }) {
    return Icon(icon, size: size, color: color ?? AppColors.textPrimary);
  }

  /// 将图标代码点转换为 [IconData]
  /// 参数：
  /// - [codePoint]：图标的 Unicode 代码点（如 0xe601）。
  /// - [fontFamily]：字体家族名称，默认为 [_fontFamily]。
  static IconData fromCodePoint(int codePoint,
      {String fontFamily = _fontFamily}) {
    return IconData(codePoint, fontFamily: fontFamily);
  }
}
