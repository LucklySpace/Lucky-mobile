import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../constants/app_message.dart';
import '../../utils/objects.dart';
import '../../utils/rsa.dart';
import '../api/api_service.dart';
import '../core/handlers/error_handler.dart';
import 'package:flutter_im/exceptions/app_exception.dart';
import '../models/User.dart';
import '../models/message_receive.dart';
import '../services/websocket_service.dart';
import 'chat_controller.dart';
import 'contact_controller.dart';

/// 用户控制器：管理用户认证、存储、WebSocket 连接
class UserController extends GetxController with WidgetsBindingObserver {
  // 单例访问
  static UserController get to => Get.find();

  // ---------- 常量定义（配置/固定值） ----------
  static const _keyUserId = 'userId';
  static const _keyToken = 'token';
  static const _successCode = 200;
  static const _qrAuthorizedCode = 'AUTHORIZED';
  static const _reconnectBaseDelay = Duration(seconds: 2);
  static const _maxReconnectAttempts = 6;

  // ---------- 依赖注入（外部服务/控制器） ----------
  // 这些依赖通过 Get.find 注入，注意不要在 Binding 时触发循环依赖
  final _storage = GetStorage();
  final _secureStorage = const FlutterSecureStorage();
  final _apiService = Get.find<ApiService>();
  final _wsService = Get.find<WebSocketService>();
  late final ChatController _chatController;
  late final ContactController _contactController;

  // ---------- 响应式状态（用于界面/其他模块监听） ----------
  final RxString userId = ''.obs; // 用户 ID（持久化到 GetStorage）
  final RxString token = ''.obs; // 认证令牌（持久化到 FlutterSecureStorage）
  final RxMap<String, dynamic> userInfo = <String, dynamic>{}.obs; // 用户信息

  // ---------- 非响应式字段（内部状态、计时器等） ----------
  String publicKey = ''; // RSA 公钥（用于登录加密）
  bool _gettingPublicKey = false; // 获取公钥的标志位，防止重复请求
  bool _connecting = false; // websocket 连接中标志
  bool _reconnectLock = false; // 重连锁
  int _reconnectAttempts = 0; // 重连尝试次数（用于指数退避）
  Timer? _reconnectTimer; // 重连定时器

  final RxBool isEditing = false.obs; // 额外状态示例，供界面使用

  // ---------- 生命周期（onInit/onClose 等） ----------
  @override
  void onInit() {
    super.onInit();

    // 启动时加载本地持久化数据，并设置响应式监听器
    _loadStoredData();
    _setupListeners();

    _chatController = Get.find<ChatController>();
    _contactController = Get.find<ContactController>();

    // 观察应用生命周期（前后台切换）
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _reconnectTimer?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 根据应用生命周期采取相应操作（如断开/重连 websocket、清理当前会话等）
    switch (state) {
      case AppLifecycleState.inactive:
        Get.log('📌 应用进入非活动状态');
        break;
      case AppLifecycleState.paused:
        Get.log('⏸️ 应用进入后台');
        // 进入后台时清理当前会话（以避免后台占用资源）
        _chatController.currentChat.value = null;
        break;
      case AppLifecycleState.resumed:
        Get.log('✅ 应用恢复到前台');
        // 恢复时尝试重连 websocket
        reconnectWebSocket();
        break;
      case AppLifecycleState.detached:
        Get.log('🔌 应用 UI 已分离');
        break;
      case AppLifecycleState.hidden:
        Get.log('👻 应用已隐藏');
        break;
    }
  }

  // ====================== 认证（登录/登出） ======================

  /// 用户登录（加密密码并调用 API），成功后会触发 startConnect()
  Future<bool> login(String username, String password, String authType) async {
    try {
      await logout(); // 先清理旧状态
      await _ensurePublicKey();

      final encryptedPassword = await RSAService.encrypt(password, publicKey);
      Get.log('🔑 加密后的密码（已隐藏）');

      final loginData = {
        'principal': username,
        'credentials': encryptedPassword,
        'authType': authType,
      };

      final response = await _apiService.login(loginData);
      return _handleApiResponse(response, onSuccess: (data) {
        if (Objects.isNotBlank(Objects.safeGet<String>(data, 'accessToken')) &&
            Objects.isNotBlank(Objects.safeGet<String>(data, 'userId'))) {
          token.value = Objects.safeGet<String>(data, 'accessToken') ?? '';
          userId.value = Objects.safeGet<String>(data, 'userId') ?? '';
          startConnect();
          return true;
        }
        return false;
      }, errorMessage: '登录失败');
    } catch (e, st) {
      _showError('登录异常', silent: false);
      return false;
    }
  }

