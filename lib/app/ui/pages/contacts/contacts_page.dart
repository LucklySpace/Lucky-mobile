import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../routes/app_routes.dart';
import '../../../controller/contact_controller.dart';
import '../../../models/friend.dart';
import '../../widgets/contacts/user_avatar_name.dart';

class ContactsPage extends GetView<ContactController> {
  const ContactsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '通讯录',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.font18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: AppSizes.iconMedium),
            onPressed: () {
              // TODO: 实现搜索功能
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add, size: AppSizes.iconMedium),
            onPressed: () {
              // TODO: 实现添加联系人功能
              Get.toNamed("${Routes.HOME}${Routes.ADD_FRIEND}");
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            _buildNewFriendItem(),
            Expanded(child: _buildFriendList(controller.contactsList)),
          ],
        );
      }),
    );
  }

  Widget _buildNewFriendItem() {
    return ListTile(
      leading: Container(
        width: AppSizes.spacing40,
        height: AppSizes.spacing40,
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(AppSizes.radius4),
        ),
        child: const Icon(
          Icons.person_add,
          color: AppColors.textWhite,
          size: AppSizes.iconMedium,
        ),
      ),
      title: const Text('新的朋友'),
      trailing: Obx(() => controller.newFriendRequestCount.value > 0
          ? Container(
              padding: const EdgeInsets.all(AppSizes.spacing4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${controller.newFriendRequestCount.value}',
                style: const TextStyle(color: AppColors.textWhite, fontSize: AppSizes.font12),
              ),
            )
          : const SizedBox()),
      onTap: () => {Get.toNamed("${Routes.HOME}${Routes.FRIEND_REQUESTS}")},
    );
  }

  Widget _buildFriendList(List<Friend> contactsList) {
    return ListView.builder(
      itemCount: contactsList.length,
      itemBuilder: (context, index) {
        final friend = contactsList[index];
        return UserAvatarName(
          avatar: friend.avatar,
          name: friend.name,
          onTap: () {
            Get.toNamed("${Routes.HOME}${Routes.FRIEND_PROFILE}",
                arguments: {'userId': friend.friendId});
          },
        );
      },
    );
  }
}
