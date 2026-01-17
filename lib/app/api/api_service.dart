import 'package:dio/dio.dart' as dio;
import 'package:flutter_im/app/controller/user_controller.dart';
import 'package:flutter_im/app/models/models.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

import '../../config/app_config.dart';
import '../../exceptions/app_exception.dart';
import '../../utils/http.dart';

/// **🌐 统一 API 服务**
class ApiService extends GetxService {
  /// 单例访问
  static ApiService get to => Get.find();

  /// HTTP 工具类实例
  late final Http _http;

  /// 当前用户 Token（从 UserController 获取）
  String? get _token => Get.find<UserController>().token.value;

  @override
  void onInit() {
    super.onInit();
    _initHttp();
  }

  /// 初始化 HTTP 配置
  void _initHttp() {
    _http = Http();
    _http.init(HttpConfig(
      baseUrl: AppConfig.apiServer,
      serviceBaseUrls: AppConfig.serviceUrls,
      dynamicHeaderBuilder: () async {
        final headers = <String, String>{};
        final token = _token;
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
        return headers;
      },
      onGlobalError: (message) {
        print('🚨 API错误: $message');
      },
      enableLogging: AppConfig.isDebug,
      ignoreBadCertInDebug: true,
    ));
  }

  // ========================================
  // 🔐 认证相关 API
  // ========================================

  /// 登录
  Future<Result<LoginResponse>> login(Map<String, dynamic> data) {
    return _http.post<LoginResponse>(
      '/auth/login',
      service: 'auth',
      data: data,
      fromJson: (json) => LoginResponse.fromJson(json),
    );
  }

  /// 退出登录
  Future<Result<dynamic>> logout() {
    return _http.post('/auth/logout', service: 'auth');
  }

  /// 刷新 Token
  Future<Result<LoginResponse>> refreshToken() {
    return _http.get<LoginResponse>(
      '/auth/refresh/token',
      service: 'auth',
      fromJson: (json) => LoginResponse.fromJson(json),
    );
  }

  /// 发送短信验证码
  Future<Result<dynamic>> sendSms(Map<String, dynamic> params) {
    return _http.get('/auth/sms', service: 'auth', params: params);
  }

  /// 获取二维码
  Future<Result<QRCodeResponse>> getQRCode(Map<String, dynamic> params) {
    return _http.get<QRCodeResponse>(
      '/auth/qrcode',
      service: 'auth',
      params: params,
      fromJson: (json) => QRCodeResponse.fromJson(json),
    );
  }

  /// 扫码登录
  Future<Result<QRCodeStatusResponse>> scanQRCode(Map<String, dynamic> data) {
    return _http.post<QRCodeStatusResponse>(
      '/auth/qrcode/scan',
      service: 'auth',
      data: data,
      fromJson: (json) => QRCodeStatusResponse.fromJson(json),
    );
  }

  /// 检查二维码状态
  Future<Result<QRCodeStatusResponse>> checkQRCodeStatus(
      Map<String, dynamic> params) {
    return _http.get<QRCodeStatusResponse>(
      '/auth/qrcode/status',
      service: 'auth',
      params: params,
      fromJson: (json) => QRCodeStatusResponse.fromJson(json),
    );
  }

  /// 获取公钥
  Future<Result<Map<String, dynamic>>> getPublicKey() {
    return _http.get<Map<String, dynamic>>('/auth/publickey', service: 'auth');
  }

  /// 获取在线状态
  Future<Result<dynamic>> getOnlineStatus(Map<String, dynamic> params) {
    return _http.get('/auth/online', service: 'auth', params: params);
  }

  /// 获取个人信息
  Future<Result<User>> getUserInfo(Map<String, dynamic> params) {
    return _http.get<User>(
      '/auth/info',
      service: 'auth',
      params: params,
      fromJson: (json) => User.fromJson(json),
    );
  }

  // ========================================
  // 👤 用户 / 好友相关 API
  // ========================================

  /// 更新用户信息
  Future<Result<User>> updateUserInfo(Map<String, dynamic> data) {
    return _http.post<User>(
      '/user/update',
      service: 'service',
      data: data,
      fromJson: (json) => User.fromJson(json),
    );
  }

  /// 获取好友列表
  Future<Result<List<Friend>>> getFriendList(Map<String, dynamic> params) {
    return _http.get<List<Friend>>('/relationship/contacts/list',
        service: 'service',
        params: params,
        fromJson: (json) =>
            (json as List).map((e) => Friend.fromJson(e)).toList());
  }

  /// 获取群列表
  Future<Result<List<Group>>> getGroupList() {
    return _http.get<List<Group>>('/relationship/groups/list',
        service: 'service',
        fromJson: (json) =>
            (json as List).map((e) => Group.fromJson(e)).toList());
  }