  /// 登出：关闭 websocket，清除本地认证信息与内存状态
  Future<void> logout() async {
    try {
      _wsService.closeSocket();
      token.value = '';
      userId.value = '';
      userInfo.value = {};
      await _secureStorage.delete(key: _keyToken);
      await _storage.remove(_keyUserId);
    } catch (e) {
      _showError('登出失败: $e');
    }
  }

  /// 登录成功后启动的一系列初始化流程（按顺序更新用户数据与连接）
  Future<void> startConnect() async {
    // 获取用户信息
    await getUserInfo();
    // 连接 WebSocket
    connectWebSocket();
    // 并行获取各类数据以加快启动速度
    await Future.wait([
      _contactController.fetchContacts(),
      _contactController.fetchFriendRequests(),
      _chatController.fetchChats(),
    ]);
    // 获取消息（会读取本地或远端）
    _chatController.fetchMessages();
  }

  // ====================== WebSocket 管理 ======================

  /// 建立 websocket 连接（ok 时会 register）
  void connectWebSocket() {
    if (token.value.isEmpty || userId.value.isEmpty) return;

    if (_wsService.isConnected) {
      Get.log('WebSocket 已连接，跳过 connect');
      return;
    }

    if (_connecting) {
      Get.log('正在连接中，跳过重复连接');
      return;
    }

    _connecting = true;
    try {
      _wsService.initWebSocket(
        onOpen: () {
          Get.log('WebSocket 连接成功，开始注册');
          _wsService.register(token.value);
          _connecting = false;
          _reconnectAttempts = 0;
        },
        onMessage: _handleWebSocketMessage,
        onError: (error) {
          _showError('WebSocket 错误: $error');
          _connecting = false;
        },
        uid: userId.value,
        token: token.value,
      );
    } catch (e, st) {
      _connecting = false;
      _showError('connectWebSocket 发生异常: $e\n$st');
      // 触发重连策略
      reconnectWebSocket();
    }
  }

  /// 重连逻辑：采用指数退避并且使用锁避免重复重连
  Future<void> reconnectWebSocket() async {
    if (_reconnectLock) {
      Get.log('重连已在排队/进行中，跳过重复请求');
      return;
    }
    _reconnectLock = true;

    // 取消已有定时器（如果存在）
    _reconnectTimer?.cancel();

    // 指数退避（2s, 4s, 8s, ...，受 _maxReconnectAttempts 限制）
    final attempts = _reconnectAttempts.clamp(0, _maxReconnectAttempts);
    final delay = _reconnectBaseDelay * (1 << attempts); // 2s,4s,8s...
    _reconnectAttempts++;

    Get.log(
        '尝试重连 WebSocket，第 $_reconnectAttempts 次，将在 ${delay.inSeconds}s 后尝试');

    _reconnectTimer = Timer(delay, () async {
      try {
        connectWebSocket();
        await _chatController.fetchMessages();
      } catch (e, st) {
        _showError('重连尝试失败: $e\n$st');
      } finally {
        // 允许下一次重连（如果仍然需要）
        _reconnectLock = false;
      }
    });
  }

  /// WebSocket 原始消息处理器（入口）
  void _handleWebSocketMessage(dynamic rawData) {
    try {
      final message = _safeDecodeJson(rawData);
      if (message == null) {
        _showError('无法解析的 WebSocket 消息: $rawData');
        return;
      }

      final code = message['code'] ?? 1;
      final contentType = IMessageType.fromCode(code);

      switch (contentType) {
        case IMessageType.login:
          Get.log('WebSocket 注册响应: $message');
          break;
        case IMessageType.heartBeat:
          Get.log('WebSocket 心跳响应: $message');
          break;
        case IMessageType.singleMessage:
        case IMessageType.groupMessage:
          _processChatMessage(message['data']);
          break;
        case IMessageType.videoMessage:
          _processVideoMessage(message['data']);
          break;
        default:
          Get.log('未知的 WebSocket 消息类型: $code');
      }
    } catch (e, st) {
      _showError('处理 WebSocket 消息出错: $e\n$st');
    }
  }

  /// 处理普通的单聊/群聊消息（解包 -> 更新会话 -> 日志）
  void _processChatMessage(dynamic data) {
    try {
      if (data == null) {
        _showError('_processChatMessage: data 为 null');
        return;
      }
      final IMessage parsedMessage = IMessage.fromJson(data);
      final String? chatId = _deriveChatIdFromMessage(parsedMessage);
      if (chatId == null) {
        _showError('无法从消息推断 chatId: ${parsedMessage.toJson()}');
        return;
      }

      _chatController.handleCreateOrUpdateChat(parsedMessage, chatId, false);
      Get.log(
          'WebSocket ${parsedMessage.messageType == IMessageType.singleMessage.code ? '单聊' : '群聊'}消息接收: ${parsedMessage.messageId ?? 'unknown id'}');
    } catch (e, st) {
      _showError('_processChatMessage 异常: $e\n$st');
    }
  }

