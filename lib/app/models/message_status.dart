/// 消息发送状态
///
/// 用于追踪消息从创建到成功发送的整个生命周期
enum MessageSendStatus {
  /// 创建中 - 消息对象已创建但未开始发送
  creating,

  /// 排队中 - 消息已加入发送队列，等待发送
  queued,

  /// 发送中 - 正在向服务器发送消息
  sending,

  /// 已发送 - 消息已成功发送到服务器，等待确认
  sent,

  /// 发送成功 - 服务器已确认收到消息
  success,

  /// 发送失败 - 消息发送失败，可重试
  failed,

  /// 已撤回 - 消息已被撤回
  recalled,
}

/// 消息发送优先级
///
/// 用于决定消息在队列中的发送顺序
enum MessagePriority {
  /// 低优先级 - 如普通文本消息
  low,

  /// 普通优先级 - 如图片消息
  normal,

  /// 高优先级 - 如系统消息、通知
  high,

  /// 紧急优先级 - 如视频通话邀请
  urgent,
}

/// 消息发送结果
///
/// 封装消息发送操作的结果信息
class MessageSendResult {
  /// 是否成功
  final bool isSuccess;

  /// 消息ID（客户端临时ID或服务端ID）
  final String messageId;

  /// 服务端返回的消息ID（如果成功）
  final String? serverMessageId;

  /// 错误信息（如果失败）
  final String? error;

  /// 错误代码（如果失败）
  final int? errorCode;

  const MessageSendResult({
    required this.isSuccess,
    required this.messageId,
    this.serverMessageId,
    this.error,
    this.errorCode,
  });

  /// 创建成功结果
  factory MessageSendResult.success({
    required String messageId,
    String? serverMessageId,
  }) {
    return MessageSendResult(
      isSuccess: true,
      messageId: messageId,
      serverMessageId: serverMessageId,
    );
  }

  /// 创建失败结果
  factory MessageSendResult.failure({
    required String messageId,
    required String error,
    int? errorCode,
  }) {
    return MessageSendResult(
      isSuccess: false,
      messageId: messageId,
      error: error,
      errorCode: errorCode,
    );
  }

  @override
  String toString() {
    return 'MessageSendResult{isSuccess: $isSuccess, messageId: $messageId, '
        'serverMessageId: $serverMessageId, error: $error, errorCode: $errorCode}';
  }
}

/// 可重试的发送任务
///
/// 封装消息发送任务，支持重试机制
class RetryableSendTask {
  /// 消息对象
  final dynamic message;

  /// 当前重试次数
  int retryCount;

  /// 最大重试次数
  final int maxRetries;

  /// 首次发送时间戳
  final int firstSendTime;

  /// 优先级
  final MessagePriority priority;

  /// 回调函数
  final Future<MessageSendResult> Function() sendFunction;

  RetryableSendTask({
    required this.message,
    required this.sendFunction,
    this.retryCount = 0,
    this.maxRetries = 3,
    int? firstSendTime,
    this.priority = MessagePriority.normal,
  }) : firstSendTime = firstSendTime ?? DateTime.now().millisecondsSinceEpoch;

  /// 是否可以重试
  bool get canRetry => retryCount < maxRetries;

  /// 是否已过期（超过30秒认为过期）
  bool get isExpired {
    final elapsed = DateTime.now().millisecondsSinceEpoch - firstSendTime;
    return elapsed > 30000; // 30秒
  }

  /// 增加重试次数
  void incrementRetry() {
    retryCount++;
  }

  /// 创建重试副本
  RetryableSendTask copyWithIncrementedRetry() {
    return RetryableSendTask(
      message: message,
      sendFunction: sendFunction,
      retryCount: retryCount + 1,
      maxRetries: maxRetries,
      firstSendTime: firstSendTime,
      priority: priority,
    );
  }
}
