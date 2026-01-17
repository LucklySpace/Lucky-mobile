import 'package:flutter_im/app/core/base/base_controller.dart';
import 'package:flutter_im/utils/performance.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';

import '../database/app_database.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';

/// 联系人管理控制器
///
/// 功能：
/// - 好友列表管理（增删改查）
/// - 好友请求处理（发送、接受、拒绝）
/// - 好友搜索
/// - 本地数据同步
class ContactController extends BaseController {
  // ==================== 依赖注入 ====================

  final _db = GetIt.instance<AppDatabase>();
  final _storage = GetStorage();

  // ==================== 常量定义 ====================

  static const String _keyUserId = 'userId';

  // 响应式状态
  final RxList<Friend> contactsList = <Friend>[].obs; // 好友列表
  final RxList<FriendRequest> friendRequests = <FriendRequest>[].obs; // 好友请求列表
  final RxList<Friend> searchResults = <Friend>[].obs; // 搜索结果
  final RxString userId = ''.obs; // 当前用户ID
  final RxInt newFriendRequestCount = 0.obs; // 未处理好友请求计数
  final RxBool isLoadingRequests = false.obs; // 加载好友请求状态
  final RxBool isSearching = false.obs; // 搜索状态

  @override
  void onInit() {
    super.onInit();
    // 初始化用户ID
    final storedUserId = _storage.read(_keyUserId);
    if (storedUserId != null) {
      userId.value = storedUserId.toString();
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
      // 确保用户ID已加载
      if (userId.isEmpty) {
        getUserId();
      }

      if (userId.isEmpty) {
        showError('用户ID未初始化');
        return;
      }

      Get.log('📥 开始获取好友列表');

      // 查询本地最大的sequence（用于增量同步）
      final localMaxSequence = await _db.friendDao.getMaxSequence(userId.value);

      // 从服务器获取好友列表
      final response = await apiService.getFriendList({
        'sequence': localMaxSequence ?? 0,
        'userId': userId.value,
      });

      handleApiResponse(response, onSuccess: (data) async {
        final List<Friend> rawList = data;

        if (rawList.isEmpty) {
          Get.log('✅ 好友列表为空或已是最新');
          return;
        }

        Get.log('📥 收到 ${rawList.length} 个好友更新');

        // 批量保存到本地数据库
        await Performance.batchExecute(
          rawList,
          (friend) async => await _db.friendDao.insertOrUpdate(friend),
          batchSize: 20,
        );

        Get.log('✅ 好友列表更新完成');
      });
    } finally {
      isLoading.value = false;
      // 刷新好友列表
      await _loadContactsFromDb();
    }
  }

  /// 从数据库加载好友列表
  Future<void> _loadContactsFromDb() async {
    if (userId.isEmpty) return;

    // 从数据库加载好友列表
    final friends = await _db.friendDao.list(userId.value);
    if (friends != null) {
      // 过滤掉已拉黑的好友
      contactsList.value = friends.where((friend) => friend.isNormal).toList();
      Get.log('📚 从数据库加载了 ${contactsList.length} 个好友');
    }
  }

  /// 获取好友信息
  Future<Friend> getFriend(String targetId, String friendId) async {
    Friend? result;

    if (!targetId.isEmpty) {
      final response = await apiService
          .getFriendInfo({'fromId': targetId, 'toId': friendId});
      handleApiResponse(response, onSuccess: (data) {
        result = data;
      });
    }

    return result ?? Friend(userId: targetId, friendId: friendId, name: '');
  }

  /// 删除好友
  Future<void> deleteFriend(String friendId) async {
    final response = await apiService.deleteContact({'friendId': friendId});
    handleApiResponse(response, onSuccess: (data) async {
      if (userId.value.isNotEmpty && friendId.isNotEmpty) {
        await _db.friendDao.deleteFriend(userId.value, friendId);
      }
      showSuccess('已删除好友');
      fetchContacts(); // 刷新好友列表
    });
  }

  // --- 好友请求管理 ---

  /// 获取好友请求列表，并更新未处理请求计数
  Future<void> fetchFriendRequests() async {
    if (userId.isEmpty) {
      getUserId();
    }

    isLoadingRequests.value = true;
    final response =
        await apiService.getRequestFriendList({"userId": userId.value});
    handleApiResponse(response, onSuccess: (data) {
      friendRequests.value = response.data ?? [];
      // 计算未处理请求数量
      newFriendRequestCount.value =
          friendRequests.where((request) => request.approveStatus == 0).length;
    }, silent: true);
    isLoadingRequests.value = false;
  }

  /// 发送好友请求
  Future<void> sendFriendRequest(String targetUserId, String reason) async {
    final response = await apiService.requestContact({
      'friendId': targetUserId,
      'reason': reason,
    });
    handleApiResponse(response, onSuccess: (data) {
      showSuccess('好友请求已发送');
    });
  }

  /// 审批联系人
  Future<void> handleFriendApprove(String requestId, bool approve) async {
    final response = await apiService.approveContact({
      'requestId': requestId,
      'status': approve ? 1 : 2,
    });
    handleApiResponse(response, onSuccess: (data) {
      showSuccess(approve ? '已接受好友请求' : '已拒绝好友请求');
      fetchContacts(); // 刷新好友列表
      fetchFriendRequests(); // 刷新请求列表
    });
  }

  // --- 搜索功能 ---

  /// 搜索用户
  Future<void> searchUser(String keyword) async {
    isSearching.value = true;
    searchResults.clear();
    final response =
        await apiService.searchFriendInfoList({'keyword': keyword});
    handleApiResponse(response, onSuccess: (data) {
      final List<Friend> users = data;
      searchResults.value = users;
      if (searchResults.isEmpty) {
        showInfo('搜索用户不存在');
      }
    });
    isSearching.value = false;
  }

  /// 更新好友请求计数
  void updateNewFriendRequestCount(int count) {
    newFriendRequestCount.value = count;
  }
}
