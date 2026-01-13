import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_im/constants/app_colors.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

import '../../../../config/app_config.dart';
import '../../../controller/user_controller.dart';
import '../../../models/User.dart';
import '../../widgets/crop/crop_image.dart';

/// 用户资料页面
class UserProfilePage extends GetView<UserController> {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 初始化控制器
    final usernameController = TextEditingController();
    final birthdayController = TextEditingController();
    final locationController = TextEditingController();
    final signatureController = TextEditingController();

    final gender = RxInt(-1);
    final avatarUrl = RxString("");

    return WillPopScope(
      onWillPop: () async {
        if (controller.isEditing.value) {
          controller.isEditing.value = false;
          return false;
        }
        return true;
      },
      child: Obx(() {
        final isEditing = controller.isEditing.value;
        final userInfo = controller.userInfo;

        // 非编辑模式下同步数据
        if (!isEditing) {
          usernameController.text = userInfo['name'] as String? ?? '';
          birthdayController.text = userInfo['birthday'] as String? ?? '';
          locationController.text = userInfo['location'] as String? ?? '';
          signatureController.text = userInfo['selfSignature'] as String? ?? '';
          gender.value = userInfo['gender'] as int? ?? -1;
          avatarUrl.value = userInfo['avatar'] as String? ?? '';
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6F8), // 浅灰背景
          appBar: _buildAppBar(isEditing),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // 头像区域
                _buildAvatarSection(context, avatarUrl.value, isEditing),

                const SizedBox(height: 32),

                // 基本信息卡片
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildListTile(
                        label: '用户名',
                        content: _buildTextField(usernameController, isEditing,
                            hint: '设置用户名'),
                      ),
                      _buildDivider(),
                      _buildListTile(
                        label: '性别',
                        content: isEditing
                            ? _buildGenderSelector(gender)
                            : Text(_getGenderText(gender.value),
                                style: _contentStyle),
                      ),
                      _buildDivider(),
                      _buildListTile(
                        label: '生日',
                        content: isEditing
                            ? _buildClickableField(birthdayController, '选择日期',
                                () => _selectBirthDate(birthdayController))
                            : Text(
                                birthdayController.text.isEmpty
                                    ? '未设置'
                                    : birthdayController.text,
                                style: _contentStyle),
                      ),
                      _buildDivider(),
                      _buildListTile(
                        label: '地区',
                        content: _buildTextField(locationController, isEditing,
                            hint: '添加地区'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 个性签名卡片
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('个性签名',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      isEditing
                          ? TextField(
                              controller: signatureController,
                              maxLines: 4,
                              maxLength: 50,
                              style: const TextStyle(fontSize: 15, height: 1.5),
                              decoration: InputDecoration(
                                hintText: '写点什么...',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                contentPadding: const EdgeInsets.all(12),
                                counterText: "",
                              ),
                            )
                          : Text(
                              signatureController.text.isEmpty
                                  ? '暂无签名'
                                  : signatureController.text,
                              style: TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: signatureController.text.isEmpty
                                      ? Colors.grey
                                      : const Color(0xFF4A4A4A)),
                            ),
                    ],
                  ),
                ),

                if (isEditing) ...[
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _handleSave(
                            usernameController,
                            birthdayController,
                            locationController,
                            signatureController,
                            gender,
                            avatarUrl),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 2,
                          shadowColor: AppColors.primary.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text('保存修改',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        );
      }),
    );
  }

  // --- 样式定义 ---
  final TextStyle _labelStyle = const TextStyle(
      fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary);

  final TextStyle _contentStyle =
      const TextStyle(fontSize: 16, color: Color(0xFF4A4A4A));

  // --- 组件构建 ---

  AppBar _buildAppBar(bool isEditing) {
    return AppBar(
      title: const Text('个人资料'),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      actions: [
        TextButton(
          onPressed: () {
            controller.isEditing.toggle();
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          child: Text(isEditing ? '取消' : '编辑'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAvatarSection(BuildContext context, String url, bool isEditing) {
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _viewFullImage(context, url),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24), // 圆角矩形
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: url.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: Icon(Icons.person,
                              size: 40, color: Color(0xFFE0E0E0)),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.person,
                              size: 40, color: Color(0xFFE0E0E0)),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.person,
                            size: 50, color: Color(0xFFE0E0E0)),
                      ),
              ),
            ),
          ),
          if (isEditing)
            Positioned(
              right: -4,
              bottom: -4,
              child: GestureDetector(
                onTap: _changeAvatar,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]),
                  child: const Icon(Icons.camera_alt,
                      size: 16, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListTile({required String label, required Widget content}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: _labelStyle),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: content,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, bool isEditing,
      {String? hint}) {
    if (!isEditing) {
      return Text(
        controller.text.isEmpty ? '未设置' : controller.text,
        style: _contentStyle,
        overflow: TextOverflow.ellipsis,
      );
    }

    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      style: _contentStyle,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildClickableField(
      TextEditingController controller, String hint, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            controller.text.isEmpty ? hint : controller.text,
            style: TextStyle(
                fontSize: 16,
                color: controller.text.isEmpty
                    ? Colors.grey[400]
                    : const Color(0xFF4A4A4A)),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildGenderSelector(RxInt gender) {
    return Obx(() => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGenderChip('男', 1, gender),
            const SizedBox(width: 12),
            _buildGenderChip('女', 0, gender),
          ],
        ));
  }

  Widget _buildGenderChip(String label, int value, RxInt groupValue) {
    final isSelected = groupValue.value == value;
    return GestureDetector(
      onTap: () => groupValue.value = value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
        height: 1,
        thickness: 0.5,
        indent: 20,
        endIndent: 20,
        color: Color(0xFFEEEEEE));
  }

  // --- 逻辑处理 ---

  Future<void> _handleSave(
    TextEditingController usernameController,
    TextEditingController birthdayController,
    TextEditingController locationController,
    TextEditingController signatureController,
    RxInt gender,
    RxString avatarUrl,
  ) async {
    // 检查用户名
    if (usernameController.text.trim().isEmpty) {
      Get.snackbar('提示', '用户名不能为空', snackPosition: SnackPosition.TOP);
      return;
    }

    // 更新头像URL（如果已更改）
    if (avatarUrl.isNotEmpty &&
        controller.userInfo['avatar'] != avatarUrl.value) {
      avatarUrl.value = controller.userInfo['avatar'];
    }

    final user = User(
        userId: controller.userId.value,
        name: usernameController.text.trim(),
        avatar: avatarUrl.value,
        birthday: birthdayController.text,
        location: locationController.text.trim(),
        gender: gender.value == -1 ? 1 : gender.value,
        // 默认为男
        selfSignature: signatureController.text.trim());

    await controller.updateUserInfo(user);
    controller.isEditing.value = false;
  }

  void _viewFullImage(BuildContext context, String avatarUrl) {
    if (avatarUrl.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: PhotoView(
              imageProvider: CachedNetworkImageProvider(avatarUrl),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2.0,
            ),
          ),
        ),
      ),
    );
  }

  String _getGenderText(int? gender) {
    switch (gender) {
      case 0:
        return '女';
      case 1:
        return '男';
      default:
        return '未设置';
    }
  }

  Future<void> _changeAvatar() async {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.blue[50], shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.blue),
                  ),
                  title: const Text('拍摄照片',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    getImage();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.purple[50], shape: BoxShape.circle),
                    child:
                        const Icon(Icons.photo_library, color: Colors.purple),
                  ),
                  title: const Text('从相册选取',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    chooseImage();
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future getImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      cropImage(File(image.path));
    }
  }

  Future chooseImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      cropImage(File(image.path));
    }
  }

  void cropImage(File originalImage) async {
    try {
      final File? cropped =
          await CropperImage.crop(originalImage, AppConfig.cropImageTimeout);
      if (cropped != null) {
        final String? imageUrl = await controller.uploadImage(cropped);
        if (imageUrl != null) {
          controller.userInfo['avatar'] = imageUrl;
          controller.userInfo.refresh();
        }
      }
    } catch (e) {
      debugPrint('Error creating CropperImage: $e');
    }
  }

  Future<void> _selectBirthDate(TextEditingController controller) async {
    DateTime initialDate;
    if (controller.text.isNotEmpty && controller.text != '未设置') {
      try {
        List<String> parts = controller.text.split('-');
        if (parts.length == 3) {
          initialDate = DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        } else {
          initialDate = DateTime.now();
        }
      } catch (e) {
        initialDate = DateTime.now();
      }
    } else {
      initialDate = DateTime.now();
    }

    if (initialDate.isAfter(DateTime.now())) initialDate = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }
}