  /// 获取好友添加请求列表
  Future<Result<List<FriendRequest>>> getRequestFriendList(
      Map<String, dynamic> params) {
    return _http.get<List<FriendRequest>>('/relationship/newFriends/list',
        service: 'service',
        params: params,
        fromJson: (json) =>
            (json as List).map((e) => FriendRequest.fromJson(e)).toList());
  }

  /// 获取好友信息
  Future<Result<Friend>> getFriendInfo(Map<String, dynamic> data) {
    return _http.post<Friend>(
      '/relationship/getFriendInfo',
      service: 'service',
      data: data,
      fromJson: (json) => Friend.fromJson(json),
    );
  }

  /// 搜索好友信息
  Future<Result<List<Friend>>> searchFriendInfoList(Map<String, dynamic> data) {
    return _http.post<List<Friend>>(
      '/relationship/search/getFriendInfoList',
      service: 'service',
      data: data,
      fromJson: (json) =>
          (json as List).map((e) => Friend.fromJson(e)).toList(),
    );
  }

  /// 请求添加好友
  Future<Result<dynamic>> requestContact(Map<String, dynamic> data) {
    return _http.post('/relationship/requestContact',
        service: 'service', data: data);
  }

  /// 同意或拒绝好友请求
  Future<Result<dynamic>> approveContact(Map<String, dynamic> data) {
    return _http.post('/relationship/approveContact',
        service: 'service', data: data);
  }

  /// 删除好友
  Future<Result<dynamic>> deleteContact(Map<String, dynamic> data) {
    return _http.post('/relationship/deleteFriendById',
        service: 'service', data: data);
  }

  // ========================================
  // 🚩 群组相关 API
  // ========================================

  /// 获取群成员
  Future<Result<Map<String, GroupMember>>> getGroupMembers(
      Map<String, dynamic> data) {
    return _http.post<Map<String, GroupMember>>('/group/member',
        service: 'service', data: data, fromJson: (json) {
      if (json is Map) {
        return json.map((key, value) =>
            MapEntry(key.toString(), GroupMember.fromJson(value)));
      }
      return {};
    });
  }

  /// 同意或拒绝群聊邀请
  Future<Result<dynamic>> approveGroup(Map<String, dynamic> data) {
    return _http.post('/group/approve', service: 'service', data: data);
  }

  /// 退出群聊
  Future<Result<dynamic>> quitGroup(Map<String, dynamic> data) {
    return _http.post('/group/quit', service: 'service', data: data);
  }

  /// 邀请群成员
  Future<Result<dynamic>> inviteGroupMember(Map<String, dynamic> data) {
    return _http.post('/group/invite', service: 'service', data: data);
  }

  // ========================================
  // 💬 会话相关 API
  // ========================================

  /// 获取会话列表
  Future<Result<List<Chats>>> getChatList() {
    return _http.post<List<Chats>>('/chat/list',
        service: 'service',
        fromJson: (json) =>
            (json as List).map((e) => Chats.fromJson(e)).toList());
  }

  /// 获取单个会话
  Future<Result<Chats>> getChat(Map<String, dynamic> params) {
    return _http.get<Chats>(
      '/chat/one',
      service: 'service',
      params: params,
      fromJson: (json) => Chats.fromJson(json),
    );
  }

  /// 标记会话已读
  Future<Result<dynamic>> readChat(Map<String, dynamic> data) {
    return _http.post('/chat/read', service: 'service', data: data);
  }

  /// 创建会话
  Future<Result<Chats>> createChat(Map<String, dynamic> data) {
    return _http.post<Chats>('/chat/create',
        service: 'service',
        data: data,
        fromJson: (json) => Chats.fromJson(json));
  }

  // ========================================
  // 📩 消息相关 API
  // ========================================

  /// 发送单聊消息
  Future<Result<IMessage>> sendSingleMessage(Map<String, dynamic> data) {
    return _http.post<IMessage>(
      '/message/single',
      service: 'service',
      data: data,
      fromJson: (json) => IMessage.fromJson(json),
    );
  }

  /// 发送群聊消息
  Future<Result<IMessage>> sendGroupMessage(Map<String, dynamic> data) {
    return _http.post<IMessage>(
      '/message/group',
      service: 'service',
      data: data,
      fromJson: (json) => IMessage.fromJson(json),
    );
  }

  /// 撤回消息
  Future<Result<dynamic>> recallMessage(Map<String, dynamic> data) {
    return _http.post('/message/recall', service: 'service', data: data);
  }

  /// 获取消息列表
  Future<Result<Map<String, dynamic>>> getMessageList(
      Map<String, dynamic> data) {
    return _http.post<Map<String, dynamic>>('/message/list',
        service: 'service', data: data);
  }

  /// 检查单聊消息
  Future<Result<dynamic>> checkSingleMessage(Map<String, dynamic> data) {
    return _http.post('/message/singleCheck', service: 'service', data: data);
  }

  /// 发送视频消息
  Future<Result<dynamic>> sendCallMessage(Map<String, dynamic> data) {
    return _http.post('/message/media/video', service: 'service', data: data);
  }

