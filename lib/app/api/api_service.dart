import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:flutter_im/exceptions/app_exception.dart';
import '../services/http_service.dart';

/// **🌐 统一 API 服务**
class ApiService extends HttpService {
  // 单例模式
  // ====================================
  // 🔐 认证相关 API
  // ====================================

  /// 登录
  Future<Map<String, dynamic>?> login(Map<String, dynamic> data) {
    return post('/auth/api/v1/auth/login', data: data);
  }

  /// 退出登录
  Future<Map<String, dynamic>?> logout(Map<String, dynamic> data) {
    return post('/auth/api/v1/auth/logout', data: data);
  }

  /// 刷新 Token
  Future<Map<String, dynamic>?> refreshToken() {
    return get('/auth/api/v1/auth/refresh/token');
  }

  /// 发送短信
  Future<Map<String, dynamic>?> sendSms(Map<String, dynamic> data) {
    return get('/auth/api/v1/auth/sms', params: data);
  }

  /// 获取二维码
  Future<Map<String, dynamic>?> getQRCode(Map<String, dynamic> data) {
    return get('/auth/api/v1/auth/qrcode', params: data);
  }

  /// 扫码登录
  Future<Map<String, dynamic>?> scanQRCode(Map<String, dynamic> data) {
    return post('/auth/api/v1/auth/qrcode/scan', data: data);
  }

  /// 检查二维码状态
  Future<Map<String, dynamic>?> checkQRCodeStatus(Map<String, dynamic> data) {
    return get('/auth/api/v1/auth/qrcode/status', params: data);
  }

  /// 获取公钥
  Future<Map<String, dynamic>?> getPublicKey() {
    return get('/auth/api/v1/auth/publickey');
  }

  /// 获取在线状态
  Future<Map<String, dynamic>?> getOnlineStatus(Map<String, dynamic> data) {
    return get('/auth/api/v1/auth/online', params: data);
  }

  /// 获取个人信息
  Future<Map<String, dynamic>?> getUserInfo(Map<String, dynamic> data) {
    return get('/auth/api/v1/auth/info', params: data);
  }

  // ====================================
  // 👤 用户 / 好友相关 API
  // ====================================

  /// **更新用户信息**
  Future<Map<String, dynamic>?> updateUserInfo(
      Map<String, dynamic> data) async {
    return post('/service/api/v1/user/update', data: data);
  }

  /// **获取好友列表**
  Future<Map<String, dynamic>?> getFriendList(Map<String, dynamic> data) {
    return get('/service/api/v1/relationship/contacts/list', params: data);
  }

  /// **获取群列表**
  Future<Map<String, dynamic>?> getGroupList(Map<String, dynamic> data) {
    return get('/service/api/v1/relationship/groups/list', params: data);
  }

  /// **获取好友添加请求列表**
  Future<Map<String, dynamic>?> getRequestFriendList(
      Map<String, dynamic> params) {
    return get('/service/api/v1/relationship/newFriends/list', params: params);
  }

  /// **获取好友信息**
  Future<Map<String, dynamic>?> getFriendInfo(Map<String, dynamic> data) {
    return post('/service/api/v1/relationship/getFriendInfo', data: data);
  }

  /// **搜索好友信息**
  Future<Map<String, dynamic>?> searchFriendInfoList(
      Map<String, dynamic> data) {
    return post('/service/api/v1/relationship/search/getFriendInfoList',
        data: data);
  }

  /// **请求添加好友**
  Future<Map<String, dynamic>?> requestContact(Map<String, dynamic> data) {
    return post('/service/api/v1/relationship/requestContact', data: data);
  }

  /// **同意或拒绝好友请求**
  Future<Map<String, dynamic>?> approveContact(Map<String, dynamic> data) {
    return post('/service/api/v1/relationship/approveContact', data: data);
  }

  /// **删除好友**
  Future<Map<String, dynamic>?> deleteContact(Map<String, dynamic> data) {
    return post('/service/api/v1/relationship/deleteFriendById', data: data);
  }

  // ====================================
  // 💬 会话相关 API
  // ====================================

  /// 获取会话列表
  Future<Map<String, dynamic>?> getChatList(Map<String, dynamic> data) {
    return post('/service/api/v1/chat/list', data: data);
  }

  /// 获取单个会话
  Future<Map<String, dynamic>?> getChat(Map<String, dynamic> data) {
    return get('/service/api/v1/chat/one', params: data);
  }

  /// 标记会话已读
  Future<Map<String, dynamic>?> readChat(Map<String, dynamic> data) {
    return post('/service/api/v1/chat/read', data: data);
  }

  /// 创建会话
  Future<Map<String, dynamic>?> createChat(Map<String, dynamic> data) {
    return post('/service/api/v1/chat/create', data: data);
  }

  // ====================================
  // 📩 消息相关 API
  // ====================================

  /// 发送单聊消息
  Future<Map<String, dynamic>?> sendSingleMessage(Map<String, dynamic> data) {
    return post('/service/api/v1/message/single', data: data);
  }

  /// 发送群聊消息
  Future<Map<String, dynamic>?> sendGroupMessage(Map<String, dynamic> data) {
    return post('/service/api/v1/message/group', data: data);
  }

  /// 撤回消息
  Future<Map<String, dynamic>?> recallMessage(Map<String, dynamic> data) {
    return post('/service/api/v1/message/recall', data: data);
  }

  /// 获取群成员
  Future<Map<String, dynamic>?> getGroupMember(Map<String, dynamic> data) {
    return post('/service/api/v1/group/member', data: data);
  }

  /// 同意或拒绝群聊邀请
  Future<Map<String, dynamic>?> approveGroup(Map<String, dynamic> data) {
    return post('/service/api/v1/group/approve', data: data);
  }

