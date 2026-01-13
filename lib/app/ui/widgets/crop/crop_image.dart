import 'dart:io';

import 'package:flutter_im/constants/app_sizes.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../../../constants/app_colors.dart';

/// 头像裁剪组件
///
/// 封装 image_cropper 库，提供可靠的头像裁剪功能。
/// 支持圆形/方形裁剪、平台适配（Android/iOS UI 定制）、
/// 错误处理（取消/失败返回 null）和异步返回裁剪后的 File。
/// 可靠性增强：添加超时检查、文件存在验证和异常捕获。
class CropperImage {
  /// 裁剪头像
  ///
  /// [sourceFile] 原图像文件（File）
  /// [aspectRatio] 裁剪比例，默认 1:1（正方形）
  /// [cropStyle] 裁剪样式，默认圆形（适合头像）
  /// [maxWidth] 最大输出宽度，默认 512px
  /// [maxHeight] 最大输出高度，默认 512px
  /// [compressQuality] 压缩质量，默认 90%
  /// 返回: 裁剪后的 File 或 null（取消/失败）
  static Future<File?> crop(
    File sourceFile,
    int timeout, {
    double? aspectRatio = 1.0,
    CropStyle cropStyle = CropStyle.circle,
    int maxWidth = 512,
    int maxHeight = 512,
    int compressQuality = 90,
  }) async {
    try {
      // 验证源文件存在
      if (!await sourceFile.exists()) {
        Get.snackbar('错误', '源图像文件不存在');
        return null;
      }

      // 调用 image_cropper 裁剪
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: sourceFile.path,
        aspectRatio: CropAspectRatio(ratioX: aspectRatio!, ratioY: 1.0),
        //cropStyle: cropStyle,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        compressQuality: compressQuality,
        compressFormat: ImageCompressFormat.png,
        // 默认 JPG 格式
        uiSettings: [
          // Android UI 配置：自定义颜色/标题，确保主题一致
          AndroidUiSettings(
            toolbarTitle: '裁剪头像',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: AppColors.textWhite,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: true,
            // 隐藏底部工具栏
            dimmedLayerColor: AppColors.textPrimary,
            showCropGrid: false,
            cropFrameColor: AppColors.primary,
            cropFrameStrokeWidth: AppSizes.spacing2.toInt(),
          ),
          // iOS UI 配置：自定义标题/按钮
          IOSUiSettings(
            title: '裁剪头像',
            cancelButtonTitle: '取消',
            doneButtonTitle: '完成',
            aspectRatioLockEnabled: true,
            rectX: 0,
            rectY: 0,
            rectWidth: Get.width,
            rectHeight: Get.width,
            rotateButtonsHidden: true,
            resetButtonHidden: true,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      ).timeout(Duration(seconds: timeout)); // 超时保护，防止卡住

      // 处理结果
      if (croppedFile == null) {
        return null; // 用户取消
      }

      final File resultFile = File(croppedFile.path);
      if (await resultFile.exists() && await resultFile.length() > 0) {
        return resultFile;
      } else {
        Get.snackbar('错误', '裁剪文件无效');
        return null;
      }
    } catch (e) {
      Get.snackbar('错误', '裁剪失败: $e');
      return null;
    }
  }
}
