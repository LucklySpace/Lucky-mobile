import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';
import 'package:workmanager/workmanager.dart';

import 'app/database/app_database.dart';
import 'binding/app_bindings.dart';
import 'config/app_config.dart';
import 'i18n/app_trans.dart';
import 'routes/app_pages.dart';
import 'theme/app_theme_data.dart';

final getIt = GetIt.instance;

Future<void> main() async {
  await initApp();
  runApp(const MyApp());
}

/// 应用初始化函数
///
/// 执行以下初始化操作：
/// 1. 配置开发环境SSL证书（仅调试模式）
/// 2. 初始化Flutter绑定
/// 3. 初始化本地存储
/// 4. 配置自定义日志
/// 5. 初始化数据库
/// 6. 初始化后台任务管理器
Future<void> initApp() async {
  // 初始化Flutter绑定（必须在所有初始化之前）
  WidgetsFlutterBinding.ensureInitialized();

  // 打印配置信息（仅调试模式）
  AppConfig.printConfig();

  // 配置SSL证书（仅调试模式，用于开发环境）
  if (AppConfig.isDebug) {
    HttpOverrides.global = GlobalHttpOverrides();
  }

  // 初始化GetStorage本地存储
  await GetStorage.init();

  // 配置自定义日志输出
  Get.config(
    enableLog: AppConfig.isDebug,
    logWriterCallback: customLogWriter,
  );

  // 初始化数据库并注册到依赖注入容器
  final database =
      await $FloorAppDatabase.databaseBuilder(AppConfig.databaseName).build();
  getIt.registerSingleton<AppDatabase>(database);

  // 初始化后台任务管理器
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: AppConfig.isDebug,
  );
}

/// tips : 所有类启动 都需要 注意 优先级，否则可能初始化失败找不到类
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // 标题
      title: 'Lucky App',
      // 初始化绑定
      initialBinding: AppAllBinding(),
      // 初始路由
      initialRoute: AppPages.initial,
      // 路由
      getPages: AppPages.rootRoutes,
      // 路由
      unknownRoute: AppPages.unknownRoute,
      routingCallback: routingCallback,
      // 国际化配置
      translations: AppTranslations(),
      // 默认语言
      locale: const Locale('zh', 'CN'),
      // 备用语言
      fallbackLocale: const Locale('en', 'US'),

      // 添加本地化代理
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 添加支持的语言
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],

      // 主题
      theme: AppThemeData.lightTheme,
      darkTheme: AppThemeData.darkTheme,
      themeMode: ThemeMode.system,

      // 去除debug 标志
      debugShowCheckedModeBanner: false,
    );
  }
}

/// 路由回调函数
///
/// 在路由变化时被调用，可用于：
/// - 页面埋点统计
/// - 权限检查
/// - 页面切换动画
/// - 日志记录
void routingCallback(Routing? routing) {
  if (routing == null) return;

  // 记录路由变化（仅调试模式）
  if (AppConfig.isDebug) {
    Get.log('📍 路由变化: ${routing.current}');
  }

  // TODO: 可在此处添加页面埋点、权限检查等业务逻辑
  // 示例：
  // if (routing.current == '/premium_feature') {
  //   checkUserPermission();
  // }
}

/// 后台任务调度器
///
/// 处理后台定时任务，如：
/// - 消息同步
/// - 数据清理
/// - 状态更新
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    debugPrint('🔄 后台任务执行: $task');

    // TODO: 根据任务类型执行不同的后台操作
    // 示例：
    // switch (task) {
    //   case 'syncMessages':
    //     return syncMessagesInBackground();
    //   case 'cleanCache':
    //     return cleanCacheInBackground();
    // }

    return Future.value(true);
  });
}

/// 自定义日志输出函数
///
/// 功能：
/// - 格式化日志输出，包含时间戳、文件信息
/// - 仅在调试模式下执行详细日志处理
/// - 生产环境仅输出错误日志
///
/// 参数：
/// - [text] 日志内容
/// - [isError] 是否为错误日志
void customLogWriter(String text, {bool isError = false}) {
  // 生产环境：仅输出错误日志
  if (!AppConfig.isDebug) {
    if (isError) {
      debugPrint('❌ $text');
    }
    return;
  }

  // 开发环境：格式化输出详细日志
  final now = DateTime.now();
  final formattedTime = _formatDateTime(now);
  final fileInfo = _extractFileInfo();

  final icon = isError ? '❌' : '✅';
  final logText = '$icon [$formattedTime] ($fileInfo) $text';

  debugPrint(logText);
}

/// 格式化时间
String _formatDateTime(DateTime dateTime) {
  return '${dateTime.year}-'
      '${dateTime.month.toString().padLeft(2, '0')}-'
      '${dateTime.day.toString().padLeft(2, '0')} '
      '${dateTime.hour.toString().padLeft(2, '0')}:'
      '${dateTime.minute.toString().padLeft(2, '0')}:'
      '${dateTime.second.toString().padLeft(2, '0')}';
}

/// 从堆栈信息中提取文件名和行号
String _extractFileInfo() {
  try {
    final stackTrace = StackTrace.current.toString();
    final frames = stackTrace.split('\n');

    // 跳过前几帧（通常是日志函数本身的调用）
    if (frames.length > 2) {
      final frame = frames[2];
      final regex = RegExp(r'\((.*?):(\d+):(\d+)\)');
      final match = regex.firstMatch(frame);

      if (match != null) {
        final filePath = match.group(1) ?? '';
        final lineNumber = match.group(2) ?? '0';

        // 只保留文件名（不包含完整路径）
        final fileName = filePath.split('/').last;
        return '$fileName:$lineNumber';
      }
    }
  } catch (e) {
    // 忽略堆栈解析错误，避免日志功能本身出错
  }

  return 'Unknown:0';
}

/// 全局HTTP覆写配置
///
/// ⚠️ 仅用于开发环境！
///
/// 功能：忽略SSL证书验证，方便开发调试
/// 注意：生产环境必须移除此配置，否则存在安全风险
class GlobalHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);

    // 忽略SSL证书验证（仅开发环境）
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;

    return client;
  }
}
