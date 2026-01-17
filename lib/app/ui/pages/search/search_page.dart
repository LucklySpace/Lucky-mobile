import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../routes/app_routes.dart';
import '../../../../utils/i18n_util.dart';
import '../../../controller/chat_controller.dart';
import '../../../controller/search_controller.dart' as search_ctrl;
import '../../../models/chats.dart';
import '../../../models/friend.dart';
import '../../../models/search_message_result.dart';
import '../../widgets/icon/icon_font.dart';

/// 搜索页面
///
/// 提供全局搜索功能，支持搜索联系人、群组和聊天记录。
/// 模仿微信搜索体验：
/// - 实时搜索及关键词高亮
/// - 分类展示结果
/// - 历史记录管理
class SearchPage extends GetView<search_ctrl.SearchController> {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final searchTextController = TextEditingController();

    // 同步搜索关键字到输入框
    ever(controller.currentKeyword, (String keyword) {
      if (searchTextController.text != keyword) {
        searchTextController.text = keyword;
        searchTextController.selection = TextSelection.fromPosition(
          TextPosition(offset: keyword.length),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(searchTextController),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: _buildBody(searchTextController),
      ),
    );
  }

  /// 构建顶部 AppBar
  PreferredSizeWidget _buildAppBar(TextEditingController searchTextController) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing12),
        child: Row(
          children: [
            Expanded(child: _buildSearchField(searchTextController)),
            _buildCancelButton(),
          ],
        ),
      ),
    );
  }

  /// 构建搜索输入框
  Widget _buildSearchField(TextEditingController searchTextController) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radius8),
      ),
      child: TextField(
        controller: searchTextController,
        autofocus: true,
        textAlignVertical: TextAlignVertical.center,
        onChanged: (value) => controller.performSearch(value),
        onSubmitted: (value) => controller.searchNow(value),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: I18n.t('search.placeholder'),
          hintStyle: const TextStyle(
              color: AppColors.textHint, fontSize: AppSizes.font14),
          border: InputBorder.none,
          isDense: true,
          prefixIcon:
              Icon(Iconfont.search, color: AppColors.textHint, size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          suffixIcon: Obx(() => controller.currentKeyword.isEmpty
              ? const SizedBox()
              : IconButton(
                  icon: const Icon(Icons.cancel,
                      color: AppColors.textHint, size: 18),
                  onPressed: () {
                    searchTextController.clear();
                    controller.clearResults();
                  },
                )),
        ),
        style: const TextStyle(
            fontSize: AppSizes.font16, color: AppColors.textPrimary),
      ),
    );
  }

  /// 构建取消按钮
  Widget _buildCancelButton() {
    return TextButton(
      onPressed: () => Get.back(),
      child: Text(
        I18n.t('cancel'),
        style: const TextStyle(
            color: AppColors.primary,
            fontSize: AppSizes.font16,
            fontWeight: FontWeight.w500),
      ),
    );
  }

  /// 构建页面主体
  Widget _buildBody(TextEditingController searchTextController) {
    return Obx(() {
      if (controller.isSearching.value &&
          controller.currentKeyword.isNotEmpty) {
        return const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        );
      }

      if (controller.currentKeyword.isEmpty) {
        return _buildSearchHistory(searchTextController);
      }

      if (!controller.hasResults) {
        return _buildEmptyState();
      }

      return _buildSearchResults();
    });
  }

  /// 构建搜索结果列表
  Widget _buildSearchResults() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        if (controller.contactResults.isNotEmpty)
          _buildSection(
            title: I18n.t('search.contacts'),
            items: controller.contactResults,
            itemBuilder: (friend) => _buildContactItem(friend as Friend),
          ),
        if (controller.groupResults.isNotEmpty)
          _buildSection(
            title: I18n.t('search.groups'),
            items: controller.groupResults,
            itemBuilder: (chat) => _buildGroupItem(chat as Chats),
          ),
        if (controller.messageResults.isNotEmpty)
          _buildSection(
            title: I18n.t('search.messages'),
            items: controller.messageResults,
            itemBuilder: (result) =>
                _buildMessageResultItem(result as SearchMessageResult),
          ),
        const SizedBox(height: AppSizes.spacing32),
      ],
    );
  }

  /// 构建分类列表节
  Widget _buildSection({
    required String title,
    required List items,
    required Widget Function(dynamic) itemBuilder,
  }) {
    final bool showMore = items.length > 3;
    final displayItems = showMore ? items.take(3).toList() : items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
              AppSizes.spacing16, 16, AppSizes.spacing16, 8),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppSizes.font13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          color: AppColors.surface,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayItems.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 76, color: AppColors.divider),
            itemBuilder: (context, index) => itemBuilder(displayItems[index]),
          ),
        ),
        if (showMore)
          InkWell(
            onTap: () {
              // TODO: 跳转到该分类的完整结果页
            },
            child: Container(
              height: 48,
              color: AppColors.surface,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
              child: Row(
                children: [
                  Icon(Iconfont.search, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${I18n.t('search.more')} $title',
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: AppSizes.font14),
                  ),
                  const Spacer(),
                  Icon(Iconfont.fromName('right'),
                      size: 14, color: AppColors.textHint),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// 构建联系人搜索结果项
  Widget _buildContactItem(Friend friend) {
    final keyword = controller.currentKeyword.value;
    final friendId = friend.friendId;
    final bool matchId = friendId.toLowerCase().contains(keyword.toLowerCase());

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing16, vertical: 4),
      leading: _buildAvatar(friend.fullAvatar, Iconfont.person),
      title: _buildHighlightedText(friend.name),
      subtitle: matchId && keyword.isNotEmpty
          ? _buildHighlightedText('ID: $friendId', isSubtitle: true)
          : null,
      onTap: () {
        Get.toNamed('${Routes.HOME}${Routes.FRIEND_PROFILE}',
            arguments: {'userId': friend.friendId});
      },
    );
  }

  /// 构建群组搜索结果项
  Widget _buildGroupItem(Chats chat) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing16, vertical: 4),
      leading: _buildAvatar(chat.fullAvatar, Iconfont.contacts),
      title: _buildHighlightedText(chat.name),
      onTap: () {
        Get.find<ChatController>().changeCurrentChat(chat);
      },
    );
  }

  /// 构建消息搜索结果项
  Widget _buildMessageResultItem(SearchMessageResult result) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing16, vertical: 4),
      leading: _buildAvatar(result.fullAvatar, Iconfont.message),
      title: Text(
        result.name,
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.font16,
            fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${result.messageCount} ${I18n.t('search.related_records')}',
        style: const TextStyle(
            color: AppColors.textHint, fontSize: AppSizes.font13),
      ),
      trailing:
          Icon(Iconfont.fromName('right'), size: 14, color: AppColors.textHint),
      onTap: () {
        // TODO: 跳转到该会话的消息详情搜索页
      },
    );
  }

  /// 构建头像
  Widget _buildAvatar(String url, IconData fallback) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radius8),
      child: Container(
        width: 44,
        height: 44,
        color: AppColors.background,
        child: url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Icon(fallback, color: AppColors.textHint, size: 24),
                errorWidget: (_, __, ___) =>
                    Icon(fallback, color: AppColors.textHint, size: 24),
              )
            : Icon(fallback, color: AppColors.textHint, size: 24),
      ),
    );
  }

  /// 构建关键词高亮的文本
  Widget _buildHighlightedText(String text, {bool isSubtitle = false}) {
    final keyword = controller.currentKeyword.value;
    final style = TextStyle(
      color: isSubtitle ? AppColors.textHint : AppColors.textPrimary,
      fontSize: isSubtitle ? AppSizes.font13 : AppSizes.font16,
      fontWeight: isSubtitle ? FontWeight.normal : FontWeight.w600,
    );

    if (keyword.isEmpty ||
        !text.toLowerCase().contains(keyword.toLowerCase())) {
      return Text(text, style: style);
    }

    final List<TextSpan> spans = [];
    final lowerText = text.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerKeyword);

    while (index != -1) {
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + keyword.length),
        style: const TextStyle(
            color: AppColors.primary, fontWeight: FontWeight.bold),
      ));
      start = index + keyword.length;
      index = lowerText.indexOf(lowerKeyword, start);
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(
        style: style,
        children: spans,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconfont.fromName('71shibai'),
              size: 70, color: AppColors.textHint.withOpacity(0.5)),
          const SizedBox(height: AppSizes.spacing16),
          Text(
            I18n.t('search.no_result'),
            style: const TextStyle(
                color: AppColors.textHint, fontSize: AppSizes.font15),
          ),
        ],
      ),
    );
  }

  /// 构建搜索历史
  Widget _buildSearchHistory(TextEditingController searchTextController) {
    return Obx(() {
      if (controller.searchHistory.isEmpty) {
        return const SizedBox();
      }
      return ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing16, vertical: AppSizes.spacing20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                I18n.t('search.history'),
                style: const TextStyle(
                  fontSize: AppSizes.font15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: controller.clearSearchHistory,
                child: const Icon(Icons.delete_outline,
                    size: 20, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing16),
          Wrap(
            spacing: AppSizes.spacing10,
            runSpacing: AppSizes.spacing10,
            children: controller.searchHistory.map((keyword) {
              return GestureDetector(
                onTap: () => controller.searchNow(keyword),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radius20),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(
                    keyword,
                    style: const TextStyle(
                        fontSize: AppSizes.font14,
                        color: AppColors.textSecondary),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    });
  }
}
