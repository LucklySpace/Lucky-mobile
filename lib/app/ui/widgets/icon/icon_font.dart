import 'package:flutter/material.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';

/// 自定义 Iconfont 图标组件，封装基于自定义字体文件的图标
///
/// 特性：
/// - 提供静态 [IconData] 属性，基于自定义字体文件（如 iconfont.ttf）
/// - 支持主题化配置（如大小、颜色）
/// - 易于扩展，可添加新的图标代码点
/// - 支持通过名称、代码点、文件扩展名获取图标
///
/// 使用示例：
/// ```dart
/// // 方式一：直接使用静态属性（推荐）
/// Icon(Iconfont.message)
///
/// // 方式二：通过名称获取
/// Icon(Iconfont.fromName('Markdown'))
///
/// // 方式三：通过代码点获取
/// Icon(Iconfont.fromCodePoint(0xe601))
///
/// // 方式四：通过文件扩展名获取
/// Icon(Iconfont.fromFileExtension('pdf'))
/// ```
class Iconfont {
  // ==================== 常量定义 ====================

  /// 字体家族名称（必须与 pubspec.yaml 中配置的字体名称一致）
  static const String _fontFamily = 'Iconfont';

  // ==================== 常用图标（快捷访问） ====================
  // 保留原有的图标定义，确保向后兼容

  /// 消息图标 - 发起会话
  static const IconData message = IconData(0xe650, fontFamily: _fontFamily);

  /// 个人/我的图标
  static const IconData person = IconData(0xe602, fontFamily: _fontFamily);

  /// 视频通话 - 右旋转
  static const IconData videoCall = IconData(0xe603, fontFamily: _fontFamily);

  /// 添加好友 - 男性
  static const IconData addFriend = IconData(0xe604, fontFamily: _fontFamily);

  /// 设置/位置图标
  static const IconData location = IconData(0xe605, fontFamily: _fontFamily);

  /// 下载图标
  static const IconData download = IconData(0xe65c, fontFamily: _fontFamily);

  /// 我的图标
  static const IconData my = IconData(0xe60a, fontFamily: _fontFamily);

  /// 添加/加号图标
  static const IconData add = IconData(0xe608, fontFamily: _fontFamily);

  /// 扫码图标
  static const IconData scan = IconData(0xe749, fontFamily: _fontFamily);

  /// 搜索图标
  static const IconData search = IconData(0xe699, fontFamily: _fontFamily);

  /// 设置图标
  static const IconData setting = IconData(0xe60c, fontFamily: _fontFamily);

  /// 联系人图标
  static const IconData contacts = IconData(0xe607, fontFamily: _fontFamily);

  // ==================== 完整图标映射表 ====================
  // 从 iconfont.json 中提取的所有图标定义
  // 键为 font_class，值为 Unicode 代码点

