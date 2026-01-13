import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../config/app_config.dart';
import '../../proto/im_connect.pb.dart';
import '../../proto/im_connect_json.dart';
import '../controller/user_controller.dart';

/// WebSocket连接状态枚举
enum SocketStatus {
  /// 已连接
  connected,

  /// 连接中
  connecting,

  /// 连接失败
  failed,

  /// 连接已关闭
  closed,

  /// 重连中
  reconnecting,
}

/// 消息序列化类型
enum SerializationType {
  /// JSON格式
  json,

  /// Protocol Buffer格式
  protobuf
}

/// WebSocket服务类
///
/// 功能：
/// - 管理WebSocket连接生命周期
/// - 自动心跳保活
/// - 智能重连机制（指数退避）
/// - 支持JSON和Protobuf两种序列化方式
class WebSocketService extends GetxService {
  /// 单例访问
  static WebSocketService get to => Get.find();

  // ==================== 私有字段 ====================

  /// WebSocket连接实例
  WebSocketChannel? _webSocket;

  /// 心跳定时器
  Timer? _heartBeatTimer;

  /// 重连定时器
  Timer? _reconnectTimer;

  /// 连接状态订阅
  StreamSubscription? _streamSubscription;

  /// 当前连接URL
  Uri? _requestUrl;

  /// 重连次数计数器
  int _reconnectAttempts = 0;

  /// 是否正在连接中（防止重复连接）
  bool _isConnecting = false;

  /// 是否手动关闭（手动关闭时不自动重连）
  bool _isManualClose = false;

  // ==================== 配置参数 ====================

  /// 心跳间隔（毫秒）
  final int _heartbeatInterval = AppConfig.heartbeatInterval;

  /// 最大重连次数
  final int _maxReconnectAttempts = AppConfig.maxReconnectAttempts;

  /// 重连基础延迟（秒）
  final int _reconnectBaseDelay = AppConfig.reconnectBaseDelay;

  // ==================== 响应式状态 ====================

  /// 连接状态
  final Rx<SocketStatus> _socketStatus = SocketStatus.closed.obs;

  /// 最新接收的消息（用于调试）
  final RxString latestMessage = ''.obs;

  // ==================== 公开属性 ====================

  /// 序列化类型
  SerializationType serializationType = AppConfig.protocolType == 'proto'
      ? SerializationType.protobuf
      : SerializationType.json;

  /// 连接状态
  SocketStatus get socketStatus => _socketStatus.value;

  /// 连接状态流
  Stream<SocketStatus> get socketStatusStream => _socketStatus.stream;

  /// 是否已连接
  bool get isConnected => _socketStatus.value == SocketStatus.connected;

  /// WebSocket关闭码
  int? get webSocketCloseCode => _webSocket?.closeCode;

  // ==================== 回调函数 ====================

  /// 连接成功回调
  Function? onOpen;

  /// 接收消息回调
  Function? onMessage;

  /// 连接错误回调
  Function? onError;

  // ==================== 生命周期方法 ====================

  /// 初始化服务
  Future<WebSocketService> init() async {
    Get.log('📡 WebSocket服务初始化完成');
    return this;
  }

  /// 服务关闭时的清理工作
  @override
  void onClose() {
    _cleanup();
    super.onClose();
  }

  // ==================== 连接管理 ====================

  /// 初始化WebSocket连接
  ///
  /// [onOpen] 连接成功回调
  /// [onMessage] 接收消息回调
  /// [onError] 连接错误回调
  /// [uid] 用户ID
  /// [token] 认证令牌
  /// [serializationType] 序列化类型（可选）
  void initWebSocket({
    Function? onOpen,
    Function? onMessage,
    Function? onError,
    String? uid,
    String? token,
    SerializationType? serializationType,
  }) {
    // 设置序列化类型
    this.serializationType = serializationType ??
        (AppConfig.protocolType == 'proto'
            ? SerializationType.protobuf
            : SerializationType.json);

    // 设置回调函数
    this.onOpen = onOpen;
    this.onMessage = onMessage;
    this.onError = onError;

    // 开始连接
    _connect(uid: uid, token: token);
  }

