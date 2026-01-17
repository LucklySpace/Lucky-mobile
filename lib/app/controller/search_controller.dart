import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';

import '../../constants/app_constant.dart';
import '../../exceptions/app_exception.dart';
import '../../utils/performance.dart';
import '../core/base/base_controller.dart';
import '../core/handlers/error_handler.dart';
import '../database/app_database.dart';
import '../models/chats.dart';
import '../models/friend.dart';
import '../models/search_message_result.dart';

/// 搜索控制器
///
/// 功能：
/// - 消息搜索（单聊、群聊）
/// - 搜索历史管理
/// - 搜索结果缓存
/// - 搜索防抖优化
class SearchController extends BaseController {
  // ==================== 常量定义 ====================

  static const String _searchHistoryKey = 'search_history';
  static const String _keyUserId = 'userId';
  static const int _maxHistoryCount = 10;

  // ==================== 依赖注入 ====================

  final _storage = GetStorage();
  final _db = GetIt.instance<AppDatabase>();

  /// 搜索防抖控制器
  late final DebounceController _searchDebounce;

  // ==================== 响应式状态 ====================

  /// 搜索结果分类
  final contactResults = <Friend>[].obs;
  final groupResults = <Chats>[].obs;
  final messageResults = <SearchMessageResult>[].obs;

  final searchHistory = <String>[].obs;
  final isSearching = false.obs;
  final RxString currentKeyword = ''.obs;

  // ==================== 生命周期 ====================

  @override
  void onInit() {
    super.onInit();

    // 初始化防抖控制器
    _searchDebounce = DebounceController(
      duration: Duration(milliseconds: AppConstants.debounceDelayMs),
    );

    // 加载搜索历史
    loadSearchHistory();
  }

  @override
  void onClose() {
    _searchDebounce.dispose();
    super.onClose();
  }

  // ==================== 搜索历史管理 ====================

  /// 加载搜索历史
  Future<void> loadSearchHistory() async {
    try {
      final List<dynamic>? history = _storage.read<List>(_searchHistoryKey);
      if (history != null && history.isNotEmpty) {
        searchHistory.value = history.map((e) => e.toString()).toList();
        Get.log('✅ 已加载 ${searchHistory.length} 条搜索历史');
      }
    } catch (e) {
      ErrorHandler.handle(
        AppException('加载搜索历史失败', details: e),
        silent: true,
      );
    }
  }

  /// 保存搜索到历史记录
  Future<void> saveSearch(String keyword) async {
    final trimmedKeyword = keyword.trim();
    if (trimmedKeyword.isEmpty) return;

    try {
      // 移除已存在的相同关键词
      searchHistory.remove(trimmedKeyword);

      // 插入到顶部
      searchHistory.insert(0, trimmedKeyword);

      // 限制历史记录数量
      if (searchHistory.length > _maxHistoryCount) {
        searchHistory.removeRange(_maxHistoryCount, searchHistory.length);
      }

      // 持久化到本地存储
      await _storage.write(_searchHistoryKey, searchHistory);
      Get.log('✅ 搜索历史已保存: $trimmedKeyword');
    } catch (e) {
      ErrorHandler.handle(
        AppException('保存搜索历史失败', details: e),
        silent: true,
      );
    }
  }

  /// 清除搜索历史
  void clearSearchHistory() {
    searchHistory.clear();
    _storage.remove(_searchHistoryKey);
    ErrorHandler.showSuccess('搜索历史已清除');
    Get.log('🗑️ 搜索历史已清除');
  }

  /// 删除单条搜索历史
  void removeSearchHistory(String keyword) {
    searchHistory.remove(keyword);
    _storage.write(_searchHistoryKey, searchHistory);
    Get.log('🗑️ 已删除搜索历史: $keyword');
  }

  // ==================== 搜索功能 ====================

  /// 执行搜索（带防抖）
  ///
  /// [keyword] 搜索关键词
  void performSearch(String keyword) {
    _searchDebounce.call(() => _executeSearch(keyword));
  }

  /// 立即执行搜索（不防抖）
  Future<void> searchNow(String keyword) async {
    _searchDebounce.cancel();
    await _executeSearch(keyword);
  }

