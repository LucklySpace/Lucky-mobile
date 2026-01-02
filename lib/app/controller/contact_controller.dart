import 'package:flutter_im/utils/objects.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';

import '../api/api_service.dart';
import '../core/handlers/error_handler.dart';
import '../database/app_database.dart';
import 'package:flutter_im/exceptions/app_exception.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';

/// 联系人管理控制器，负责处理好友列表、好友请求及搜索功能
class ContactController extends GetxController {
  // 依赖注入
  final _apiService = Get.find<ApiService>();
  final _db = GetIt.instance<AppDatabase>();
  final _storage = GetStorage();

  // 常量定义
  static const String _keyUserId = 'userId';
  static const int _successCode = 200;
  static const String _defaultErrorMsg = '操作失败';

  // 响应式状态
  final RxList<Friend> contactsList = <Friend>[].obs; // 好友列表
  final RxList<FriendRequest> friendRequests = <FriendRequest>[].obs; // 好友请求列表
  final RxList<Friend> searchResults = <Friend>[].obs; // 搜索结果
  final RxString userId = ''.obs; // 当前用户ID
  final RxInt newFriendRequestCount = 0.obs; // 未处理好友请求计数
  final RxBool isLoading = false.obs; // 加载好友列表状态
  final RxBool isLoadingRequests = false.obs; // 加载好友请求状态
  final RxBool isSearching = false.obs; // 搜索状态

  @override
  void onInit() {
    super.onInit();
    // 初始化用户ID
    final storedUserId = _storage.read(_keyUserId);
    if (storedUserId != null) {
      userId.value = storedUserId;
    }
  }

  // --- 好友列表管理 ---

  void getUserId() {
    final storedUserId = _storage.read(_keyUserId);
    if (storedUserId != null) {
      userId.value = storedUserId.toString();
    }
  }

  /// 获取好友列表
  Future<void> fetchContacts() async {
    try {
      isLoading.value = true;

      if (userId.isEmpty) {
        getUserId();
      }

      // 先查询本地最大的 sequence
      final localMaxSequence = await _db.friendDao.getMaxSequence(userId.value);

      final response = await _apiService.getFriendList({
        'userId': userId.value,
        'sequence': localMaxSequence ?? 0,
      });

      _handleApiResponse(response, onSuccess: (data) async {
        final list = (data as List<dynamic>)
            .map((friend) => Friend.fromJson(friend))
            .toList();

        // 保存好友列表到本地数据库
        for (var friend in list) {
          await _db.friendDao.insertOrUpdate(friend);
        }

        contactsList.value = (await _db.friendDao.list(userId.value))! ?? [];
      }, errorMessage: '获取好友列表失败');
    } catch (e) {
      _showError('获取好友列表失败: $e');
      contactsList.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// 删除好友
  Future<void> deleteFriend(String friendId) async {
    try {
      final response = await _apiService.deleteContact({
        'fromId': userId.value,
        'toId': friendId,
      });
      _handleApiResponse(response, onSuccess: (_) async {
        if (Objects.isNotBlank(userId.value) && Objects.isNotBlank(friendId)) {
          await _db.friendDao.deleteFriend(userId.value, friendId);
        }
        Get.snackbar('成功', '已删除好友');
        fetchContacts(); // 刷新好友列表
      }, errorMessage: '删除好友失败');
    } catch (e) {
      _showError('删除好友失败: $e');
    }
  }

  // --- 好友请求管理 ---

  /// 获取好友请求列表，并更新未处理请求计数
  Future<void> fetchFriendRequests() async {
    if (userId.isEmpty) {
      getUserId();
    }

    try {
      isLoadingRequests.value = true;
      final response = await _apiService.getRequestFriendList({
        'userId': userId.value,
      });
      _handleApiResponse(response, onSuccess: (data) {
        friendRequests.value = (data as List<dynamic>)
            .map((request) => FriendRequest.fromJson(request))
            .toList();
        // 计算未处理请求数量
        newFriendRequestCount.value = friendRequests
            .where((request) => request.approveStatus == 0)
            .length;
      }, errorMessage: '获取好友请求列表失败');
    } finally {
      isLoadingRequests.value = false;
    }
  }

  /// 发送好友请求
  Future<void> sendFriendRequest(String targetUserId) async {
    try {
      final response = await _apiService.requestContact({
        'fromId': userId.value,
        'toId': targetUserId,
      });
      _handleApiResponse(response, onSuccess: (_) {
        Get.snackbar('成功', '好友请求已发送');
      }, errorMessage: '发送好友请求失败');
    } catch (e) {
      _showError('发送好友请求失败: $e');
    }
  }

  ///  审批联系人
  ///  requestId 联系人请求id
  /// approveStatus 状态 （0未审批，1同意，2拒绝）
  Future<void> handleFriendApprove(String requestId, int approveStatus) async {
    try {
      final response = await _apiService.approveContact({
        'id': requestId,
        'approveStatus': approveStatus,
      });
      _handleApiResponse(response, onSuccess: (_) {
        Get.snackbar('成功', '已接受好友请求');
        fetchContacts(); // 刷新好友列表
        fetchFriendRequests(); // 刷新请求列表
      }, errorMessage: '处理好友请求失败');
    } catch (e) {
      _showError('处理好友请求失败: $e');
    }
  }

  // --- 搜索功能 ---

  /// 搜索用户
  Future<void> searchUser(String keyword) async {
    try {
      isSearching.value = true;
      searchResults.clear();
      final response = await _apiService.getFriendInfo({
        'fromId': userId.value,
        'toId': keyword,
      });
      _handleApiResponse(response, onSuccess: (data) {
        if (data != null) {
          searchResults.add(Friend.fromJson(data));
        } else {
          Get.snackbar('错误', '搜索用户不存在');
        }
      }, errorMessage: '搜索用户失败');
    } finally {
      isSearching.value = false;
    }
  }

  // --- 辅助方法 ---

  /// 统一处理 API 响应
  void _handleApiResponse(
    Map<String, dynamic>? response, {
    required void Function(dynamic) onSuccess,
    required String errorMessage,
  }) {
    final code = Objects.safeGet<int>(response, 'code');
    if (code == _successCode) {
      return onSuccess(response?['data']);
    }
    final msg = Objects.safeGet<String>(response, 'message', errorMessage);
    throw BusinessException(msg.toString());
  }

  /// 显示错误提示
  void _showError(dynamic error) {
    ErrorHandler.handle(error);
  }

  /// 更新好友请求计数
  void updateNewFriendRequestCount(int count) {
    newFriendRequestCount.value = count;
  }
}
