import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../routes/app_routes.dart';
import '../../../../utils/i18n_util.dart';

/// 搜索页面
///
/// 提供聊天记录搜索功能，支持实时搜索、历史记录展示和结果列表。
/// 使用 GetX 响应式状态管理，自动处理加载、结果和空状态。
/// 搜索框支持自动焦点，历史标签可点击填充并搜索。
class SearchPage extends GetView<SearchController> {
  const SearchPage({super.key});

  /// 构建搜索页面 UI
  @override
  Widget build(BuildContext context) {
    final searchTextController = TextEditingController();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(searchTextController),
      body: _buildBody(searchTextController),
    );
  }

  /// 构建顶部 AppBar，包含搜索框和取消按钮
  PreferredSizeWidget _buildAppBar(TextEditingController searchTextController) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Expanded(child: _buildSearchField(searchTextController)),
          _buildCancelButton(),
        ],
      ),
    );
  }

  /// 构建搜索输入框，支持自动焦点和提交搜索
  Widget _buildSearchField(TextEditingController searchTextController) {
    return Container(
      height: AppSizes.spacing32,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius4),
        border: Border.all(color: AppColors.border, width: AppSizes.spacing1),
      ),
      child: TextField(
        controller: searchTextController,
        autofocus: true,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: I18n.t('search.chat_records'),
          hintStyle: const TextStyle(color: AppColors.textHint),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing8, vertical: 0),
          isDense: true,
          prefixIcon: const Icon(Icons.search,
              color: AppColors.textHint, size: AppSizes.font18),
          prefixIconConstraints: const BoxConstraints(
              minWidth: AppSizes.spacing40, minHeight: AppSizes.spacing32),
        ),
        style: const TextStyle(fontSize: AppSizes.font16),
        //onSubmitted: controller.performSearch,
      ),
    );
  }

  /// 构建取消按钮
  Widget _buildCancelButton() {
    return TextButton(
      onPressed: () => Get.toNamed('${Routes.HOME}'),
      style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing8)),
      child: Text(I18n.t('cancel')),
    );
  }

  /// 构建页面主体，根据搜索状态显示加载、历史或结果
  Widget _buildBody(TextEditingController searchTextController) {
    return Column(
      children: [
        // Expanded(
        //   // child: Obx(() {
        //   //   // if (controller.isSearching.value) {
        //   //   //   return const Center(child: CircularProgressIndicator());
        //   //   // }
        //   //   // if (controller.searchResults.isEmpty) {
        //   //   //   return _buildSearchHistory(searchTextController);
        //   //   // }
        //   //   // return _buildSearchResults();
        //   // }),
        // ),
      ],
    );
  }

  /// 构建搜索结果列表
  ///
  /// 显示匹配用户的头像、名称和消息计数，支持分隔线和错误图像处理。
// Widget _buildSearchResults() {
//   return ListView.separated(
//     padding: const EdgeInsets.all(AppSizes.spacing16),
//     itemCount: controller.searchResults.length,
//     separatorBuilder: (context, index) => const Divider(
//       height: 0.5,
//       thickness: 0.5,
//       color: AppColors.divider,
//     ),
//     itemBuilder: (context, index) {
//       final result = controller.searchResults[index];
//       return SizedBox(
//         height: 48,
//         child: Row(
//           children: [
//             const SizedBox(width: AppSizes.spacing12),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(AppSizes.radius4),
//               child: Image.network(
//                 result.avatar,
//                 width: 32,
//                 height: 32,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) => Container(
//                   width: 32,
//                   height: 32,
//                   decoration: BoxDecoration(
//                     color: AppColors.background,
//                     borderRadius: BorderRadius.circular(AppSizes.radius4),
//                   ),
//                   child: const Icon(Icons.person, size: 16, color: AppColors.textHint),
//                 ),
//               ),
//             ),
//             const SizedBox(width: AppSizes.spacing12),
//             Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(result.name, style: const TextStyle(fontSize: AppSizes.font14)),
//                   const SizedBox(height: AppSizes.spacing2),
//                   Text(
//                     '${result.messageCount}${I18n.t('search.related_records')}',
//                     style: const TextStyle(fontSize: AppSizes.font12, color: AppColors.textHint),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: AppSizes.spacing12),
//           ],
//         ),
//       );
//     },
//   );
// }
//
// /// 构建搜索历史区域
// ///
// /// 支持历史标签展示、点击填充搜索框并触发搜索、清除历史功能。
// Widget _buildSearchHistory(TextEditingController searchTextController) {
//   return Obx(() {
//     if (controller.searchHistory.isEmpty) {
//       return Center(
//         child: Text(I18n.t('search.no_history'), style: const TextStyle(color: AppColors.textHint)),
//       );
//     }
//     return ListView(
//       padding: const EdgeInsets.all(AppSizes.spacing16),
//       children: [
//         _buildHistoryHeader(),
//         const SizedBox(height: AppSizes.spacing8),
//         _buildHistoryTags(searchTextController),
//       ],
//     );
//   });
// }
//
// /// 构建历史标题和清除按钮
// Widget _buildHistoryHeader() {
//   return Row(
//     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//     children: [
//       Text(
//         I18n.t('search.history'),
//         style: const TextStyle(fontSize: AppSizes.font16, fontWeight: FontWeight.bold),
//       ),
//       IconButton(
//         icon: const Icon(Icons.delete_outline),
//         onPressed: controller.clearSearchHistory,
//       ),
//     ],
//   );
// }
//
// /// 构建历史标签 Wrap 布局
// Widget _buildHistoryTags(TextEditingController searchTextController) {
//   return Wrap(
//     spacing: AppSizes.spacing8,
//     runSpacing: AppSizes.spacing8,
//     children: controller.searchHistory.map((keyword) {
//       return ActionChip(
//         label: Text(keyword, style: const TextStyle(fontSize: AppSizes.font14)),
//         backgroundColor: AppColors.background,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius16)),
//         onPressed: () {
//           searchTextController.text = keyword;
//           controller.performSearch(keyword);
//         },
//       );
//     }).toList(),
//   );
// }
}