  /// 执行搜索的核心逻辑
  Future<void> _executeSearch(String keyword) async {
    final trimmedKeyword = keyword.trim();

    if (trimmedKeyword.isEmpty) {
      _clearAllResults();
      return;
    }

    isSearching.value = true;
    currentKeyword.value = trimmedKeyword;
    _clearAllResults();

    final storedUserId = _storage.read(_keyUserId);
    if (storedUserId == null) {
      isSearching.value = false;
      return;
    }

    try {
      // 1. 搜索联系人
      final friends =
          await _db.friendDao.searchFriends(storedUserId, trimmedKeyword);
      contactResults.addAll(friends);

      // 2. 搜索群组 (根据名称搜索本地群组会话)
      final groups =
          await _db.chatsDao.searchGroupChats(storedUserId, trimmedKeyword);
      groupResults.addAll(groups);

      // 3. 搜索聊天记录
      final results = await Future.wait([
        _db.singleMessageDao.searchMessages(trimmedKeyword, storedUserId),
        _db.groupMessageDao.searchMessages(trimmedKeyword, storedUserId),
      ]);

      final Map<String, SearchMessageResult> resultMap = {};
      if (results[0].isNotEmpty) {
        await _processSingleMessages(results[0], storedUserId, resultMap);
      }
      if (results[1].isNotEmpty) {
        await _processGroupMessages(results[1], storedUserId, resultMap);
      }
      messageResults.value = resultMap.values.toList();

      // 按时间降序排序消息结果
      messageResults.sort((a, b) {
        final aTime = a.messages.isNotEmpty ? a.messages.first.messageTime : 0;
        final bTime = b.messages.isNotEmpty ? b.messages.first.messageTime : 0;
        return bTime.compareTo(aTime);
      });

      // 保存到搜索历史 (如果有结果且关键字长度大于1)
      if (trimmedKeyword.length > 1 && hasResults) {
        saveSearch(trimmedKeyword);
      }
    } catch (e) {
      ErrorHandler.handle(AppException('搜索失败', details: e));
    } finally {
      isSearching.value = false;
    }
  }

  void _clearAllResults() {
    contactResults.clear();
    groupResults.clear();
    messageResults.clear();
  }

  /// 处理群聊消息搜索结果
  Future<void> _processGroupMessages(
    List<dynamic> messages,
    String userId,
    Map<String, SearchMessageResult> resultMap,
  ) async {
    for (final message in messages) {
      final groupId = message.groupId;
      if (groupId == null) continue;

      if (!resultMap.containsKey(groupId)) {
        final chats =
            await _db.chatsDao.getChatByOwnerIdAndToId(userId, groupId);
        if (chats != null && chats.isNotEmpty) {
          final chat = chats.first;
          resultMap[groupId] = SearchMessageResult(
            id: groupId,
            name: chat.name,
            avatar: chat.avatar,
            messageCount: 0,
            messages: [],
            type: '',
          );
        }
      }

      if (resultMap.containsKey(groupId)) {
        resultMap[groupId]!.messages.add(message);
        resultMap[groupId]!.messageCount;
      }
    }
  }

  /// 处理单聊消息搜索结果
  Future<void> _processSingleMessages(
    List<dynamic> messages,
    String userId,
    Map<String, SearchMessageResult> resultMap,
  ) async {
    for (final message in messages) {
      final chatId = message.fromId == userId ? message.toId : message.fromId;

      if (!resultMap.containsKey(chatId)) {
        // 先尝试从本地数据库获取好友信息
        final localFriend = await _db.friendDao.getFriendById(userId, chatId);
        if (localFriend != null) {
          resultMap[chatId] = SearchMessageResult(
            id: chatId,
            name: localFriend.name ?? "未知用户",
            avatar: localFriend.avatar ?? "",
            messageCount: 0,
            messages: [],
            type: '',
          );
        } else {
          // 本地没有再尝试从网络获取
          final response = await apiService.getFriendInfo({'friendId': chatId});
          handleApiResponse(response, onSuccess: (data) {
            final user = data;
            resultMap[chatId] = SearchMessageResult(
              id: chatId,
              name: user.name,
              avatar: user.avatar,
              messageCount: 0,
              messages: [],
              type: '',
            );
          }, onError: (code, message) {
            Get.log('⚠️ 获取好友信息失败 ($chatId): $message');
            // 如果获取失败，先占个位
            resultMap[chatId] = SearchMessageResult(
              id: chatId,
              name: "用户($chatId)",
              avatar: "",
              messageCount: 0,
              messages: [],
              type: '',
            );
          }, silent: true);
        }
      }

      // 添加消息到结果
      if (resultMap.containsKey(chatId)) {
        resultMap[chatId]!.messages.add(message);
        resultMap[chatId]!.messageCount;
      }
    }
  }

  /// 是否有搜索结果
  bool get hasResults =>
      contactResults.isNotEmpty ||
      groupResults.isNotEmpty ||
      messageResults.isNotEmpty;

  /// 清空搜索结果
  void clearResults() {
    _clearAllResults();
    currentKeyword.value = '';
    _searchDebounce.cancel();
  }
}