  static const Map<String, int> _iconNameToCodePoint = {
    // ==================== 文本与编辑 ====================
    'wenben1': 0xe628, // 文本
    '24': 0xe6af, // 工具,写,编辑,钢笔,铅笔
    'chexiao': 0xe659, // 撤销
    'chehui': 0xe65a, // 撤回

    // ==================== 扫码与屏幕 ====================
    'saoma': 0xe749, // 扫码
    'luping': 0xe631, // 录屏
    'jietu': 0xe60e, // 截图
    'jietu1': 0xe61f, // 截图
    'jietu2': 0xe64f, // 截图
    'jietu3': 0xe70e, // 截图
    'winfo-icon-jietu': 0xe65d, // 截图

    // ==================== 音频与视频 ====================
    'jingyin': 0xe663, // 静音
    'mti-guanbijingyin': 0xe9d2, // 关闭静音
    'shipin1': 0xe85f, // 视频
    'shipin-': 0xe62d, // 视频
    'shipin': 0xe662, // 视频
    'bofang': 0xe630, // 播放
    'bofang1': 0xe737, // 播放
    'maikefeng': 0xe65f, // 麦克风
    'shexiangtou_shiti': 0xeca5, // 摄像头实体
    'yangshengqi': 0xe61e, // 扬声器
    'yuyin_o': 0xeb6c, // 语音

    // ==================== 聊天与消息 ====================
    'liaotian': 0xe625, // 聊天
    'liaotianjilu': 0xe619, // 聊天记录
    'xiaoxi': 0xe638, // 消息
    'xiaoxi3': 0xfe71, // 消息
    'xiaoxi1': 0xe62b, // 消息
    'xiaoxi2': 0xe6a5, // 消息
    'Rrl_s_140': 0xe613, // 消息气泡
    'huihuarizhi': 0xe670, // 会话日志
    'faqihuihua': 0xe650, // 发起会话
    'huihua': 0xe63c, // 会话

    // ==================== 联系人相关 ====================
    'lianxiren3': 0xe685, // 联系人
    'lianxiren4': 0xe60f, // 联系人
    'lianxiren5': 0xe612, // 联系人
    'lianxiren6': 0xe680, // 联系人
    'lianxiren7': 0xe63a, // 联系人2
    'lianxiren8': 0xe645, // 联系人
    'lianxiren9': 0xe673, // 联系人
    'lianxiren10': 0xe617, // 联系人
    'lianxiren--': 0xe635, // 联系人
    'lianxiren-copy-copy': 0xe607, // 联系人
    'lianxiren1': 0xe609, // 联系人
    'lianxiren2': 0xe60a, // 联系人
    'lianxiren': 0xe622, // 联系人
    'renyuanmingdan': 0xe614, // 人员名单
    'tianjiahaoyou': 0xe61d, // 添加好友
    'tongxunlu': 0xe655, // 通讯录
    'pengyouquan': 0xe672, // 朋友圈
    'pengyou': 0xe61a, // 朋友

    // ==================== 设置相关 ====================
    '33': 0xe60c, // 设置
    'shezhi1': 0xe6b4, // 设置
    'User': 0xe610, // 设置
    'shezhix': 0xe611, // 设置
    'shezhi2': 0xe657, // 设置
    'shezhi': 0xe606, // 设置

    // ==================== 窗口控制（Mac风格） ====================
    'mac_top_green': 0xe6df, // 放大
    'mac_top_yellow': 0xe6e0, // 缩小
    'mac_top_ghover': 0xe6e1, // 放大悬浮
    'mac_top_yhover': 0xe6e2, // 缩小悬浮
    'mac_top_red': 0xe6df, // 关闭
    'mac_top_rhover': 0xe6e4, // 关闭悬浮

    // ==================== 箭头与方向 ====================
    'right': 0xe8e6, // 向右箭头
    'righttop': 0xe618, // 长箭头
    'zuixiaohua': 0xe624, // 最小化
    'zuidahua-da': 0xe693, // 最大化
    'zuoxuanzhuan': 0xe600, // 左旋转
    'youxuanzhuan': 0xe603, // 右旋转

    // ==================== 形状与图形 ====================
    'xingzhuang-juxing': 0xeb97, // 矩形
    'yuanxing': 0xe626, // 圆形
    'jurassic_line': 0xe68d, // 直线
    'masaike': 0xe759, // 马赛克

    // ==================== 操作按钮 ====================
    'wanchengqueding': 0xe69b, // 完成/确定
    'quxiao': 0xe620, // 取消
    'quxiaolianjie': 0xec80, // 取消链接
    'guanbi': 0xe6a8, // 关闭
    'chenggong': 0xe616, // 成功
    '71shibai': 0xe64a, // 失败
    'chulizhong': 0xefd0, // 处理中
    'fasongzhong': 0xe67b, // 发送中

    // ==================== 文件图标 ====================
    // Markdown 和文档
    'Markdown': 0xe6db, // Markdown
    'markdown': 0xe72f, // markdown

    // 压缩文件
    'file_rar': 0xe72b, // 压缩文件

    // Office 文档
    'file-b-': 0xe652, // file-b-4
    'file-b-1': 0xe653, // file-b-0
    'file-b-2': 0xe654, // file-b-6
    'file-b-3': 0xe656, // file-b-7
    'file-b-5': 0xe658, // file-b-3
    'file-b-7': 0xe65b, // file-b-1
    'file-b-8': 0xe65e, // file-b-2
    'file-b-9': 0xe660, // file-b-5
    'file-b-10': 0xe661, // file-b-9
    'file-b-12': 0xe664, // file-b-10
    'file-b-13': 0xe665, // file-b-15
    'file-b-14': 0xe667, // file-b-12
    'file-b-15': 0xe668, // file-b-14
    'file-b-16': 0xe669, // file-b-13
    'file-b-18': 0xe66b, // file-b-17
    'file-b-19': 0xe66c, // file-b-16
    'file-b-20': 0xe66d, // file-b-19
    'file-b-21': 0xe66e, // file-b-18
    'file-b-22': 0xe66f, // file-b-8
    'file-b-7-copy-copy': 0xe605, // file-b-0

    // 通用文件
    'wenjian': 0xe686, // 文件
    'wenjian1': 0xe633, // 文件

    // ==================== 图片与媒体 ====================
    'tupian': 0xe889, // 图片
    'biaoqing-xue': 0xe632, // 表情

    // ==================== 通话相关 ====================
    'shipintonghua': 0xe601, // 视频通话
    'shipintonghua1': 0xe825, // 视频通话
    'videoCall': 0xe765, // 视频通话
    'guaduan': 0xe6e3, // 挂断
    'dianhua': 0xe61b, // 电话

    // ==================== 网络与设备 ====================
    'wangluozhongduan': 0xe60b, // 网络中断
    'diannao': 0xe64e, // 电脑
    'shouji': 0xe615, // 手机

    // ==================== 编辑与操作 ====================
    'jia': 0xe608, // 加
    'shangchuan': 0xe666, // 上传
    'xiazai': 0xe65c, // 下载
    'baocun': 0xe63b, // 保存
    'fangda': 0xe60d, // 放大
    'fangda1': 0xec14, // 放大
    'suoxiao': 0xec13, // 缩小
    'juzhong': 0xe67f, // 居中

    // ==================== 用户与权限 ====================
    'nanxing': 0xe604, // 男性
    'nvxing': 0xe623, // 女性

    // ==================== 通知与提醒 ====================
    'tixing': 0xe639, // 提醒
    'sandian': 0xe634, // 三点
    'jinggao': 0xe84f, // 警告

    // ==================== 搜索与查找 ====================
    'sousuo': 0xe61c, // 搜索
    'search': 0xe699, // search

    // ==================== 语言与地区 ====================
    'yuyan-kong': 0xe692, // 语言-空

    // ==================== 其他图标 ====================
    'rengongzhineng': 0xe621, // 人工智能
    'gouwuche': 0xe602, // 购物车
  };

