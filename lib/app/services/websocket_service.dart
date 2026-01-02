import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../config/app_config.dart';
import '../../proto/im_connect.pb.dart';
import '../../proto/im_connect_json.dart';
import '../controller/user_controller.dart';

/// WebSocket状态
enum SocketStatus {
  socketStatusConnected, // 已连接
  socketStatusFailed, // 失败
  socketStatusClosed, // 连接关闭
}

/// 序列化类型
enum SerializationType { json, protobuf }

class WebSocketService extends GetxService {
  /// 单例对象
  static WebSocketService get to => Get.find();

  /// 使用 Rx 变量来跟踪状态
  final Rx<SocketStatus?> _socketStatus = Rx<SocketStatus?>(null);
  late WebSocketChannel _webSocket; // WebSocket
  Timer? _heartBeat; // 心跳定时器
  final int _heartTimes = 20000; // 心跳间隔(毫秒)
  final int _reconnectCount = 10; // 重连次数，默认10次
  int _reconnectTimes = 0; // 重连计数器
  Timer? _reconnectTimer; // 重连定时器

  // 序列化类型，默认为JSON
  SerializationType serializationType = AppConfig.protocolType == "proto"
      ? SerializationType.protobuf
      : SerializationType.json;

  // 使用 RxString 来存储最新消息
  final RxString latestMessage = ''.obs;
  Uri? requestUrl; // 修改为可空类型

  // 定义回调函数
  Function? onOpen;
  Function? onMessage;
  Function? onError;

  /// 初始化服务
  Future<WebSocketService> init() async {
    return this;
  }

  /// 初始化WebSocket
  void initWebSocket(
      {Function? onOpen,
      Function? onMessage,
      Function? onError,
      String? uid,
      String? token,
      SerializationType? serializationType}) {
    this.serializationType = serializationType ??
        (AppConfig.protocolType == "proto"
            ? SerializationType.protobuf
            : SerializationType.json);
    this.onOpen = onOpen;
    this.onMessage = onMessage;
    this.onError = onError;
    openSocket(uid: uid, token: token);
  }

  /// 开启WebSocket连接
  void openSocket({String? uid, String? token}) {
    Uri? url;
    if (uid != null && uid.isNotEmpty && token != null && token.isNotEmpty) {
      url = Uri.parse(AppConfig.wsServer).replace(queryParameters: {
        "uid": uid,
        "token": token,
      });
    }

    // 只有在 URL 有效且发生变化时才更新 requestUrl
    if (url != null && requestUrl != url) {
      requestUrl = url;
      Get.log('WebSocket 连接 URL: $requestUrl');
    }

    // 如果没有有效的 URL，则不进行连接
    if (requestUrl == null) {
      Get.log('WebSocket连接失败: 无效的连接URL');
      return;
    }

    try {
      _webSocket = WebSocketChannel.connect(
        requestUrl!,
      );
      Get.log('WebSocket连接成功: ${AppConfig.wsServer}');

      _socketStatus.value = SocketStatus.socketStatusConnected;
      _reconnectTimes = 0;

      if (_reconnectTimer != null) {
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
      }

      onOpen?.call();

      // 接收消息
      _webSocket.stream.listen((data) => webSocketOnMessage(data),
          onError: webSocketOnError, onDone: webSocketOnDone);
    } catch (e) {
      Get.log('WebSocket连接异常: $e');
      _socketStatus.value = SocketStatus.socketStatusFailed;
      reconnect();
    }
  }

  /// WebSocket接收消息回调
  webSocketOnMessage(data) {
    if (serializationType == SerializationType.protobuf) {
      // Protobuf 模式，处理二进制数据
      try {
        if (data is Uint8List) {
          IMConnectMessage im_message = IMConnectMessage.fromBuffer(data);
          latestMessage.value = jsonEncode(im_message.toJson());
          onMessage?.call(latestMessage.value);
        } else if (data is List<int>) {
          final message = IMConnectMessage.fromBuffer(Uint8List.fromList(data));
          latestMessage.value = message.toString();
          onMessage?.call(message);
        } else {
          Get.log('Protobuf模式下收到非二进制数据: ${data.runtimeType}');
          latestMessage.value = data.toString();
          onMessage?.call(data);
        }
      } catch (e) {
        Get.log('Protobuf消息解析失败: $e');
      }
    } else {
      // JSON 模式，处理文本数据
      try {
        String textData;
        if (data is String) {
          textData = data;
        } else if (data is List<int>) {
          textData = utf8.decode(data);
        } else if (data is Uint8List) {
          textData = utf8.decode(data);
        } else {
          Get.log('JSON模式下收到未知类型数据: ${data.runtimeType}');
          latestMessage.value = data.toString();
          onMessage?.call(data);
          return;
        }

        final jsonData = jsonDecode(textData);
        latestMessage.value = textData;
        onMessage?.call(jsonData);
      } catch (e) {
        Get.log('JSON消息解析失败: $e');
      }
    }
  }

