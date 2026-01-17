import 'dart:io';

/// 环境类型枚举
enum Environment {
  dev, // 开发环境
  staging, // 测试环境
  prod // 生产环境
}

/// 应用配置类 - 统一管理应用级别配置
///
/// 支持多环境配置，可在编译时或运行时切换环境
/// 使用方式: AppConfig.apiServer, AppConfig.isDebug 等
class AppConfig {
  // ==================== 环境配置 ====================

  /// 当前环境，可根据实际需求在编译时设置
  static const Environment _currentEnv = Environment.dev;

  /// 是否为调试模式
  static const bool isDebug = true;

  /// 根据环境获取服务器地址
  static String get _baseHost {
    switch (_currentEnv) {
      case Environment.dev:
        return '192.168.31.166'; // 开发环境地址
      case Environment.staging:
        return 'staging.example.com'; // 测试环境地址
      case Environment.prod:
        return 'api.example.com'; // 生产环境地址
    }
  }

  // ==================== API 服务配置 ====================

  /// API 服务器地址（主服务）
  static String get apiServer => 'https://$_baseHost:9190';

  /// 各服务的基础URL配置
  static Map<String, String> get serviceUrls => {
        'auth': '$apiServer/auth/api/v1', // 认证服务
        'service': '$apiServer/service/api/v1', // 业务服务
        'wallet': '$apiServer/wallet/api', // 钱包服务
        'upload': '$apiServer/upload/api/v1', // 上传服务
        'webrtc': 'https://$_baseHost', // WebRTC服务
      };

  /// API 基础路径
  static const String baseApi = '/api';

  /// WebSocket 服务器地址（IM通讯）
  static String get wsServer => 'ws://$_baseHost:9191/im';

  /// WebSocket 服务器地址（会议）
  static String get meetWsServer => 'wss://$_baseHost:9190/meet';

  /// WebRTC 服务器地址
  static String get webRtcServer => 'webRTC://$_baseHost/live/';

  /// SRS 流媒体服务器地址
  static String get srsServer => 'https://$_baseHost:1980';

  // ==================== 应用信息 ====================

  static const String appName = 'Lucky IM';
  static const String version = '1.0.0';
  static const String appVersion = '1.0.0';
  static const String appDescription = '即时通讯应用';
  static const String appIcon = 'assets/logo.png';
  static const String appIconSmall = 'assets/logo_small.png';
  static const String appCopyright =
      '© 2023-2026 Lucky IM. All rights reserved.';

  /// 公司信息
  static const String companyName = 'Lucky IM';

  /// 官方网站
  static const String website = 'https://github.com/LucklySpace';

  /// 联系邮箱
  static const String supportEmail = 'support@lucky-im.example.com';
  static const String businessEmail = 'business@lucky-im.example.com';
  static const String techSupportEmail = 'tech@lucky-im.example.com';

  /// 设备类型标识
  static final String deviceType = Platform.isIOS ? 'ios' : 'android';

  /// 协议类型: 'json' 或 'proto'
  static const String protocolType = 'proto';

  /// 默认网页地址
  static const String defaultUrl = 'https://luckly-xyz.github.io';

  // ==================== 存储配置 ====================

  /// 本地存储名称
  static const String storeName = 'im_store';

  /// 数据库文件名
  static const String databaseName = 'im_db.db';

  /// 数据库索引文件名
  static const String databaseIndexName = 'im_index.db';

  // ==================== 业务配置 ====================

  /// 列表刷新时间（毫秒）
  static const int listRefreshTime = 10000;

  /// 音频文件路径前缀
  static const String audioPath = 'assets/audio/';

  /// 通知标题
  static const String notificationTitle = 'Lucky';

  /// 消息时间显示间隔（分钟）
  static const int messageTimeDisplayInterval = 5;

  /// 图片裁剪超时时间（秒）
  static const int cropImageTimeout = 30;

  /// 表情包文件路径
  static const String emojiPath = 'assets/data/emoji_pack.json';

  /// 图片选择器路径标识
  static const String pickerPath = 'picker';

  // ==================== 网络配置 ====================

  /// 连接超时时间（秒）
  static const int connectTimeout = 10;

  /// 接收超时时间（秒）
  static const int receiveTimeout = 10;

  /// 发送超时时间（秒）
  static const int sendTimeout = 10;

  /// WebSocket 心跳间隔（毫秒）
  static const int heartbeatInterval = 20000;

  /// WebSocket 最大重连次数
  static const int maxReconnectAttempts = 10;

  /// WebSocket 重连基础延迟（秒）
  static const int reconnectBaseDelay = 2;

  // ==================== 分页配置 ====================

  /// 默认分页大小
  static const int defaultPageSize = 20;

  /// 消息列表分页大小
  static const int messagePageSize = 20;

  // ==================== 工具方法 ====================

  /// 获取完整的 API URL
  static String getApiUrl(String path) {
    return '$apiServer$baseApi$path';
  }

  /// 获取文件完整 URL (针对头像、图片等)
  static String getFullUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // 处理相对路径，这里默认拼接到 apiServer，具体根据后端情况调整
    // 如果后端返回的是包含 /upload/ 的路径，可能需要拼接 upload 服务地址
    final baseUrl = apiServer;
    return '$baseUrl${url.startsWith('/') ? '' : '/'}$url';
  }

  /// 获取音频文件完整路径
  static String getAudioPath(String fileName) {
    return '$audioPath$fileName';
  }

  /// 获取当前环境名称
  static String getEnvironmentName() {
    return _currentEnv.name.toUpperCase();
  }

  /// 打印当前配置信息（仅用于调试）
  static void printConfig() {
    if (!isDebug) return;

    print('╔════════════════════════════════════════╗');
    print('║      Lucky IM Configuration Info      ║');
    print('╠════════════════════════════════════════╣');
    print('║ Environment: ${getEnvironmentName().padRight(27)}║');
    print('║ Debug Mode:  ${isDebug.toString().padRight(27)}║');
    print('║ API Server:  ${apiServer.padRight(27)}║');
    print('║ WS Server:   ${wsServer.padRight(27)}║');
    print('║ Version:     ${appVersion.padRight(27)}║');
    print('╚════════════════════════════════════════╝');
  }
}
