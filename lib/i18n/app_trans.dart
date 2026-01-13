import 'package:get/get.dart';

import 'en_US.dart';
import 'zh_CN.dart';

/// 应用翻译管理器
///
/// 管理应用的所有翻译文本，支持中文和英文
///
/// 支持的语言：
/// - zh_CN: 中文简体
/// - en_US: 英语（美国）
///
/// 使用方式：
/// ```dart
/// // 在 main.dart 中配置
/// GetMaterialApp(
///   translations: AppTranslations(),
///   locale: Locale('zh', 'CN'),
///   fallbackLocale: Locale('en', 'US'),
/// )
///
/// // 在代码中使用
/// Text('login'.tr)  // 登录 / Login
/// ```
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': zhCN,
        'en_US': enUS,
      };
}
