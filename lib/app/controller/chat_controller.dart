import 'chat/chat_coordinator_controller.dart';

/// 聊天控制器（重构版）
///
/// ✨ 架构优化：
/// - 已拆分为多个专职控制器，遵循单一职责原则
/// - 通过协调器模式管理子控制器，避免循环依赖
/// - 完全向后兼容，现有代码无需修改
///
/// 📦 新架构：
/// - [ChatCoordinatorController]: 协调器，组合所有子控制器
/// - [ChatSessionController]: 会话管理
/// - [ChatMessageController]: 消息管理
/// - [ChatGroupController]: 群组管理
/// - [ChatVideoController]: 视频通话
/// - [ChatBaseController]: 基类，提供共享能力
///
/// 🎯 设计原则：
/// - 单一职责：每个控制器只负责一个领域
/// - 开闭原则：对扩展开放，对修改关闭
/// - 里氏替换：可以完全替代旧版本
/// - 依赖倒置：依赖抽象而非具体实现
/// - 接口隔离：提供最小必要的公共接口
///
/// 💡 使用建议：
/// - 对于简单场景，继续使用 ChatController
/// - 对于复杂场景，可以直接使用子控制器（如 ChatMessageController）
/// - 子控制器可以独立测试和复用
///
/// @see [ChatCoordinatorController] 协调器实现
/// @see [ChatSessionController] 会话管理
/// @see [ChatMessageController] 消息管理
/// @see [ChatGroupController] 群组管理
/// @see [ChatVideoController] 视频通话
class ChatController extends ChatCoordinatorController {
  // ✅ 所有功能已通过继承自 ChatCoordinatorController 获得
  // 无需重复实现，保持向后兼容

  // 如果需要添加特定功能，可以在此扩展
  // 例如：
  // - 自定义的业务逻辑
  // - 特定的性能优化
  // - 额外的回调处理
}
