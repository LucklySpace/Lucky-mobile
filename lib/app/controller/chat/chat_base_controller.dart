import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:get_storage/get_storage.dart';

import '../../../constants/app_message.dart';
import '../../../routes/app_routes.dart';
import '../../core/base/base_controller.dart';
import '../../core/handlers/error_handler.dart';
import '../../database/app_database.dart';
import '../../models/message_receive.dart';
import '../../services/event_bus_service.dart';

/// 聊天控制器基类
///
/// 职责：
/// - 提供共享依赖（数据库、API服务、存储等）
/// - 提供通用方法和工具函数
/// - 避免子控制器之间重复代码
///
/// 设计原则：
/// - 单一职责：只负责提供基础能力
/// - 开闭原则：对扩展开放，对修改关闭
/// - 依赖倒置：依赖抽象而非具体实现
abstract class ChatBaseController extends BaseController {
  // ==================== 共享依赖 ====================

  /// 数据库实例
  final AppDatabase db = GetIt.instance<AppDatabase>();

  /// 本地存储
  final GetStorage storage = GetStorage();

  /// 事件总线
  final EventBus eventBus = Get.find<EventBus>();

  /// 常量
  static const int successCode = 200;
  static const String keyUserId = 'userId';

  // ==================== 响应式状态 ====================

  /// 当前用户ID
  final Rx<String> userId = ''.obs;

  // ==================== 生命周期 ====================

  @override
  void onInit() {
    super.onInit();
    getUserId();
  }

  /// 从本地存储获取用户ID
  void getUserId() {
    final storedUserId = storage.read(keyUserId);
    if (storedUserId != null && storedUserId.toString().isNotEmpty) {
      userId.value = storedUserId.toString();
      Get.log('✅ 用户ID已加载: ${userId.value}');
    } else {
      Get.log('⚠️ 未找到存储的用户ID');
    }
  }

  // ==================== API响应处理 ====================

  /// 显示错误提示
  @override
  void showError(dynamic error) {
    if (error is String) {
      super.showError(error);
    } else {
      ErrorHandler.handle(error);
    }
  }

  // ==================== 消息工具方法 ====================

  /// 判断是否为单聊消息
  bool isSingleMessage(IMessage message) {
    return message.messageType == MessageType.singleMessage.code;
  }

  /// 判断是否为群聊消息
  bool isGroupMessage(IMessage message) {
    return message.messageType == MessageType.groupMessage.code;
  }

  /// 获取消息目标ID
  ///
  /// 单聊：返回对方ID（如果我是发送者，返回接收者ID，否则返回发送者ID）
  /// 群聊：返回群组ID
  String? getMessageTargetId(IMessage message) {
    if (isSingleMessage(message)) {
      final singleMessage = IMessage.toSingleMessage(message, userId.value);
      return singleMessage.fromId == userId.value
          ? message.toId
          : singleMessage.fromId;
    } else if (isGroupMessage(message)) {
      final groupMessage = IMessage.toGroupMessage(message, userId.value);
      return groupMessage.groupId;
    }
    return null;
  }

  // ==================== 路由跳转工具 ====================

  /// 打开搜索页面
  void openSearch() {
    Get.toNamed('${Routes.HOME}${Routes.SEARCH}');
  }

  /// 打开扫一扫页面
  void openScan() {
    Get.toNamed('${Routes.HOME}${Routes.SCAN}');
  }

  /// 打开添加好友页面
  void openAddFriend() {
    Get.toNamed('${Routes.HOME}${Routes.ADD_FRIEND}');
  }
}
