import 'package:get/get.dart';

import '../../models/group_member.dart';
import 'chat_base_controller.dart';

/// 聊天群组控制器
///
/// 职责：
/// - 管理群组成员列表
/// - 加载和缓存群组信息
/// - 提供群成员查询接口
///
/// 设计原则：
/// - 单一职责：只负责群组相关功能
/// - 缓存优化：避免重复请求群成员信息
/// - 懒加载：按需加载群成员
class ChatGroupController extends ChatBaseController {
  // ==================== 响应式状态 ====================

  /// 群成员列表
  /// Map结构：groupId -> Map(userId -> GroupMember)
  final RxMap<String, Map<String, GroupMember>> groupMembers =
      <String, Map<String, GroupMember>>{}.obs;

  /// 加载状态
  final RxBool isLoadingMembers = false.obs;

  // ==================== 公共方法 ====================

  /// 获取群成员列表
  ///
  /// 参数：
  /// - [groupId] 群组ID
  /// - [forceRefresh] 是否强制刷新（默认false，使用缓存）
  Future<Map<String, GroupMember>?> getGroupMembers(
    String groupId, {
    bool forceRefresh = false,
  }) async {
    // 如果有缓存且不强制刷新，直接返回缓存
    if (!forceRefresh && groupMembers.containsKey(groupId)) {
      return groupMembers[groupId];
    }

    // 从服务器加载
    await fetchGroupMembers(groupId);
    return groupMembers[groupId];
  }

  /// 获取单个群成员信息
  ///
  /// 参数：
  /// - [groupId] 群组ID
  /// - [userId] 用户ID
  GroupMember? getGroupMember(String groupId, String userId) {
    return groupMembers[groupId]?[userId];
  }

  /// 加载群成员列表
  ///
  /// 参数：
  /// - [groupId] 群组ID
  Future<void> fetchGroupMembers(String groupId) async {
    if (isLoadingMembers.value) {
      Get.log('⏳ 群成员加载中，跳过本次请求');
      return;
    }
    isLoadingMembers.value = true;
    final response = await apiService.getGroupMembers({"groupId": groupId});

    handleApiResponse(
      response,
      onSuccess: (data) async {
        if (data.isEmpty) return;
        groupMembers[groupId] = data;
        Get.log('✅ 已加载群组 $groupId 的 ${data.length} 个成员');
      },
    );
    isLoadingMembers.value = false;
  }

  /// 更新群成员信息
  ///
  /// 参数：
  /// - [groupId] 群组ID
  /// - [member] 群成员信息
  void updateGroupMember(String groupId, GroupMember member) {
    if (groupMembers.containsKey(groupId)) {
      groupMembers[groupId]![member.memberId] = member;
      groupMembers.refresh();
    }
  }

  /// 批量更新群成员
  ///
  /// 参数：
  /// - [groupId] 群组ID
  /// - [members] 群成员列表
  void updateGroupMembers(String groupId, List<GroupMember> members) {
    final memberMap = <String, GroupMember>{};
    for (final member in members) {
      memberMap[member.memberId] = member;
    }
    groupMembers[groupId] = memberMap;
    groupMembers.refresh();
  }

  /// 清除群成员缓存
  ///
  /// 参数：
  /// - [groupId] 群组ID，如果为null则清除所有缓存
  void clearGroupMembersCache([String? groupId]) {
    if (groupId != null) {
      groupMembers.remove(groupId);
    } else {
      groupMembers.clear();
    }
  }

  /// 检查用户是否在群组中
  ///
  /// 参数：
  /// - [groupId] 群组ID
  /// - [userId] 用户ID
  bool isMemberInGroup(String groupId, String userId) {
    return groupMembers[groupId]?.containsKey(userId) ?? false;
  }

  /// 获取群组成员数量
  ///
  /// 参数：
  /// - [groupId] 群组ID
  int getGroupMemberCount(String groupId) {
    return groupMembers[groupId]?.length ?? 0;
  }
}
