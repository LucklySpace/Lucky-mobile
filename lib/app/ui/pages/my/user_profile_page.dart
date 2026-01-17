import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

import '../../../../config/app_config.dart';
import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../controller/user_controller.dart';
import '../../../models/user.dart';
import '../../widgets/crop/crop_image.dart';
import '../../widgets/icon/icon_font.dart';

/// 用户资料页面
/// 支持查看和编辑个人信息
class UserProfilePage extends GetView<UserController> {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用局部变量保持输入状态
    final usernameController = TextEditingController();
    final birthdayController = TextEditingController();
    final locationController = TextEditingController();
    final signatureController = TextEditingController();
    final gender = RxInt(-1);
    final avatarUrl = RxString("");

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (controller.isEditing.value) {
          controller.isEditing.value = false;
        }
      },
      child: Obx(() {
        final isEditing = controller.isEditing.value;
        final userInfo = controller.userInfo.value;

        // 非编辑模式下同步数据
        if (!isEditing) {
          usernameController.text = userInfo?.name ?? '';
          birthdayController.text = userInfo?.birthday ?? '';
          locationController.text = userInfo?.location ?? '';
          signatureController.text = userInfo?.selfSignature ?? '';
          gender.value = userInfo?.gender ?? -1;
          avatarUrl.value = userInfo?.avatar ?? '';
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(isEditing),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: AppSizes.spacing24),

                /// 头像区域
                _buildAvatarSection(context, avatarUrl.value, isEditing),

                const SizedBox(height: AppSizes.spacing32),

                /// 基本信息列表
                Container(
                  color: AppColors.surface,
                  child: Column(
                    children: [
                      _buildInfoTile(
                        label: '名字',
                        content: _buildTextField(usernameController, isEditing,
                            hint: '设置名字'),
                      ),
                      const Divider(
                          height: 1, indent: 20, color: AppColors.divider),
                      _buildInfoTile(
                        label: '性别',
                        content: isEditing
                            ? _buildGenderSelector(gender)
                            : Text(_getGenderText(gender.value),
                                style: _contentStyle),
                      ),
                      const Divider(
                          height: 1, indent: 20, color: AppColors.divider),
                      _buildInfoTile(
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
                      const Divider(
                          height: 1, indent: 20, color: AppColors.divider),
                      _buildInfoTile(
                        label: '地区',
                        content: _buildTextField(locationController, isEditing,
                            hint: '添加地区'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.spacing12),

                /// 个性签名区域
                Container(
                  width: double.infinity,
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(AppSizes.spacing20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('个性签名',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: AppSizes.spacing12),
                      isEditing
                          ? TextField(
                              controller: signatureController,
                              maxLines: 3,
                              maxLength: 50,
                              style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: '写点什么吧...',
                                hintStyle:
                                    const TextStyle(color: AppColors.textHint),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSizes.radius8),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: AppColors.background,
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
                                    ? AppColors.textHint
                                    : AppColors.textSecondary,
                              ),
                            ),
                    ],
                  ),
                ),

                if (isEditing) ...[
                  const SizedBox(height: AppSizes.spacing40),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.spacing32),
                    child: _buildSaveButton(
                      usernameController,
                      birthdayController,
                      locationController,
                      signatureController,
                      gender,
                      avatarUrl,
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.spacing40),
              ],
            ),
          ),
        );
      }),
    );
  }

  final TextStyle _contentStyle =
      const TextStyle(fontSize: 16, color: AppColors.textSecondary);

  /// 构建 AppBar
  AppBar _buildAppBar(bool isEditing) {
    return AppBar(
      title: const Text('个人资料'),
      centerTitle: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: AppColors.textPrimary, size: 20),
        onPressed: () => Get.back(),
      ),
      actions: [
        TextButton(
          onPressed: () => controller.isEditing.toggle(),
          child: Text(
            isEditing ? '取消' : '编辑',
            style: const TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// 构建头像区域
  Widget _buildAvatarSection(BuildContext context, String url, bool isEditing) {
    final fullUrl = AppConfig.getFullUrl(url);
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _viewFullImage(context, fullUrl),
            child: Hero(
              tag: 'user_avatar',
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radius20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  color: AppColors.surface,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radius20),
                  child: url.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: fullUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Icon(Iconfont.person,
                              size: 40, color: AppColors.textHint),
                          errorWidget: (context, url, error) => Icon(
                              Iconfont.person,
                              size: 40,
                              color: AppColors.textHint),
                        )
                      : Icon(Iconfont.person,
                          size: 50, color: AppColors.textHint),
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
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      size: 16, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoTile({required String label, required Widget content}) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing20, vertical: AppSizes.spacing16),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 16, color: AppColors.textPrimary)),
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

  /// 构建文本编辑框
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
        hintStyle: const TextStyle(color: AppColors.textHint),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  /// 构建可点击的选择字段
  Widget _buildClickableField(
      TextEditingController controller, String hint, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            controller.text.isEmpty ? hint : controller.text,
            style: TextStyle(
              fontSize: 16,
              color: controller.text.isEmpty
                  ? AppColors.textHint
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Iconfont.fromName('right'), size: 12, color: AppColors.textHint),
        ],
      ),
    );
  }

  /// 构建性别选择器
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

  /// 构建性别标签
  Widget _buildGenderChip(String label, int value, RxInt groupValue) {
    final isSelected = groupValue.value == value;
    return GestureDetector(
      onTap: () => groupValue.value = value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(AppSizes.radius20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 构建保存按钮
  Widget _buildSaveButton(
    TextEditingController usernameController,
    TextEditingController birthdayController,
    TextEditingController locationController,
    TextEditingController signatureController,
    RxInt gender,
    RxString avatarUrl,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () => _handleSave(
          usernameController,
          birthdayController,
          locationController,
          signatureController,
          gender,
          avatarUrl,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radius12)),
        ),
        child: const Text('保存修改',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
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
    if (usernameController.text.trim().isEmpty) {
      Get.snackbar('提示', '名字不能为空', snackPosition: SnackPosition.TOP);
      return;
    }

    final user = User(
      userId: controller.userId.value,
      name: usernameController.text.trim(),
      avatar: avatarUrl.value,
      birthday: birthdayController.text,
      location: locationController.text.trim(),
      gender: gender.value == -1 ? 1 : gender.value,
      selfSignature: signatureController.text.trim(),
    );

    await controller.updateUserInfo(user);
    controller.isEditing.value = false;
  }

  void _viewFullImage(BuildContext context, String avatarUrl) {
    if (avatarUrl.isEmpty) return;
    Get.to(() => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          body: PhotoView(
            imageProvider: CachedNetworkImageProvider(avatarUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.0,
          ),
        ));
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
                const SizedBox(height: 12),
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
                      child: const Icon(Icons.camera_alt, color: Colors.blue)),
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
                      child: const Icon(Icons.photo_library,
                          color: Colors.purple)),
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
      _cropImage(File(image.path));
    }
  }

  Future chooseImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      _cropImage(File(image.path));
    }
  }

  void _cropImage(File originalImage) async {
    try {
      final File? cropped =
          await CropperImage.crop(originalImage, AppConfig.cropImageTimeout);
      if (cropped != null) {
        final String? imageUrl = await controller.uploadImage(cropped);
        if (imageUrl != null) {
          // 这里可以根据业务逻辑处理上传后的 URL
        }
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
    }
  }

  Future<void> _selectBirthDate(TextEditingController controller) async {
    DateTime initialDate = DateTime.now();
    if (controller.text.isNotEmpty && controller.text != '未设置') {
      try {
        initialDate = DateTime.parse(controller.text);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.primary)),
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
