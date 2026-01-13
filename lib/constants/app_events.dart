/// 事件常量定义
/// 供全局事件总线使用
/// 对应前端 ts/index.ts 中的 Events

/// 事件常量类
class AppEvents {
  // 私有构造函数，防止实例化
  AppEvents._();

  // ==================== 好友相关事件 ====================

  /// 好友备注更新
  static const String friendRemarkUpdated = 'friend:remarkUpdated';

  // ==================== 群组相关事件 ====================

  /// 群组重命名
  static const String groupRenamed = 'group:renamed';

  /// 群公告变更
  static const String groupNoticeChanged = 'group:noticeChanged';

  // ==================== 聊天相关事件 ====================

  /// 会话变更
  static const String chatChanged = 'chat:changed';
}
