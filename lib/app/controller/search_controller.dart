import 'package:flutter_im/utils/objects.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';

import '../api/api_service.dart';
import '../core/handlers/error_handler.dart';
import '../database/app_database.dart';
import 'package:flutter_im/exceptions/app_exception.dart';
import '../models/friend.dart';
import '../models/search_message_result.dart';

class SearchController extends GetxController {
  final _storage = GetStorage();
  static const String _searchHistoryKey = 'search_history';
  static const String KEY_USER_ID = 'userId';

  // 数据库实例
  final db = GetIt.instance<AppDatabase>();
  late ApiService _apiService;

  final searchResults = <SearchMessageResult>[].obs;
  final searchHistory = <String>[].obs;
  final isSearching = false.obs;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    loadSearchHistory();
  }

  // 加载搜索历史
  Future<void> loadSearchHistory() async {
    try {
      final List<dynamic>? history = _storage.read<List>(_searchHistoryKey);
      if (history != null) {
        searchHistory.value = history.map((e) => e.toString()).toList();
      }
    } catch (e) {
      ErrorHandler.handle(AppException('加载搜索历史失败', details: e), silent: true);
    }
  }

  // 保存搜索历史
  Future<void> saveSearch(String keyword) async {
    if (keyword.trim().isEmpty) return;

    try {
      searchHistory.remove(keyword);
      searchHistory.insert(0, keyword);
      if (searchHistory.length > 10) {
        searchHistory.removeLast();
      }

      await _storage.write(_searchHistoryKey, searchHistory);
    } catch (e) {
      ErrorHandler.handle(AppException('保存搜索历史失败', details: e), silent: true);
    }
  }

  // 清除搜索历史
  void clearSearchHistory() {
    searchHistory.clear();
    _storage.remove(_searchHistoryKey);
  }

  // 执行搜索
  Future<void> performSearch(String keyword) async {
    if (keyword.trim().isEmpty) return;

    isSearching.value = true;
    searchResults.clear();

    final storedUserId = _storage.read(KEY_USER_ID);

    try {
      // 搜索单聊消息
      final singleMessages =
          await db.singleMessageDao.searchMessages(keyword, storedUserId);

      // 搜索群聊消息
      final groupMessages =
          await db.groupMessageDao.searchMessages(keyword, storedUserId);

      // 整理搜索结果
      final Map<String, SearchMessageResult> resultMap = {};

      // 处理单聊消息
      if (singleMessages.isNotEmpty) {
        for (final message in singleMessages) {
          final chatId =
              message.fromId == storedUserId ? message.toId : message.fromId;

          if (!resultMap.containsKey(chatId)) {
            final response = await _apiService
                .getFriendInfo({'fromId': storedUserId, 'toId': chatId});

            _handleApiResponse(response, onSuccess: (data) {
              if (data != null) {
                Friend friend = Friend.fromJson(data);
                resultMap[chatId] = SearchMessageResult(
                  id: chatId,
                  name: friend.name ?? "",
                  avatar: friend.avatar ?? "",
                  messageCount: 0,
                  messages: [],
                );
              }
            }, errorMessage: '获取用户信息失败');
          }

          if (resultMap.containsKey(chatId)) {
            resultMap[chatId]!.messages.add(message);
            resultMap[chatId]!.messageCount++;
          }
        }
      }

      // 将Map转换为List并更新searchResults
      searchResults.value = resultMap.values.toList();

      await saveSearch(keyword);
    } catch (e) {
      _showError('搜索失败: $e');
    } finally {
      isSearching.value = false;
    }
  }

  /// 统一处理 API 响应
  void _handleApiResponse(
    Map<String, dynamic>? response, {
    required void Function(dynamic) onSuccess,
    required String errorMessage,
  }) {
    final code = Objects.safeGet<int>(response, 'code');
    if (code == 200) {
      return onSuccess(response?['data']);
    }
    final msg = Objects.safeGet<String>(response, 'message', errorMessage);
    throw BusinessException(msg.toString());
  }

  /// 显示错误提示
  void _showError(dynamic error) {
    ErrorHandler.handle(error);
  }
}