  /// 退出群聊
  Future<Map<String, dynamic>?> quitGroup(Map<String, dynamic> data) {
    return post('/service/api/v1/group/quit', data: data);
  }

  /// 邀请群成员
  Future<Map<String, dynamic>?> inviteGroupMember(Map<String, dynamic> data) {
    return post('/service/api/v1/group/invite', data: data);
  }

  /// 获取消息列表
  Future<Map<String, dynamic>?> getMessageList(Map<String, dynamic> data) {
    return post('/service/api/v1/message/list', data: data);
  }

  /// 检查单聊消息
  Future<Map<String, dynamic>?> checkSingleMessage(Map<String, dynamic> data) {
    return post('/service/api/v1/message/singleCheck', data: data);
  }

  /// 发送视频消息
  Future<Map<String, dynamic>?> sendCallMessage(Map<String, dynamic> data) {
    return post('/service/api/v1/message/media/video', data: data);
  }

  // ====================================
  // 💰 钱包 / 支付相关 API
  // ====================================

  /// 创建钱包
  Future<Map<String, dynamic>?> createWallet(Map<String, dynamic> data) {
    return post('/wallet/api/wallet/create', data: data);
  }

  /// 为用户创建钱包
  Future<Map<String, dynamic>?> createUserWallet(String userId) {
    return post('/wallet/api/wallet/user/$userId/create');
  }

  /// 获取钱包信息（按地址）
  Future<Map<String, dynamic>?> getWalletByAddress(String address) {
    return get('/wallet/api/wallet/$address');
  }

  /// 获取钱包信息（按用户）
  Future<Map<String, dynamic>?> getWalletByUser(String userId) {
    return get('/wallet/api/wallet/user/$userId');
  }

  /// 获取交易历史（按地址）
  Future<Map<String, dynamic>?> getTransactionsByAddress(
      String address, int page, int size) {
    return get('/wallet/api/wallet/$address/history',
        params: {'page': page, 'size': size});
  }

  /// 获取交易历史（按用户）
  Future<Map<String, dynamic>?> getTransactionsByUser(
      String userId, int page, int size) {
    return get('/wallet/api/wallet/user/$userId/history',
        params: {'page': page, 'size': size});
  }

  /// 获取手续费
  Future<Map<String, dynamic>?> fee() {
    return get('/wallet/api/payment/fee');
  }

  /// 直接付款
  Future<Map<String, dynamic>?> pay(Map<String, dynamic> data) {
    return post('/wallet/api/payment/pay', data: data);
  }

  /// 发起转账
  Future<Map<String, dynamic>?> transfer(Map<String, dynamic> data) {
    return post('/wallet/api/payment/transfer', data: data);
  }

  /// 确认收款
  Future<Map<String, dynamic>?> confirmPayment(
      String txId, String receiverAddress) {
    return post('/wallet/api/payment/confirm',
        data: {'txId': txId, 'receiverAddress': receiverAddress});
  }

  /// 退回转账
  Future<Map<String, dynamic>?> returnPayment(
      String txId, String receiverAddress) {
    return post('/wallet/api/payment/return',
        data: {'txId': txId, 'receiverAddress': receiverAddress});
  }

  /// 取消转账
  Future<Map<String, dynamic>?> cancelPayment(
      String txId, String senderAddress) {
    return post('/wallet/api/payment/cancel',
        data: {'txId': txId, 'senderAddress': senderAddress});
  }

  // ====================================
  // 📂 文件相关 API
  // ====================================

  /// 图片上传
  Future<Map<String, dynamic>?> uploadImage(FormData data) {
    return post('/upload/api/v1/media/image', data: data);
  }

  /// 文件上传
  Future<Map<String, dynamic>?> uploadFile(FormData data) {
    return post('/service/api/v1/file/formUpload', data: data);
  }

  // ====================================
  // ⚠️ 异常上报
  // ====================================

  Future<Map<String, dynamic>?> exceptionReport(Map<String, dynamic> data) {
    return get('/service/api/v1/tauri/exception/report', params: data);
  }

// ====================================
// 📂 webrtc 相关 API
// ====================================

  /// webrtc 获取 远程 answer
  Future<RTCSessionDescription> webRtcHandshake(
      String baseUrl, String webrtcUrl, String sdp,
      {String type = 'play'}) async {
    final dioInstance = Dio();
    // 拼接url
    final url = type == 'publish'
        ? '$baseUrl/rtc/v1/publish/'
        : '$baseUrl/rtc/v1/play/';

    final Map<String, dynamic> data = {
      'api': url,
      'streamurl': webrtcUrl,
      'sdp': sdp,
      'tid': "2b45a06" // 需确认此 ID 用途，建议参数化
    };

    try {
      (dioInstance.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
          () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      };

      dioInstance.options.headers['Content-Type'] = 'application/json';
      dioInstance.options.headers['Connection'] = 'close';
      dioInstance.options.responseType = ResponseType.plain;

      final response = await dioInstance.post(url, data: jsonEncode(data));

      if (response.statusCode == 200) {
        final Map<String, dynamic> o = jsonDecode(response.data);
        if (!o.containsKey('code') || !o.containsKey('sdp') || o['code'] != 0) {
          if (o['code'] == 400) {
            throw BusinessException("当前已有人在推流", code: 400);
          }
          throw BusinessException('WebRTC handshake failed: ${response.data}');
        }
        return RTCSessionDescription(o['sdp'], 'answer');
      } else {
        throw NetworkException('请求推流服务器信令验证失败', code: response.statusCode);
      }
    } catch (err) {
      if (err is AppException) rethrow;
      throw NetworkException('获取 webrtc sdp 失败', details: err);
    } finally {
      dioInstance.close();
    }
  }
}