  /// 处理视频通话类消息
  void _processVideoMessage(dynamic data) {
    try {
      if (data == null) {
        _showError('_processVideoMessage: data 为 null');
        return;
      }
      final parsedMessage = MessageVideoCallDto.fromJson(data);
      _chatController.handleCallMessage(parsedMessage);
      Get.log('WebSocket 视频消息接收: ${parsedMessage.fromId ?? 'unknown'}');
    } catch (e, st) {
      _showError('_processVideoMessage 异常: $e\n$st');
    }
  }

  /// 从 IMessage 推断 chatId（single => 对端 id，group => groupId）
  String? _deriveChatIdFromMessage(IMessage parsedMessage) {
    try {
      if (parsedMessage.messageType == IMessageType.singleMessage.code) {
        // single message: chatId 是另一方的 id（如果当前为发送方取 toId，否则取 fromId）
        final single = IMessage.toSingleMessage(parsedMessage, userId.value);
        if (single == null) return null;
        return single.fromId == userId.value
            ? parsedMessage.toId
            : parsedMessage.fromId;
      } else if (parsedMessage.messageType == IMessageType.groupMessage.code) {
        final group = IMessage.toGroupMessage(parsedMessage, userId.value);
        return group?.groupId;
      }
      return null;
    } catch (e) {
      _showError('推断 chatId 失败: $e');
      return null;
    }
  }

  // ====================== 与后端 API 交互的方法 ======================

  /// 发送短信验证码（示例）
  Future<void> sendVerificationCode(String phone) async {
    try {
      final response = await _apiService.sendSms({'phone': phone});
      _handleApiResponse(response, onSuccess: (_) {}, errorMessage: '发送验证码失败');
    } catch (e, st) {
      _showError('发送验证码失败: $e\n$st');
      rethrow;
    }
  }

  /// 获取公钥：包含重复请求保护（_gettingPublicKey）
  Future<void> _ensurePublicKey() async {
    if (publicKey.isNotEmpty) return;
    if (_gettingPublicKey) {
      // 等待已有请求完成（最多等待 5s，避免无限等待）
      var waited = 0;
      while (_gettingPublicKey && waited < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        waited++;
      }
      return;
    }
    await getPublicKey();
  }

  /// 请求公钥接口（设置 publicKey）
  Future<void> getPublicKey() async {
    if (_gettingPublicKey) return;
    _gettingPublicKey = true;
    try {
      final response = await _apiService.getPublicKey();
      _handleApiResponse(response, onSuccess: (data) {
        publicKey = Objects.safeGet<String>(data, 'publicKey') ?? '';
        Get.log('✅ 获取公钥成功: ${publicKey.isNotEmpty ? '[RECEIVED]' : '[EMPTY]'}');
      }, errorMessage: '获取公钥失败');
    } catch (e, st) {
      _showError('获取公钥失败: $e\n$st');
    } finally {
      _gettingPublicKey = false;
    }
  }

  /// 上传图片（使用 dio 的 FormData）
  Future<String?> uploadImage(File? img) async {
    try {
      if (img == null) {
        Get.log('图片为空');
        return null;
      }

      Get.log('图片大小: ${img.lengthSync()}');
      Get.log('图片格式: ${img.path.split('.').last}');
      Get.log('图片路径: ${img.path}');
      Get.log('图片名称: ${img.path.split('/').last}');

      // 使用 dio 的 FormData
      final formData = dio.FormData.fromMap({
        "file": await dio.MultipartFile.fromFile(img.path,
            filename: img.path.split('/').last),
      });

      final response = await _apiService.uploadImage(formData);
      return response?['path'] as String?;
    } catch (e, st) {
      _showError('上传图片失败: $e\n$st');
      rethrow;
    }
  }

  /// 更新用户信息并刷新本地 userInfo
  Future<void> updateUserInfo(User user) async {
    try {
      final response = await _apiService.updateUserInfo(user.toJson());
      _handleApiResponse(response, onSuccess: (data) {
        Get.log('✅ 更新用户信息成功');
        getUserInfo();
        Get.snackbar('成功', '资料已更新', snackPosition: SnackPosition.TOP);
      }, errorMessage: '更新用户信息失败');
    } catch (e, st) {
      _showError('更新用户信息失败: $e\n$st');
      rethrow;
    }
  }

