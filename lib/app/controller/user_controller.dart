import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_im/exceptions/app_exception.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../constants/app_message.dart';
import '../../routes/app_routes.dart';
import '../../utils/rsa.dart';
import '../core/base/base_controller.dart';
import '../core/handlers/error_handler.dart';
import '../models/message_receive.dart';
import '../models/user.dart';
import '../services/websocket_service.dart';
import 'chat_controller.dart';
import 'contact_controller.dart';

/// 用户控制器：管理用户认证、存储、WebSocket 连接
class UserController extends BaseController with WidgetsBindingObserver {
  // 单例访问
  static UserController get to => Get.find();

  // ---------- 常量定义（配置/固定值） ----------
  static const _keyUserId = 'userId';
  static const _keyToken = 'token';

  // ---------- 依赖注入（外部服务/控制器） ----------
  final _storage = GetStorage();
  final _secureStorage = const FlutterSecureStorage();
  final _wsService = Get.find<WebSocketService>();
  late final ChatController _chatController;
  late final ContactController _contactController;

  // ---------- 响应式状态（用于界面/其他模块监听） ----------
  final RxString userId = ''.obs; // 用户 ID
  final RxString token = ''.obs; // 认证令牌
  final Rxn<User> userInfo = Rxn<User>(); // 用户详细信息
  final RxBool isAppInBackground = false.obs; // 应用是否在后台

  // ---------- 非响应式字段 ----------
  String publicKey = ''; // RSA 公钥
  bool _gettingPublicKey = false;
  bool _connecting = false;
  StreamSubscription? _statusSubscription; // WebSocket 状态订阅