  // ========================================
  // 💰 钱包 / 支付相关 API
  // ========================================

  /// 创建钱包
  Future<Result<WalletVo>> createWallet(Map<String, dynamic> data) {
    return _http.post<WalletVo>(
      '/wallet/create',
      service: 'wallet',
      data: data,
      fromJson: (json) => WalletVo.fromJson(json),
    );
  }

  /// 为用户创建钱包
  Future<Result<WalletVo>> createUserWallet(String userId) {
    return _http.post<WalletVo>(
      '/wallet/user/$userId/create',
      service: 'wallet',
      fromJson: (json) => WalletVo.fromJson(json),
    );
  }

  /// 获取钱包信息（按地址）
  Future<Result<WalletVo>> getWalletByAddress(String address) {
    return _http.get<WalletVo>(
      '/wallet/$address',
      service: 'wallet',
      fromJson: (json) => WalletVo.fromJson(json),
    );
  }

  /// 获取钱包信息（按用户）
  Future<Result<WalletVo>> getWalletByUser(String userId) {
    return _http.get<WalletVo>(
      '/user/$userId',
      service: 'wallet',
      fromJson: (json) => WalletVo.fromJson(json),
    );
  }

  /// 获取交易历史（按地址）
  Future<Result<List<TransactionVo>>> getTransactionsByAddress(
    String address,
    Map<String, dynamic> params,
  ) {
    return _http.get<List<TransactionVo>>(
      '/$address/history',
      service: 'wallet',
      params: params,
      fromJson: (json) =>
          (json as List).map((e) => TransactionVo.fromJson(e)).toList(),
    );
  }

  /// 获取交易历史（按用户）
  Future<Result<List<TransactionVo>>> getTransactionsByUser(
    String userId,
    Map<String, dynamic> params,
  ) {
    return _http.get<List<TransactionVo>>(
      '/user/$userId/history',
      service: 'wallet',
      params: params,
      fromJson: (json) =>
          (json as List).map((e) => TransactionVo.fromJson(e)).toList(),
    );
  }

  /// 获取手续费
  Future<Result<FeeVo>> fee() {
    return _http.get<FeeVo>(
      '/payment/fee',
      service: 'wallet',
      fromJson: (json) => FeeVo.fromJson(json),
    );
  }

  /// 直接付款
  Future<Result<dynamic>> pay(Map<String, dynamic> data) {
    return _http.post('/payment/pay', service: 'wallet', data: data);
  }

  /// 发起转账
  Future<Result<dynamic>> transfer(Map<String, dynamic> data) {
    return _http.post('/payment/transfer', service: 'wallet', data: data);
  }

  /// 确认收款
  Future<Result<dynamic>> confirmPayment(Map<String, dynamic> data) {
    return _http.post('/payment/confirm', service: 'wallet', data: data);
  }

  /// 退回转账
  Future<Result<dynamic>> returnPayment(Map<String, dynamic> data) {
    return _http.post('/payment/return', service: 'wallet', data: data);
  }

  /// 取消转账
  Future<Result<dynamic>> cancelPayment(Map<String, dynamic> data) {
    return _http.post('/payment/cancel', service: 'wallet', data: data);
  }

  // ========================================
  // 📂 文件相关 API
  // ========================================

  /// 图片上传
  Future<Result<Map<String, dynamic>>> uploadImage(dio.FormData data) {
    return _http.post<Map<String, dynamic>>('/media/image',
        service: 'upload', data: data);
  }

  /// 文件上传
  Future<Result<Map<String, dynamic>>> uploadFile(dio.FormData data) {
    return _http.post<Map<String, dynamic>>('/file/formUpload',
        service: 'upload', data: data);
  }

  // ========================================
  // 📹 WebRTC 相关 API
  // ========================================

  /// WebRTC 握手
  Future<RTCSessionDescription> webRtcHandshake(
    String baseUrl,
    String webrtcUrl,
    String sdp, {
    String type = 'play',
  }) async {
    final url = type == 'publish'
        ? '$baseUrl/rtc/v1/publish/'
        : '$baseUrl/rtc/v1/play/';
    final data = {
      'api': url,
      'streamurl': webrtcUrl,
      'sdp': sdp,
      'tid': '2b45a06',
    };

    final response = await _http.post<Map<String, dynamic>>(
      url,
      data: data,
      options: dio.Options(
        headers: {
          'Content-Type': 'application/json',
          'Connection': 'close',
        },
        responseType: dio.ResponseType.json,
      ),
    );

    if (response.isSuccess && response.data != null) {
      final o = response.data!;
      if (o['code'] == 0 && o.containsKey('sdp')) {
        return RTCSessionDescription(o['sdp'], 'answer');
      }
      if (o['code'] == 400) {
        throw BusinessException('当前已有人在推流', code: 400);
      }
      throw BusinessException('WebRTC handshake failed: ${response.message}');
    } else {
      throw NetworkException('请求推流服务器信令验证失败', code: response.code);
    }
  }
}