  /// 建立WebSocket连接
  ///
  /// [uid] 用户ID
  /// [token] 认证令牌
  void _connect({String? uid, String? token}) {
    // 防止重复连接
    if (_isConnecting) {
      Get.log('⚠️ WebSocket正在连接中，跳过重复请求');
      return;
    }

    // 如果已连接，先关闭旧连接
    if (isConnected) {
      Get.log('⚠️ 检测到已有连接，先关闭旧连接');
      _closeConnection(manual: false);
    }

    // 构建连接URL
    Uri? url;
    if (uid != null && uid.isNotEmpty && token != null && token.isNotEmpty) {
      url = Uri.parse(AppConfig.wsServer).replace(queryParameters: {
        'uid': uid,
        'token': token,
      });
    }

    // 更新连接URL（只有URL变化时才更新）
    if (url != null && _requestUrl != url) {
      _requestUrl = url;
      Get.log('📍 WebSocket URL: $_requestUrl');
    }

    // 检查URL有效性
    if (_requestUrl == null) {
      Get.log('❌ WebSocket连接失败: URL无效');
      _socketStatus.value = SocketStatus.failed;
      onError?.call('连接URL无效');
      return;
    }

    // 开始连接
    _isConnecting = true;
    _isManualClose = false;
    _socketStatus.value = SocketStatus.connecting;

    try {
      // 创建WebSocket连接
      _webSocket = WebSocketChannel.connect(_requestUrl!);

      Get.log('🔄 WebSocket开始连接: ${AppConfig.wsServer}');

      // 监听消息流
      _streamSubscription = _webSocket!.stream.listen(
        _onMessageReceived,
        onError: _onConnectionError,
        onDone: _onConnectionClosed,
        cancelOnError: false,
      );

      // 连接成功
      _socketStatus.value = SocketStatus.connected;
      _reconnectAttempts = 0;
      _isConnecting = false;

      // 清理重连定时器
      _cancelReconnectTimer();

      Get.log('✅ WebSocket连接成功');

      // 触发回调
      onOpen?.call();
    } catch (e, stackTrace) {
      Get.log('❌ WebSocket连接异常: $e');
      Get.log(stackTrace.toString());

      _isConnecting = false;
      _socketStatus.value = SocketStatus.failed;
      onError?.call('连接异常: $e');

      // 触发重连
      _scheduleReconnect();
    }
  }

  // ==================== 消息处理 ====================

  /// 接收到消息的回调
  void _onMessageReceived(dynamic data) {
    try {
      if (serializationType == SerializationType.protobuf) {
        _handleProtobufMessage(data);
      } else {
        _handleJsonMessage(data);
      }
    } catch (e, stackTrace) {
      Get.log('❌ 消息处理失败: $e');
      Get.log(stackTrace.toString());
    }
  }

  /// 处理Protobuf格式消息
  void _handleProtobufMessage(dynamic data) {
    try {
      if (data is Uint8List) {
        final message = IMConnectMessage.fromBuffer(data);
        latestMessage.value = jsonEncode(message.toJson());
        onMessage?.call(latestMessage.value);
      } else if (data is List<int>) {
        final message = IMConnectMessage.fromBuffer(Uint8List.fromList(data));
        latestMessage.value = message.toString();
        onMessage?.call(message);
      } else {
        Get.log('⚠️ Protobuf模式下收到非二进制数据: ${data.runtimeType}');
        latestMessage.value = data.toString();
        onMessage?.call(data);
      }
    } catch (e, stackTrace) {
      Get.log('❌ Protobuf消息解析失败: $e');
      Get.log(stackTrace.toString());
    }
  }

  /// 处理JSON格式消息
  void _handleJsonMessage(dynamic data) {
    try {
      String textData;

      // 统一转换为字符串
      if (data is String) {
        textData = data;
      } else if (data is List<int>) {
        textData = utf8.decode(data);
      } else if (data is Uint8List) {
        textData = utf8.decode(data);
      } else {
        Get.log('⚠️ JSON模式下收到未知类型数据: ${data.runtimeType}');
        latestMessage.value = data.toString();
        onMessage?.call(data);
        return;
      }

      // 解析JSON
      final jsonData = jsonDecode(textData);
      latestMessage.value = textData;
      onMessage?.call(jsonData);
    } catch (e, stackTrace) {
      Get.log('❌ JSON消息解析失败: $e');
      Get.log(stackTrace.toString());
    }
  }

  /// 连接关闭的回调
  void _onConnectionClosed() {
    Get.log('🔌 WebSocket连接已关闭');

    // 更新状态
    if (!_isManualClose) {
      _socketStatus.value = SocketStatus.closed;

      // 停止心跳
      _stopHeartbeat();

      // 触发重连
      _scheduleReconnect();
    } else {
      _socketStatus.value = SocketStatus.closed;
      Get.log('✅ 手动关闭连接，不进行重连');
    }
  }

  /// 连接错误的回调
  void _onConnectionError(dynamic error) {
    Get.log('❌ WebSocket连接错误: $error');

    _socketStatus.value = SocketStatus.failed;

    // 触发错误回调
    if (error is WebSocketChannelException) {
      onError?.call(error.message);
    } else {
      onError?.call(error.toString());
    }

    // 关闭连接并重连
    _closeConnection(manual: false);
    _scheduleReconnect();
  }

  // ==================== 心跳机制 ====================

  /// 启动心跳
  void _startHeartbeat() {
    // 先停止旧的心跳
    _stopHeartbeat();

    // 启动新的心跳定时器
    _heartBeatTimer = Timer.periodic(
      Duration(milliseconds: _heartbeatInterval),
      (_) => _sendHeartbeat(),
    );

    Get.log('💓 心跳已启动，间隔: ${_heartbeatInterval}ms');
  }