  final RxBool isEditing = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadStoredData();
    _setupListeners();
    _setupStatusListener();
    _chatController = Get.find<ChatController>();
    _contactController = Get.find<ContactController>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusSubscription?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Get.log('📱 AppLifecycleState 变更: $state');
    switch (state) {
      case AppLifecycleState.resumed:
        isAppInBackground.value = false;
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        isAppInBackground.value = true;
        _handleAppPaused();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.detached:
        break;
      default:
        break;
    }
  }

  void _handleAppResumed() {
    // 回到前台，检查并恢复连接
    if (token.isNotEmpty && userId.isNotEmpty) {
      if (_wsService.isConnected) {
        // 已连接状态下，主动同步一次消息，确保万无一失
        _chatController.fetchMessages();
      } else {
        // 断连状态下，立即重新初始化
        connectWebSocket();
      }
    }
  }

  void _handleAppPaused() {
    // 进入后台，清理非必要状态
    _chatController.currentChat.value = null;
  }

  // ====================== 认证（登录/登出） ======================

  Future<bool> login(String username, String password, String authType) async {
    try {
      Get.log('🔐 开始登录流程...');
      await logout();
      await _ensurePublicKey();

      if (publicKey.isEmpty) {
        throw AuthException('获取加密公钥失败，请重试');
      }

      final encryptedPassword = await RSAService.encrypt(password, publicKey);

      final response = await apiService.login({
        'principal': username,
        'credentials': encryptedPassword,
        'authType': authType,
      });

      bool success = false;
      handleApiResponse(response, onSuccess: (data) {
        token.value = data.accessToken;
        userId.value = data.userId;
        Get.log('✅ 登录成功，用户ID: ${data.userId}');
        startConnect();
        success = true;
      }, onError: (code, message) {
        Get.log('❌ 登录失败: [$code] $message');
      });
      return success;
    } on AuthException {
      rethrow;
    } catch (e) {
      Get.log('❌ 登录异常: $e');
      _showError(AuthException('登录失败，请稍后重试', details: e));
      return false;
    }
  }

  Future<void> logout() async {
    try {
      _wsService.closeSocket();
      token.value = '';
      userId.value = '';
      userInfo.value = null;
      await _secureStorage.delete(key: _keyToken);
      await _storage.remove(_keyUserId);
    } catch (e) {
      _showError('登出失败: $e');
    }
  }

  Future<void> startConnect() async {
    try {
      await getUserInfo();
      connectWebSocket();
      await Future.wait([
        _contactController.fetchContacts(),
        _contactController.fetchFriendRequests(),
        _chatController.fetchChats(),
      ], eagerError: false);
      _chatController.fetchMessages();
    } catch (e) {
      _showError('初始化失败，部分功能可能不可用', silent: true);
    }
  }

  // ====================== WebSocket 管理 ======================

  /// 初始化并建立 WebSocket 连接
  void connectWebSocket() {
    if (token.value.isEmpty || userId.value.isEmpty) return;
    // 如果已经连接或正在连接，跳过
    if (_wsService.isConnected || _connecting) return;

    _connecting = true;
    try {
      _wsService.initWebSocket(
        onOpen: () {
          Get.log('🔗 WebSocket 握手成功，开始注册设备...');
          _wsService.register(token.value);
          _connecting = false;
        },
        onMessage: _handleWebSocketMessage,
        onError: (error) {
          Get.log('❌ WebSocket 错误: $error');
          _connecting = false;
          // 这里的重连交由 WebSocketService 内部的指数退避机制处理
        },
        uid: userId.value,
        token: token.value,
      );
    } catch (e) {
      Get.log('❌ WebSocket 初始化异常: $e');
      _connecting = false;
    }
  }

  /// 监听 WebSocket 状态变更
  void _setupStatusListener() {
    // 监听连接状态，实现自动同步逻辑
    _statusSubscription = _wsService.socketStatusStream.listen((status) {
      Get.log('📡 WebSocket 状态变更: $status');
      if (status == SocketStatus.connected) {
        // 关键逻辑：连接成功（无论是首次还是重连）后立即拉取消息
        // 这是实现“保活/消息同步”的核心
        _chatController.fetchMessages();
      }
    });
  }

  void _handleWebSocketMessage(dynamic rawData) {
    try {
      final message = _safeDecodeJson(rawData);
      if (message == null) return;

      final code = message['code'] ?? 1;
      final contentType = MessageType.fromCode(code);

      switch (contentType) {
        case MessageType.singleMessage:
        case MessageType.groupMessage:
          _processChatMessage(message['data']);
          break;
        case MessageType.videoMessage:
          _processVideoMessage(message['data']);
          break;
        case MessageType.forceLogout:
          _processToLogin();
        case MessageType.refreshToken:
          _processRefreshToken();
        default:
          break;
      }
    } catch (e) {
      _showError('处理 WebSocket 消息出错: $e');
    }
  }

  void _processChatMessage(dynamic data) {
    if (data == null) return;
    final IMessage parsedMessage = IMessage.fromJson(data);
    final String? chatId = _deriveChatIdFromMessage(parsedMessage);
    if (chatId != null) {
      _chatController.handleCreateOrUpdateChat(parsedMessage, chatId, false);
    }
  }

  void _processVideoMessage(dynamic data) {
    if (data == null) return;
    final parsedMessage = MessageVideoCallDto.fromJson(data);
    _chatController.handleCallMessage(parsedMessage);
  }

  String? _deriveChatIdFromMessage(IMessage parsedMessage) {
    if (parsedMessage.messageType == MessageType.singleMessage.code) {
      final single = IMessage.toSingleMessage(parsedMessage, userId.value);
      return single.fromId == userId.value
          ? parsedMessage.toId
          : parsedMessage.fromId;
    } else if (parsedMessage.messageType == MessageType.groupMessage.code) {
      final group = IMessage.toGroupMessage(parsedMessage, userId.value);
      return group.groupId;
    }
    return null;
  }

  // ====================== API 交互 ======================

  Future<void> sendVerificationCode(String phone) async {
    final response =
        await apiService.sendSms({'phone': phone, 'type': 'login'});
    handleApiResponse(response, onSuccess: (data) {
      Get.log('✅ 验证码已发送');
    });
  }

  Future<void> _ensurePublicKey() async {
    if (publicKey.isNotEmpty) return;
    if (_gettingPublicKey) {
      var waited = 0;
      while (_gettingPublicKey && waited < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        waited++;
      }
      return;
    }
    await getPublicKey();
  }

  Future<void> getPublicKey() async {
    if (_gettingPublicKey) return;
    _gettingPublicKey = true;
    try {
      final response = await apiService.getPublicKey();
      handleApiResponse(response, onSuccess: (data) {
        publicKey = data['publicKey'] ?? '';
        Get.log('🔐 获取公钥成功...');
      }, showError: false);
    } finally {
      _gettingPublicKey = false;
    }
  }

  Future<void> updateUserInfo(User user) async {
    final response = await apiService.updateUserInfo(user.toJson());
    handleApiResponse(response, onSuccess: (data) async {
      await getUserInfo();
      showSuccess('资料已更新');
    });
  }

  Future<void> getUserInfo() async {
    final response = await apiService.getUserInfo({'userId': userId.value});
    handleApiResponse(response, onSuccess: (data) {
      userInfo.value = data;
    }, silent: true);
  }

  Future<bool> scanQrCode(String qrCodeContent) async {
    final response = await apiService.scanQRCode({
      'qrCode': qrCodeContent,
      'userId': userId.value,
    });

    bool success = false;
    handleApiResponse(response, onSuccess: (data) {
      success = data.status == 2;
    });
    return success;
  }

  // #TODO
  Future<String> uploadImage(File cropped) async {
    return "";
  }

  // ====================== 数据持久化 ======================

  Future<void> _loadStoredData() async {
    final storedToken = await _secureStorage.read(key: _keyToken);
    final storedUserId = _storage.read(_keyUserId);
    if (storedToken != null) token.value = storedToken;
    if (storedUserId != null) userId.value = storedUserId.toString();
  }

  void _setupListeners() {
    ever(token, (val) async {
      if (val.isEmpty)
        await _secureStorage.delete(key: _keyToken);
      else
        await _secureStorage.write(key: _keyToken, value: val);
    });
    ever(userId, (val) {
      if (val.isEmpty)
        _storage.remove(_keyUserId);
      else
        _storage.write(_keyUserId, val);
    });
  }

  Map<String, dynamic>? _safeDecodeJson(dynamic raw) {
    try {
      if (raw is String) return jsonDecode(raw);
      if (raw is Map<String, dynamic>) return raw;
      return Map<String, dynamic>.from(raw as Map);
    } catch (e) {
      return null;
    }
  }

  void _showError(dynamic error, {bool silent = false}) {
    if (error is String)
      showError(error);
    else
      ErrorHandler.handle(error, silent: silent);
  }

  void _processToLogin() {
    Get.toNamed(Routes.HOME);
  }

  Future<void> _processRefreshToken() async {
    final res = await apiService.refreshToken();
    handleApiResponse(res, onSuccess: (data) {}, onError: (code, message) {});
  }
}
