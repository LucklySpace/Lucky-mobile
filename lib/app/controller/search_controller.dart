import 'package:flutter_im/exceptions/app_exception.dart';
import 'package:flutter_im/utils/objects.dart';
import 'package:flutter_im/utils/performance.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';

import '../../constants/app_constant.dart';
import '../api/api_service.dart';
import '../core/handlers/error_handler.dart';
import '../database/app_database.dart';
import '../models/friend.dart';
import '../models/search_message_result.dart';

/// 搜索控制器
///
/// 功能：
/// - 消息搜索（单聊、群聊）
/// - 搜索历史管理
/// - 搜索结果缓存
/// - 搜索防抖优化
class SearchController extends GetxController {
  // ==================== 常量定义 ====================

  static const String _searchHistoryKey = 'search_history';
  static const String _keyUserId = 'userId';
  static const int _maxHistoryCount = 10;

  // ==================== 依赖注入 ====================

  final _storage = GetStorage();
  final _db = GetIt.instance<AppDatabase>();
  late final ApiService _apiService;

  /// 搜索防抖控制器
  late final DebounceController _searchDebounce;

  // ==================== 响应式状态 ====================

  final searchResults = <SearchMessageResult>[].obs;
  final searchHistory = <String>[].obs;
  final isSearching = false.obs;
  final RxString currentKeyword = ''.obs;

  // ==================== 生命周期 ====================

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();

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

    // 验证搜索关键词
    if (trimmedKeyword.isEmpty) {
      searchResults.clear();
      return;
    }

    if (trimmedKeyword.length > 100) {
      ErrorHandler.showWarning('搜索关键词过长');
      return;
    }

    isSearching.value = true;
    currentKeyword.value = trimmedKeyword;
    searchResults.clear();

    final storedUserId = _storage.read(_keyUserId);
    if (storedUserId == null) {
      ErrorHandler.handle(BusinessException('用户ID未找到'));
      isSearching.value = false;
      return;
    }

    try {
      Get.log('🔍 开始搜索: $trimmedKeyword');

      // 并行搜索单聊和群聊消息
      final results = await Future.wait([
        _db.singleMessageDao.searchMessages(trimmedKeyword, storedUserId),
        _db.groupMessageDao.searchMessages(trimmedKeyword, storedUserId),
      ]);

      final singleMessages = results[0];
      final groupMessages = results[1];

      Get.log(
          '📊 搜索结果: 单聊 ${singleMessages.length} 条, 群聊 ${groupMessages.length} 条');

      // 整理搜索结果
      final Map<String, SearchMessageResult> resultMap = {};

      // 处理单聊消息
      if (singleMessages.isNotEmpty) {
        await _processSingleMessages(singleMessages, storedUserId, resultMap);
      }

      // 处理群聊消息（如需要）
      // if (groupMessages.isNotEmpty) {
      //   await _processGroupMessages(groupMessages, storedUserId, resultMap);
      // }

      // 将Map转换为List并更新searchResults
      searchResults.value = resultMap.values.toList();

      // 保存到搜索历史
      if (searchResults.isNotEmpty) {
        await saveSearch(trimmedKeyword);
        Get.log('✅ 搜索完成，找到 ${searchResults.length} 个会话');
      } else {
        Get.log('📭 没有找到匹配的消息');
      }
    } catch (e) {
      ErrorHandler.handle(AppException('搜索失败', details: e));
    } finally {
      isSearching.value = false;
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

      // 如果还没有获取过这个聊天的信息
      if (!resultMap.containsKey(chatId)) {
        try {
          final response = await _apiService
              .getFriendInfo({'fromId': userId, 'toId': chatId});

          _handleApiResponse(response, onSuccess: (data) {
            if (data != null) {
              final friend = Friend.fromJson(data);
              resultMap[chatId] = SearchMessageResult(
                id: chatId,
                name: friend.name ?? "未知用户",
                avatar: friend.avatar ?? "",
                messageCount: 0,
                messages: [],
              );
            }
          }, errorMessage: '获取用户信息失败');
        } catch (e) {
          // 单个好友信息获取失败不影响其他结果
          Get.log('⚠️ 获取好友信息失败 ($chatId): $e');
          continue;
        }
      }

      // 添加消息到结果
      if (resultMap.containsKey(chatId)) {
        resultMap[chatId]!.messages.add(message);
        resultMap[chatId]!.messageCount++;
      }
    }
  }

  /// 清空搜索结果
  void clearResults() {
    searchResults.clear();
    currentKeyword.value = '';
    _searchDebounce.cancel();
  }

  // ==================== 辅助方法 ====================

  /// 统一处理 API 响应
  void _handleApiResponse(
    Map<String, dynamic>? response, {
    required void Function(dynamic) onSuccess,
    required String errorMessage,
  }) {
    final code = Objects.safeGet<int>(response, 'code');
    if (code == AppConstants.businessCodeSuccess) {
      return onSuccess(response?['data']);
    }
    final msg = Objects.safeGet<String>(response, 'message') ?? errorMessage;
    throw BusinessException(msg);
  }
}