  /// 发送心跳消息
  void _sendHeartbeat() {
    if (!isConnected) {
      Get.log('⚠️ 连接未建立，跳过心跳');
      return;
    }

    try {
      final token = Get.find<UserController>().token.value;

      if (serializationType == SerializationType.protobuf) {
        // Protobuf 序列化心跳
        final heartbeatMessage = IMConnectMessage(
          code: 1001,
          token: token,
          message: 'heartbeat',
        );
        sendMessage(heartbeatMessage.writeToBuffer());
      } else {
        // JSON 序列化心跳
        final heartbeatMessage = {
          'code': 1001,
          'token': token,
          'data': 'heartbeat',
        };
        sendMessage(jsonEncode(heartbeatMessage));
      }

      // Get.log('💓 心跳已发送');
    } catch (e) {
      Get.log('❌ 发送心跳失败: $e');
    }
  }

  /// 停止心跳
  void _stopHeartbeat() {
    if (_heartBeatTimer != null) {
      _heartBeatTimer!.cancel();
      _heartBeatTimer = null;
      Get.log('💔 心跳已停止');
    }
  }

  // ==================== 消息发送 ====================

  /// 发送WebSocket消息
  ///
  /// [message] 要发送的消息（支持String、List<int>、Uint8List）
  void sendMessage(dynamic message) {
    if (!isConnected) {
      Get.log('⚠️ WebSocket未连接，无法发送消息');
      return;
    }

    try {
      _webSocket?.sink.add(message);
      // Get.log('📤 消息已发送');
    } catch (e) {
      Get.log('❌ 发送消息失败: $e');
      _socketStatus.value = SocketStatus.failed;
    }
  }

  /// 注册WebSocket连接
  ///
  /// [token] 认证令牌
  void register(String token) {
    if (!isConnected) {
      Get.log('⚠️ WebSocket未连接，无法注册');
      return;
    }

    try {
      if (serializationType == SerializationType.protobuf) {
        // Protobuf 序列化注册消息
        final registerMessage = IMConnectMessage(
          code: 1000,
          token: token,
          message: 'registrar',
          deviceType: AppConfig.deviceType,
        );
        sendMessage(registerMessage.writeToBuffer());
      } else {
        // JSON 序列化注册消息
        final registerMessage = {
          'code': 1000,
          'token': token,
          'data': 'registrar',
          'deviceType': AppConfig.deviceType,
        };
        sendMessage(jsonEncode(registerMessage));
      }

      Get.log('📝 注册消息已发送');

      // 注册成功后启动心跳
      _startHeartbeat();
    } catch (e) {
      Get.log('❌ 发送注册消息失败: $e');
    }
  }

  // ==================== 重连机制 ====================

  /// 调度重连（使用指数退避算法）
  void _scheduleReconnect() {
    // 手动关闭不重连
    if (_isManualClose) {
      Get.log('✋ 手动关闭，不进行重连');
      return;
    }

    // 达到最大重连次数
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      Get.log('❌ 已达到最大重连次数($_maxReconnectAttempts)，停止重连');
      _socketStatus.value = SocketStatus.failed;
      _cancelReconnectTimer();
      return;
    }

    // 取消已有的重连定时器
    _cancelReconnectTimer();

    // 计算延迟时间（指数退避：2s, 4s, 8s, 16s, ...）
    final delay = _reconnectBaseDelay * (1 << _reconnectAttempts);
    final maxDelay = 60; // 最大延迟60秒
    final actualDelay = delay > maxDelay ? maxDelay : delay;

    _reconnectAttempts++;
    _socketStatus.value = SocketStatus.reconnecting;

    Get.log('🔄 计划在 ${actualDelay}秒 后进行第 $_reconnectAttempts 次重连');

    // 设置重连定时器
    _reconnectTimer = Timer(Duration(seconds: actualDelay), () {
      Get.log('🔄 开始第 $_reconnectAttempts 次重连...');
      _connect();
    });
  }

  /// 取消重连定时器
  void _cancelReconnectTimer() {
    if (_reconnectTimer != null) {
      _reconnectTimer!.cancel();
      _reconnectTimer = null;
    }
  }

  // ==================== 连接关闭 ====================

  /// 关闭WebSocket连接
  ///
  /// [manual] 是否为手动关闭（手动关闭不会触发重连）
  void closeSocket({bool manual = true}) {
    _isManualClose = manual;
    _closeConnection(manual: manual);

    if (manual) {
      Get.log('✅ WebSocket已手动关闭');
    }
  }

  /// 内部关闭连接方法
  void _closeConnection({required bool manual}) {
    // 停止心跳
    _stopHeartbeat();

    // 取消重连
    if (manual) {
      _cancelReconnectTimer();
    }

    // 取消流订阅
    _streamSubscription?.cancel();
    _streamSubscription = null;

    // 关闭WebSocket连接
    try {
      _webSocket?.sink.close();
    } catch (e) {
      Get.log('⚠️ 关闭WebSocket时出错: $e');
    }

    _webSocket = null;
    _isConnecting = false;

    if (manual) {
      _socketStatus.value = SocketStatus.closed;
    }
  }

  /// 清理所有资源
  void _cleanup() {
    Get.log('🧹 清理WebSocket服务资源');
    _closeConnection(manual: true);
    _reconnectAttempts = 0;
    _requestUrl = null;
  }
}