  /// 获取用户信息并写入 userInfo（调用方可观察 userInfo 变更）
  Future<void> getUserInfo() async {
    try {
      final response = await _apiService.getUserInfo({'userId': userId.value});
      _handleApiResponse(response, onSuccess: (data) {
        userInfo.value = data;
        Get.log('✅ 获取用户信息成功');
      }, errorMessage: '获取用户信息失败');
    } catch (e, st) {
      _showError('获取用户信息失败: $e\n$st');
      rethrow;
    }
  }

  /// 扫描二维码并判断是否授权
  Future<bool> scanQrCode(String qrCodeContent) async {
    try {
      final response = await _apiService.scanQRCode({
        'qrCode': qrCodeContent,
        'userId': userId.value,
      });
      return _handleApiResponse(response, onSuccess: (data) {
        return Objects.safeGet<String>(data, 'status') == _qrAuthorizedCode;
      }, errorMessage: '扫描二维码失败');
    } catch (e, st) {
      _showError('扫描二维码异常', silent: false);
      return false;
    }
  }

  // ====================== 数据持久化相关方法 ======================

  /// 从本地存储加载 token 与 userId （启动时调用）
  Future<void> _loadStoredData() async {
    try {
      final storedToken = await _secureStorage.read(key: _keyToken);
      final storedUserId = _storage.read(_keyUserId);

      if (storedToken != null && storedToken.isNotEmpty)
        token.value = storedToken;
      if (storedUserId != null && storedUserId.toString().isNotEmpty) {
        userId.value = storedUserId.toString();
      }
    } catch (e, st) {
      _showError('加载存储数据失败: $e\n$st');
    }
  }

  /// 保存 userId 到本地（同步方法）
  void _saveUserId() {
    try {
      if (userId.value.isEmpty) {
        _storage.remove(_keyUserId);
      } else {
        _storage.write(_keyUserId, userId.value);
      }
    } catch (e) {
      _showError('保存 userId 失败: $e');
    }
  }

  /// 保存 token 到安全存储（异步）
  Future<void> _saveToken() async {
    try {
      if (token.value.isEmpty) {
        await _secureStorage.delete(key: _keyToken);
      } else {
        await _secureStorage.write(key: _keyToken, value: token.value);
      }
    } catch (e) {
      _showError('保存令牌失败: $e');
    }
  }

  /// 设置响应式监听器：token 变更触发保存与鉴权检查；userId 变更触发保存
  void _setupListeners() {
    // 当 token 变化时，既保存也检查认证状态
    ever(token, (_) {
      _onTokenChanged();
    });

    // 保存 userId
    ever(userId, (_) => _saveUserId());
  }

  /// token 变更的处理器：保存并检测认证
  Future<void> _onTokenChanged() async {
    try {
      await _saveToken();
      _checkAuth();
    } catch (e) {
      _showError('处理 token 变更失败: $e');
    }
  }

  /// 简单检查认证状态（可扩展为主动验证 token）
  void _checkAuth() {
    if (token.value.isEmpty) {
      Get.log('用户未认证');
    } else {
      Get.log('用户已认证');
    }
  }

  // ====================== 辅助方法（通用工具/解析/日志） ======================

  /// 统一处理 API 返回值（成功调用 onSuccess，否则抛异常）
  T _handleApiResponse<T>(
    Map<String, dynamic>? response, {
    required T Function(dynamic) onSuccess,
    required String errorMessage,
  }) {
    // 使用工具类安全获取字段，避免空指针
    final code = Objects.safeGet<int>(response, 'code');
    if (code == _successCode) {
      return onSuccess(response?['data']);
    }
    final msg = Objects.safeGet<String>(response, 'message', errorMessage);
    throw BusinessException(msg.toString());
  }

  /// 安全解析 JSON（支持 raw String / Map / 其它），解析失败返回 null
  Map<String, dynamic>? _safeDecodeJson(dynamic raw) {
    try {
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        // 如果不是 map，尝试转换
        return Map<String, dynamic>.from(decoded as Map);
      } else if (raw is Map<String, dynamic>) {
        return raw;
      } else if (raw != null) {
        return Map<String, dynamic>.from(raw as Map);
      }
    } catch (e) {
      _showError('JSON 解析失败: $e -- 原始: $raw');
    }
    return null;
  }

  /// 显示错误提示
  void _showError(dynamic error, {bool silent = false}) {
    ErrorHandler.handle(error, silent: silent);
  }
}