  /// WebSocket关闭连接回调
  webSocketOnDone() {
    Get.log('webSocketOnDone closed');
    _socketStatus.value = SocketStatus.socketStatusClosed;
    reconnect();
  }

  /// WebSocket连接错误回调
  webSocketOnError(e) {
    WebSocketChannelException ex = e;
    _socketStatus.value = SocketStatus.socketStatusFailed;
    onError?.call(ex.message);
    closeSocket();
  }

  /// 初始化心跳
  void initHeartBeat() {
    destroyHeartBeat();
    _heartBeat = Timer.periodic(Duration(milliseconds: _heartTimes), (timer) {
      sentHeart();
    });
  }

  /// 心跳
  void sentHeart() {
    final token = Get.find<UserController>().token.value;

    if (serializationType == SerializationType.protobuf) {
      // 使用 Protobuf 序列化
      final heartbeatMessage =
          IMConnectMessage(code: 1001, token: token, message: 'heartbeat');
      sendMessage(heartbeatMessage.writeToBuffer());
    } else {
      // 使用 JSON 序列化
      final heartbeatMessage = {
        'code': 1001,
        'token': token,
        'data': 'heartbeat'
      };
      sendMessage(jsonEncode(heartbeatMessage));
    }
  }

  /// 销毁心跳
  void destroyHeartBeat() {
    if (_heartBeat != null) {
      _heartBeat?.cancel();
      _heartBeat = null;
    }
  }

  /// 关闭WebSocket
  void closeSocket() {
    if (_socketStatus.value == SocketStatus.socketStatusConnected) {
      Get.log('WebSocket连接关闭');
      _webSocket.sink.close();
      destroyHeartBeat();
      _socketStatus.value = SocketStatus.socketStatusClosed;
    }
  }

  /// 发送WebSocket消息
  void sendMessage(message) {
    switch (_socketStatus.value) {
      case SocketStatus.socketStatusConnected:

        ///Get.log('发送中：$message');
        _webSocket.sink.add(message);
        break;
      case SocketStatus.socketStatusClosed:
        Get.log('连接已关闭');
        break;
      case SocketStatus.socketStatusFailed:
        Get.log('发送失败');
        break;
      default:
        break;
    }
  }

  /// 重连机制
  void reconnect() {
    if (_reconnectTimes < _reconnectCount) {
      _reconnectTimes++;
      _reconnectTimer =
          Timer.periodic(Duration(milliseconds: _heartTimes), (timer) {
        openSocket();
      });
    } else {
      if (_reconnectTimer != null) {
        Get.log('重连次数超过最大次数');
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
      }
      return;
    }
  }

  /// 关闭WebSocket
  @override
  void onClose() {
    closeSocket();
    super.onClose();
  }

  // Getters
  SocketStatus? get socketStatus => _socketStatus.value;

  Stream<SocketStatus?> get socketStatusStream => _socketStatus.stream;

  get webSocketCloseCode => _webSocket.closeCode;

  /// 注册 WebSocket 连接
  void register(String token) {
    if (serializationType == SerializationType.protobuf) {
      // 使用 Protobuf 序列化
      final registerMessage = IMConnectMessage(
          code: 1000,
          token: token,
          message: 'registrar',
          deviceType: AppConfig.deviceType);
      sendMessage(registerMessage.writeToBuffer());
    } else {
      // 使用 JSON 序列化
      final registerMessage = {
        'code': 1000,
        'token': token,
        'data': 'registrar',
        'deviceType': AppConfig.deviceType
      };
      sendMessage(jsonEncode(registerMessage));
    }

    // 注册成功后启动心跳
    initHeartBeat();
  }

  // 添加一个getter来判断是否连接
  bool get isConnected =>
      _socketStatus.value == SocketStatus.socketStatusConnected;
}