  // ==================== 文件扩展名映射 ====================
  // 将文件扩展名映射到对应的图标名称

  static const Map<String, String> _fileIconMap = {
    // Markdown 文档
    'md': '#icon-Markdown',

    // 压缩文件
    '7z': '#icon-file_rar',
    'rar': '#icon-file_rar',
    'zip': '#icon-file_rar',
    'tar': '#icon-file_rar',
    'gz': '#icon-file_rar',

    // PDF 文档
    'pdf': '#icon-file-b-3',

    // Word 文档
    'doc': '#icon-file-b-5',
    'docx': '#icon-file-b-5',
    'dot': '#icon-file-b-5',
    'dotx': '#icon-file-b-5',

    // Excel 表格
    'xls': '#icon-file-b-9',
    'xlsx': '#icon-file-b-9',
    'xlsm': '#icon-file-b-9',
    'csv': '#icon-file-b-9',

    // PowerPoint 演示
    'ppt': '#icon-file-b-4',
    'pptx': '#icon-file-b-4',

    // 文本文件
    'txt': '#icon-file-b-2',
    'log': '#icon-file-b-2',

    // 其他常见格式
    'json': '#icon-file-b-2',
    'xml': '#icon-file-b-2',
    'html': '#icon-file-b-2',
    'css': '#icon-file-b-2',
    'js': '#icon-file-b-2',
    'ts': '#icon-file-b-2',
    'dart': '#icon-file-b-2',
    'yaml': '#icon-file-b-2',
    'yml': '#icon-file-b-2',
  };

  // ==================== 公共方法 ====================

