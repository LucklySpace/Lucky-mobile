import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../constants/app_constant.dart';
import '../controller/chat/chat_coordinator_controller.dart';

/// 本地通知服务类，基于 flutter_local_notifications 插件封装
/// 提供通知的初始化、显示、调度和取消功能，支持 Android/iOS 跨平台
/// 使用 GetX 服务管理，确保单例使用；自动处理权限请求和时区初始化
class LocalNotificationService extends GetxService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();

  factory LocalNotificationService() => _instance;

  LocalNotificationService._internal();

  late final FlutterLocalNotificationsPlugin _plugin;
  final String _androidChannelId = 'im_message_channel';
  final String _androidChannelName = 'IM 消息通知';
  final String _androidChannelDescription = '接收实时聊天消息通知';

  final _storage = GetStorage();

  // ==================== 响应式状态 ====================

  /// 是否启用通知
  final RxBool enableNotification = true.obs;

  /// 是否显示预览内容
  final RxBool showPreview = true.obs;

  /// 是否开启声音
  final RxBool sound = true.obs;

  /// 是否开启振动
  final RxBool vibrate = true.obs;

  /// 初始化通知服务
  @override
  Future<void> onInit() async {
    super.onInit();
    _plugin = FlutterLocalNotificationsPlugin();
    _loadSettings();
    await _initializePlugin();
    await _requestPermissions();
    await _initializeTimezone();
  }

  /// 加载本地保存的设置
  void _loadSettings() {
    enableNotification.value =
        _storage.read(AppConstants.cacheKeyNotificationEnable) ?? true;
    showPreview.value =
        _storage.read(AppConstants.cacheKeyNotificationShowPreview) ?? true;
    sound.value = _storage.read(AppConstants.cacheKeyNotificationSound) ?? true;
    vibrate.value =
        _storage.read(AppConstants.cacheKeyNotificationVibrate) ?? true;
  }

  /// 更新通知开关
  Future<void> updateEnableNotification(bool value) async {
    enableNotification.value = value;
    await _storage.write(AppConstants.cacheKeyNotificationEnable, value);
  }

  /// 更新预览开关
  Future<void> updateShowPreview(bool value) async {
    showPreview.value = value;
    await _storage.write(AppConstants.cacheKeyNotificationShowPreview, value);
  }

  /// 更新声音开关
  Future<void> updateSound(bool value) async {
    sound.value = value;
    await _storage.write(AppConstants.cacheKeyNotificationSound, value);
  }

  /// 更新振动开关
  Future<void> updateVibrate(bool value) async {
    vibrate.value = value;
    await _storage.write(AppConstants.cacheKeyNotificationVibrate, value);
  }

  /// 初始化插件配置
  ///
  /// 设置 Android/iOS 等平台的初始化参数；支持自定义图标和回调
  Future<void> _initializePlugin() async {
    try {
      // Android 配置：使用默认应用图标
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');

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
            _handleNotificationClick(payload);
          }
        },
      );
    } catch (e) {
      Get.log('❌ 通知插件初始化失败: $e');
    }
  }

  /// 处理通知点击跳转
  void _handleNotificationClick(String chatId) {
    try {
      // 这里的逻辑通常是跳转到对应的聊天页面
      // 1. 获取 ChatCoordinatorController (即 ChatController)
      // 2. 找到对应的会话并设置为当前会话
      // 3. 执行跳转
      // 注意：如果应用已在后台或者关闭状态，可能需要一些初始化逻辑

      // 我们通过 Get.find 获取控制器
      // ignore: doc_directive_unknown
      /// @see ChatCoordinatorController.changeCurrentChat
      final chatController = Get.find<ChatCoordinatorController>();

      // 在列表中查找会话
      final chat =
          chatController.chatList.firstWhereOrNull((c) => c.chatId == chatId);
      if (chat != null) {
        chatController.changeCurrentChat(chat);
      }
    } catch (e) {
      Get.log('❌ 处理通知点击失败: $e');
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
  Future<void> _initializeTimezone() async {
    try {
      tz.initializeTimeZones();
      final String timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone));
    } catch (e) {
      Get.log('❌ 时区初始化失败: $e');
    }
  }

  /// 显示聊天消息通知
  ///
  /// [chatId] 会话唯一标识
  /// [senderName] 发送者名称
  /// [content] 消息内容
  Future<void> showMessageNotification({
    required String chatId,
    required String senderName,
    required String content,
  }) async {
    // 1. 检查总开关
    if (!enableNotification.value) return;

    try {
      // 2. 根据设置脱敏
      final String displayTitle = showPreview.value ? senderName : 'Lucky IM';
      final String displayBody = showPreview.value ? content : '您收到一条新消息';

      // 3. 构建 Android 详情（适配 IM 风格）
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableLights: true,
        playSound: sound.value,
        enableVibration: vibrate.value,
        // 使用分组，同一会话的消息会叠在一起
        groupKey: chatId,
        setAsGroupSummary: false,
        category: AndroidNotificationCategory.message,
      );

      // 4. 构建 iOS 详情
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: sound.value,
        threadIdentifier: chatId, // iOS 消息聚合关键
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 使用 chatId 的哈希值作为通知 ID，确保同一会话的消息覆盖/聚合
      final int notificationId = chatId.hashCode;

      await _plugin.show(
        notificationId,
        displayTitle,
        displayBody,
        details,
        payload: chatId,
      );
      Get.log('✅ 消息通知已弹出: ChatId=$chatId');
    } catch (e) {
      Get.log('❌ 消息通知弹出失败: $e');
    }
  }

  /// 取消指定会话的所有通知
  Future<void> cancelChatNotifications(String chatId) async {
    try {
      await _plugin.cancel(chatId.hashCode);
      Get.log('✅ 已清理会话通知: $chatId');
    } catch (e) {
      Get.log('❌ 清理会话通知失败: $e');
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

  @override
  void onClose() {
    super.onClose();
  }
}
