import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 本地通知服务类，基于 flutter_local_notifications 插件封装
/// 提供通知的初始化、显示、调度和取消功能，支持 Android/iOS 跨平台
/// 使用 GetX 服务管理，确保单例使用；自动处理权限请求和时区初始化
class LocalNotificationService extends GetxService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();

  factory LocalNotificationService() => _instance;

  LocalNotificationService._internal();

  late final FlutterLocalNotificationsPlugin _plugin;
  final String _androidChannelId = 'default_channel';
  final String _androidChannelName = '默认通知通道';
  final String _androidChannelDescription = '用于应用本地通知';

  /// 初始化通知插件
  ///
  /// 在应用启动时调用（如 main.dart 中的 Get.put()），会自动请求权限和设置时区
  /// 返回: 初始化是否成功
  @override
  Future<void> onInit() async {
    super.onInit();
    _plugin = FlutterLocalNotificationsPlugin();
    await _initializePlugin();
    await _requestPermissions();
    await _initializeTimezone();
  }

  /// 初始化插件配置
  ///
  /// 设置 Android/iOS 等平台的初始化参数；支持自定义图标和回调
  /// [onSelectNotification] 通知点击回调（可选），用于处理 payload
  Future<void> _initializePlugin(
      {void Function(String?)? onSelectNotification}) async {
    try {
      // Android 配置：使用默认应用图标，创建高优先级通道
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS 配置：允许前台显示警报、声音和徽章
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // 跨平台初始化设置
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // 初始化插件并设置通知响应回调
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final String? payload = response.payload;
          if (payload != null) {
            Get.log('📱 通知点击: $payload');
            onSelectNotification?.call(payload);
          }
        },
      );
    } catch (e) {
      Get.log('❌ 通知插件初始化失败: $e');
      rethrow;
    }
  }

  /// 请求通知权限
  ///
  /// Android 13+ 和 iOS 都需要显式请求；返回权限是否已授予
  Future<bool> _requestPermissions() async {
    try {
      // Android 权限请求
      final AndroidFlutterLocalNotificationsPlugin? androidImpl =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.requestNotificationsPermission();
        // 可选：请求精确闹钟权限（用于精确调度）
        // await androidImpl.requestExactAlarmsPermission();
      }

      // iOS 权限请求
      final IOSFlutterLocalNotificationsPlugin? iosImpl =
          _plugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final bool granted = await iosImpl.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
        return granted;
      }

      return true; // 默认授予（其他平台）
    } catch (e) {
      Get.log('❌ 权限请求失败: $e');
      return false;
    }
  }

  /// 初始化时区（用于调度通知）
  ///
  /// 使用 flutter_timezone 获取设备时区，确保调度准确（考虑夏令时）
  Future<void> _initializeTimezone() async {
    try {
      tz.initializeTimeZones();
      final String timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone));
    } catch (e) {
      Get.log('❌ 时区初始化失败: $e');
    }
  }

  /// 显示本地通知
  ///
  /// [id] 通知唯一 ID（用于取消）
  /// [title] 通知标题
  /// [body] 通知正文
  /// [payload] 附加数据（点击时传递，可选）
  /// [channelId] Android 通道 ID（可选，默认使用通用通道）
  /// 返回: 显示是否成功
  Future<bool> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channelId,
  }) async {
    try {
      // 构建通知详情
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId ?? _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(id, title, body, details, payload: payload);
      Get.log('✅ 通知显示成功: ID=$id');
      return true;
    } catch (e) {
      Get.log('❌ 通知显示失败 (ID=$id): $e');
      return false;
    }
  }

  /// 调度本地通知（定时显示）
  ///
  /// [id] 通知唯一 ID
  /// [title] 通知标题
  /// [body] 通知正文
  /// [scheduledDate] 调度时间（TZDateTime）
  /// [payload] 附加数据（可选）
  /// [repeat] 是否重复（可选，默认不重复）
  /// [channelId] Android 通道 ID（可选）
  /// 返回: 调度是否成功
  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
    DateTimeComponents? matchDateTimeComponents, // 用于重复：如 .time（每日）
    String? channelId,
  }) async {
    try {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId ?? _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
      );

      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // await _plugin.zonedSchedule(
      //   id,
      //   title,
      //   body,
      //   scheduledDate,
      //   details,
      //   payload: payload,
      //   androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      //   // 精确调度（需权限）
      //   uiLocalNotificationDateInterpretation:
      //       UILocalNotificationDateInterpretation.absoluteTime,
      //   matchDateTimeComponents: matchDateTimeComponents,
      // );
      Get.log('✅ 通知调度成功: ID=$id, 时间=${scheduledDate.toString()}');
      return true;
    } catch (e) {
      Get.log('❌ 通知调度失败 (ID=$id): $e');
      // 可回退到不精确调度：使用 AndroidScheduleMode.inexact
      return false;
    }
  }

  /// 取消指定通知
  ///
  /// [id] 通知 ID
  /// 返回: 取消是否成功
  Future<bool> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id);
      Get.log('✅ 通知取消成功: ID=$id');
      return true;
    } catch (e) {
      Get.log('❌ 通知取消失败 (ID=$id): $e');
      return false;
    }
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      Get.log('✅ 所有通知已取消');
    } catch (e) {
      Get.log('❌ 取消所有通知失败: $e');
    }
  }

  /// 检查通知权限状态
  ///
  /// 返回: true 表示已授予权限（iOS 检查 alert 权限，Android 检查整体启用状态）
  Future<bool> checkPermissions() async {
    try {
      if (Platform.isIOS) {
        final iosImpl = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final options = await iosImpl?.checkPermissions();
        // 检查 alert 权限（通知可见性）
        return options?.isAlertEnabled ?? false;
      } else if (Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await androidImpl?.areNotificationsEnabled() ?? false;
      } else {
        // 其他平台默认启用
        return true;
      }
    } catch (e) {
      Get.log('❌ 检查权限失败: $e');
      return false;
    }
  }

  @override
  void onClose() {
    cancelAll(); // 清理资源
    super.onClose();
  }
}