  /// 根据图标名称获取 [IconData]
  ///
  /// 参数：
  /// - [name]：图标名称（font_class），支持带 '#icon-' 前缀
  /// - [defaultValue]：找不到图标时返回的默认值
  ///
  /// 返回：
  /// - 如果找到对应图标，返回其 [IconData]
  /// - 如果未找到且提供了默认值，返回默认值
  /// - 如果未找到且未提供默认值，返回压缩文件图标
  ///
  /// 示例：
  /// ```dart
  /// Icon(Iconfont.fromName('Markdown'))
  /// Icon(Iconfont.fromName('#icon-Markdown'))
  /// Icon(Iconfont.fromName('unknown', defaultValue: Iconfont.add))
  /// ```
  static IconData fromName(String name, {IconData? defaultValue}) {
    // 处理带有前缀的名称
    String iconName = name;
    if (name.startsWith('#icon-')) {
      iconName = name.substring(6); // 移除 '#icon-' 前缀
    }

    int? codePoint = _iconNameToCodePoint[iconName];
    if (codePoint != null) {
      return IconData(codePoint, fontFamily: _fontFamily);
    }

    // 如果提供了默认值，则返回默认值
    if (defaultValue != null) {
      return defaultValue;
    }

    // 否则返回一个默认图标（压缩文件图标）
    return const IconData(0xe72b, fontFamily: _fontFamily);
  }

  /// 根据文件扩展名获取对应的图标
  ///
  /// 参数：
  /// - [extension]：文件扩展名（不需要点号前缀）
  ///
  /// 返回：
  /// - 对应文件类型的 [IconData]
  /// - 如果未找到对应扩展名的图标，返回默认图标
  ///
  /// 示例：
  /// ```dart
  /// Icon(Iconfont.fromFileExtension('pdf'))
  /// Icon(Iconfont.fromFileExtension('docx'))
  /// ```
  static IconData fromFileExtension(String extension) {
    String? iconKey = _fileIconMap[extension.toLowerCase()];
    if (iconKey != null) {
      return fromName(iconKey);
    }

    // 返回默认图标（通用文件图标）
    return fromName('file_rar');
  }

  /// 构建自定义图标 [Widget]
  ///
  /// 参数：
  /// - [icon]：图标的 [IconData]，如 [Iconfont.message]
  /// - [size]：图标大小，默认为 [AppSizes.iconMedium]
  /// - [color]：图标颜色，默认为 [AppColors.textPrimary]
  ///
  /// 返回：
  /// - 配置好的图标 [Widget]
  ///
  /// 示例：
  /// ```dart
  /// Iconfont.buildIcon(icon: Iconfont.message)
  /// Iconfont.buildIcon(icon: Iconfont.message, size: 32, color: Colors.blue)
  /// ```
  static Widget buildIcon({
    required IconData icon,
    double size = AppSizes.iconMedium,
    Color? color,
  }) {
    return Icon(
      icon,
      size: size,
      color: color ?? AppColors.textPrimary,
    );
  }

  /// 将图标代码点转换为 [IconData]
  ///
  /// 参数：
  /// - [codePoint]：图标的 Unicode 代码点（如 0xe601）
  /// - [fontFamily]：字体家族名称，默认为 [_fontFamily]
  ///
  /// 返回：
  /// - 对应代码点的 [IconData]
  ///
  /// 示例：
  /// ```dart
  /// Icon(Iconfont.fromCodePoint(0xe601))
  /// ```
  static IconData fromCodePoint(int codePoint,
      {String fontFamily = _fontFamily}) {
    return IconData(codePoint, fontFamily: fontFamily);
  }

  /// 检查指定名称的图标是否存在
  ///
  /// 参数：
  /// - [name]：图标名称（font_class）
  ///
  /// 返回：
  /// - 如果图标存在返回 true，否则返回 false
  ///
  /// 示例：
  /// ```dart
  /// if (Iconfont.hasIcon('Markdown')) {
  ///   print('Markdown 图标存在');
  /// }
  /// ```
  static bool hasIcon(String name) {
    return _iconNameToCodePoint.containsKey(name);
  }

  /// 获取所有可用的图标名称列表
  ///
  /// 返回：
  /// - 所有图标名称的列表（按字母顺序排序）
  ///
  /// 示例：
  /// ```dart
  /// final icons = Iconfont.getAllIconNames();
  /// print('共有 ${icons.length} 个图标');
  /// ```
  static List<String> getAllIconNames() {
    return _iconNameToCodePoint.keys.toList()..sort();
  }
}
