/// 应用常量定义类
///
/// 存储应用级别的常量，包括：
/// - 业务常量
/// - 状态码常量
/// - 二维码前缀
/// - 时间常量
/// - 文件大小限制
class AppConstants {
  // 私有构造函数，防止实例化
  AppConstants._();

  // ==================== 二维码前缀常量 ====================

  /// 登录二维码前缀
  static const String loginQrcodePrefix = 'IM-LOGIN-QRCODE-';

  /// 好友资料二维码前缀
  static const String friendProfilePrefix = 'IM-FRIEND-PROFILE-';

  /// 钱包地址二维码前缀
  static const String walletAddressPrefix = 'IM-WALLET-ADDRESS-';

  // ==================== HTTP 状态码 ====================

  /// 成功状态码
  static const int httpStatusSuccess = 200;

  /// 创建成功状态码
  static const int httpStatusCreated = 201;

  /// 未授权状态码
  static const int httpStatusUnauthorized = 401;

  /// 禁止访问状态码
  static const int httpStatusForbidden = 403;

  /// 未找到状态码
  static const int httpStatusNotFound = 404;

  /// 服务器错误状态码
  static const int httpStatusServerError = 500;

  // ==================== 业务状态码 ====================

  /// 业务成功码
  static const int businessCodeSuccess = 200;

  /// Token失效码
  static const int businessCodeTokenExpired = 401;

  /// 权限不足码
  static const int businessCodePermissionDenied = 403;

  // ==================== 时间常量（秒） ====================

  /// 防抖延迟（毫秒）
  static const int debounceDelayMs = 500;

  /// 节流延迟（毫秒）
  static const int throttleDelayMs = 1000;

  /// 默认动画时长（毫秒）
  static const int defaultAnimationDurationMs = 300;

  // ==================== 文件大小限制（字节） ====================

  /// 图片最大大小 - 10MB
  static const int maxImageSize = 10 * 1024 * 1024;

  /// 视频最大大小 - 100MB
  static const int maxVideoSize = 100 * 1024 * 1024;

  /// 文件最大大小 - 50MB
  static const int maxFileSize = 50 * 1024 * 1024;

  /// 音频最大大小 - 20MB
  static const int maxAudioSize = 20 * 1024 * 1024;

  // ==================== 消息相关常量 ====================

  /// 消息最大长度
  static const int maxMessageLength = 5000;

  /// 群聊最大人数
  static const int maxGroupMembers = 500;

  /// 群名称最大长度
  static const int maxGroupNameLength = 50;

  /// 用户昵称最大长度
  static const int maxNicknameLength = 30;

  /// 默认分页大小
  static const int defaultPageSize = 20;

  // ==================== 缓存Key常量 ====================

  ///
  static const String heartbeat = 'heartbeat';

  /// 心跳
  static const String registrar = 'registrar';

  /// 用户信息缓存Key
  static const String cacheKeyUserInfo = 'user_info';

  /// Token缓存Key
  static const String cacheKeyToken = 'token';

  /// 语言设置缓存Key
  static const String cacheKeyLanguage = 'language';

  /// 主题设置缓存Key
  static const String cacheKeyTheme = 'theme';

  /// 用户ID缓存Key
  static const String cacheKeyUserId = 'userId';

  // ==================== 通知设置缓存Key ====================

  /// 启用消息通知
  static const String cacheKeyNotificationEnable = 'notification_enable';

  /// 显示消息预览
  static const String cacheKeyNotificationShowPreview =
      'notification_show_preview';

  /// 声音提醒
  static const String cacheKeyNotificationSound = 'notification_sound';

  /// 振动提醒
  static const String cacheKeyNotificationVibrate = 'notification_vibrate';

  // ==================== 正则表达式常量 ====================

  /// 手机号正则（中国大陆）
  static const String regexPhoneChina = r'^1[3-9]\d{9}$';

  /// 邮箱正则
  static const String regexEmail = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';

  /// URL正则
  static const String regexUrl = r'^https?:\/\/.+';
}
