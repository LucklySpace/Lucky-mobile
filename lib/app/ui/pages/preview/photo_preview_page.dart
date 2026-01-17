import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// 图片预览页面
/// 支持多图预览、缩放、保存
class PhotoPreviewPage extends StatefulWidget {
  const PhotoPreviewPage({Key? key}) : super(key: key);

  @override
  State<PhotoPreviewPage> createState() => _PhotoPreviewPageState();
}

class _PhotoPreviewPageState extends State<PhotoPreviewPage> {
  late int currentIndex;
  late List<String> galleryItems;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    // 隐藏状态栏和虚拟按键
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    // 获取传递的参数
    final args = Get.arguments as Map<String, dynamic>;
    galleryItems = List<String>.from(args['images'] ?? []);
    currentIndex = args['index'] ?? 0;
    pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    // 彻底恢复状态栏和导航栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      // 让图片延伸到状态栏
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   iconTheme: const IconThemeData(color: Colors.white),
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back_ios_new),
      //     onPressed: () => Get.back(),
      //   ),
      //   centerTitle: true,
      //   // title: Text(
      //   //   '${currentIndex + 1} / ${galleryItems.length}',
      //   //   style: const TextStyle(color: Colors.white, fontSize: AppSizes.font16),
      //   // ),
      //   // actions: [
      //   //   IconButton(
      //   //     icon: const Icon(Icons.download_rounded),
      //   //     onPressed: _saveImage,
      //   //     tooltip: '保存图片',
      //   //   ),
      //   // ],
      // ),
      body: Container(
        constraints: BoxConstraints.expand(
          height: MediaQuery.of(context).size.height,
        ),
        child: PhotoViewGallery.builder(
          scrollPhysics: const BouncingScrollPhysics(),
          builder: _buildItem,
          itemCount: galleryItems.length,
          loadingBuilder: (context, event) => Center(
            child: SizedBox(
              width: 20.0,
              height: 20.0,
              child: CircularProgressIndicator(
                value: event == null
                    ? 0
                    : event.cumulativeBytesLoaded /
                        (event.expectedTotalBytes ?? 1),
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          pageController: pageController,
          onPageChanged: _onPageChanged,
          enableRotation: false, // 禁用旋转
        ),
      ),
    );
  }

  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) {
    final String item = galleryItems[index];
    return PhotoViewGalleryPageOptions(
      imageProvider: CachedNetworkImageProvider(item),
      initialScale: PhotoViewComputedScale.contained,
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 2.5,
      heroAttributes: PhotoViewHeroAttributes(tag: item),
      onTapUp: (context, details, controllerValue) async {
        // 退出预览时，先恢复状态栏和导航栏，再进行路由跳转
        // 这样可以避免返回后的页面在系统 UI 弹出时产生布局跳动
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
            overlays: SystemUiOverlay.values);
        Get.back();
      },
    );
  }

  /// 保存图片逻辑 (TODO: 实现具体的保存逻辑)
  void _saveImage() async {
    // 这里可以接入保存图片到相册的逻辑
    // 需要 permission_handler 和 image_gallery_saver 等插件
    // 暂时仅做提示
    Get.snackbar(
      '提示',
      '长按图片或点击下载按钮保存功能开发中',
      snackPosition: SnackPosition.TOP,
      colorText: Colors.white,
      backgroundColor: Colors.black54,
      margin: const EdgeInsets.all(20),
    );
  }
}
