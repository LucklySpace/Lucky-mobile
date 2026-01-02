import 'package:flutter/material.dart';
import 'package:flutter_im/constants/app_colors.dart';
import 'package:flutter_im/constants/app_sizes.dart';
import 'package:get/get.dart';


import '../../../controller/chat_controller.dart';
import '../../../controller/home_controller.dart';
import '../../widgets/badge/badge.dart';
import '../../widgets/icon/icon_font.dart';
import '../chat/chat_page.dart';
import '../contacts/contacts_page.dart';
import '../my/my_page.dart';

/// 首页，展示底部导航栏及对应的页面（消息、通讯录、我的）
/// 特性：
/// - 使用 IndexedStack 切换页面，保留页面状态。
/// - 底部导航栏显示未读消息数徽章。
/// - 支持响应式更新导航索引和未读消息状态。
class HomePage extends GetView<HomeController> {
  // 常量定义
  static const _navItems = [
    _NavItemData(icon: Iconfont.message, label: '消息', page: ChatPage()),
    _NavItemData(icon: Iconfont.contacts, label: '通讯录', page: ContactsPage()),
    _NavItemData(icon: Iconfont.my, label: '我的', page: MyPage()),
  ];

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final chatList = Get.find<ChatController>().chatList;

    return Scaffold(
      body: Obx(() => IndexedStack(
            index: controller.currentIndex.value,
            children: _navItems.map((item) => item.page).toList(),
          )),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.changeTabIndex,
            items: _buildNavItems(
                context, chatList, controller.currentIndex.value),
          )),
    );
  }

  // --- UI 构建方法 ---

  /// 构建底部导航栏项
  List<BottomNavigationBarItem> _buildNavItems(
      BuildContext context, RxList chatList, int currentIndex) {
    return _navItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      // 根据当前选中的索引设置图标颜色
      final iconColor = index == currentIndex
          ? Theme.of(context).colorScheme.primary
          : AppColors.textHint;

      // 计算未读消息数（仅对"消息"页面显示徽章）
      final unreadCount = index == 0
          ? chatList.fold(0, (sum, chat) => sum + chat.unread as int)
          : 0;
      return BottomNavigationBarItem(
        icon: CustomBadge(
          child:
              Iconfont.buildIcon(icon: item.icon, size: AppSizes.iconMedium, color: iconColor),
          count: unreadCount,
          max: 99,
        ),
        label: item.label,
      );
    }).toList();
  }
}

/// 导航项数据类，定义图标、标签和页面
class _NavItemData {
  final IconData icon;
  final String label;
  final Widget page;

  const _NavItemData({
    required this.icon,
    required this.label,
    required this.page,
  });
}
