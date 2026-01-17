/// 消息相关常量定义
/// 与前端 TypeScript 常量保持一致
/// 参考: lib/constants/ts/MessageType.ts, MessageContentType.ts

// ==================== 消息类型枚举 ====================

/// 消息类型枚举
/// 对应前端 MessageType.ts
enum MessageType {
  // 协议/响应
  error(-1, '协议错误/非法数据包'),
  success(0, '成功响应'),

  // 登录相关 (1-99)
  login(1, '登录'),
  logout(2, '退出登录'),
  loginExpired(3, '登录过期'),
  refreshToken(4, '刷新Token'),
  forceLogout(5, '强制下线'),
  tokenError(6, 'Token错误'),
  notLogin(7, '未登录'),

  // 系统相关 (100-199)
  register(100, '注册'),
  heartBeat(101, '心跳'),
  connect(102, '建立连接'),
  disconnect(103, '断开连接'),
  duplicateLogin(104, '异地登录'),
  presenceUpdate(105, '在线状态更新'),
  lastSeenUpdate(106, '最后在线时间更新'),
  loginFailedTooManyTimes(107, '登录失败次数过多'),
  registerSuccess(120, '注册成功'),
  registerFailed(121, '注册失败'),
  heartBeatSuccess(130, '心跳成功'),
  heartBeatFailed(131, '心跳失败'),

  // RTC 通话 (500-599)
  rtcStartAudioCall(500, '发起语音通话'),
  rtcStartVideoCall(501, '发起视频通话'),
  rtcAccept(502, '接受通话'),
  rtcReject(503, '拒绝通话'),
  rtcCancel(504, '取消通话'),
  rtcFailed(505, '通话失败'),
  rtcHangup(506, '挂断通话'),
  rtcCandidate(507, '同步Candidate'),
  rtcOffline(508, '对方离线'),

  // 消息类型 (1000-1099)
  singleMessage(1000, '私聊消息'),
  groupMessage(1001, '群聊消息'),
  videoMessage(1002, '视频消息'),
  systemMessage(1003, '系统消息'),
  broadcastMessage(1004, '广播消息'),

  // 用户类型 (2000-2099)
  user(2000, '普通用户'),
  robot(2001, '机器人'),
  publicAccount(2002, '公众号'),
  customerService(2003, '客服'),

  // 未知
  unknown(9999, '未知指令');

  final int code;
  final String description;

  const MessageType(this.code, this.description);

  /// 通过 code 获取 MessageType
  static MessageType fromCode(int code) {
    return MessageType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => MessageType.unknown,
    );
  }

  /// 是否为登录相关类型
  bool get isLoginRelated => code >= 1 && code <= 99;

  /// 是否为 RTC 通话类型
  bool get isRtcType => code >= 500 && code <= 599;

  /// 是否为消息类型
  bool get isMessageType => code >= 1000 && code <= 1099;
}

// ==================== 消息内容类型枚举 ====================

/// 消息内容类型枚举
/// 对应前端 MessageContentType.ts
///
/// 设计原则：
/// - 0: 系统提示
/// - 1-99: 文本类
/// - 100-199: 媒体类
/// - 200-299: 文件/二进制
/// - 300-399: 富媒体/结构化内容
/// - 400+: 其它/保留
enum MessageContentType {
  // ========== 系统 / 提示 ==========
  tip(0, '系统提示'),

  // ========== 文本类（1-99）==========
  text(1, '纯文本'),
  markdown(2, 'Markdown 文本'),
  richText(3, '富文本'),

  // ========== 媒体（100-199）==========
  image(100, '图片'),
  gif(101, '动画图片'),
  video(110, '视频'),
  audio(120, '语音/音频'),
  sticker(130, '贴纸/表情包'),

  // ========== 文件 / 二进制（200-299）==========
  file(200, '文件'),
  archive(201, '压缩包'),
  document(202, '文档'),

  // ========== 富媒体 / 结构化内容（300-399）==========
  location(300, '位置'),
  contactCard(310, '名片'),
  urlPreview(320, '链接预览'),
  poll(330, '投票'),
  forward(340, '转发内容'),

  // ========== 群组（400-499）==========
  groupInvite(400, '群聊邀请'),
  groupJoinApprove(401, '群组审批'),

  // ========== 其它 / 保留 ==========
  complex(500, '混合消息'),
  recall(501, '撤回消息'),
  edit(502, '编辑消息'),
  unknown(999, '未知类型'),
  ;

  final int code;
  final String description;

  const MessageContentType(this.code, this.description);

  /// 通过 code 获取 MessageContentType
  static MessageContentType fromCode(int code) {
    return MessageContentType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => MessageContentType.unknown,
    );
  }

  /// 是否为文本类消息（code 1-99）
  bool get isTextType => code >= 1 && code <= 99;

  /// 是否为媒体类消息（code 100-199）
  bool get isMediaType => code >= 100 && code <= 199;

  /// 是否为文件类消息（code 200-299）
  bool get isFileType => code >= 200 && code <= 299;

  /// 是否为富媒体/结构化内容消息（code 300-399）
  bool get isRichMediaType => code >= 300 && code <= 399;

  /// 是否为 RTC 通话内容类型
  bool get isRtcType => code >= 1001 && code <= 1007;
}

// ==================== 消息状态枚举 ====================

/// 消息已读状态枚举
enum MessageStatus {
  // ignore: constant_identifier_names
  UNREAD(0, '未读'),
  // ignore: constant_identifier_names
  ALREADY_READ(1, '已读'),
  // ignore: constant_identifier_names
  RECALL(2, '已撤回');

  final int code;
  final String description;

  const MessageStatus(this.code, this.description);

  /// 通过 code 获取 MessageStatus
  static MessageStatus fromCode(int code) {
    return MessageStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => MessageStatus.UNREAD,
    );
  }
}

/// 兼容旧版本的别名
typedef IMessageReadStatus = MessageStatus;

// ==================== 消息发送状态枚举 ====================

/// 消息状态枚举
enum MessageSendCode {
  success(0, '成功'),
  failed(1, '失败'),
  sending(2, '发送中'),
  other(3, '其它异常');

  final int code;
  final String description;

  const MessageSendCode(this.code, this.description);

  /// 通过 code 获取 MessageSendCode
  static MessageSendCode fromCode(int code) {
    return MessageSendCode.values.firstWhere(
      (status) => status.code == code,
      orElse: () => MessageSendCode.other,
    );
  }
}

// ==================== 视频通话相关枚举 ====================

/// 视频通话主被叫枚举
enum VideoMaster {
  caller(0, '呼叫方'),
  accept(1, '接收方');

  final int code;
  final String description;

  const VideoMaster(this.code, this.description);

  /// 通过 code 获取 VideoMaster
  static VideoMaster fromCode(int code) {
    return VideoMaster.values.firstWhere(
      (master) => master.code == code,
      orElse: () => VideoMaster.caller,
    );
  }
}

/// 视频通话连接状态枚举
enum ConnectionStatus {
  connecting(100, '正在连接'),
  disconnected(200, '未连接'),
  connected(300, '连接中'),
  connectionRefused(400, '拒绝连接'),
  connectionLost(500, '连接断开'),
  cancelled(600, '取消连接'),
  closed(700, '连接关闭'),
  error(800, '连接错误');

  final int code;
  final String description;

  const ConnectionStatus(this.code, this.description);

  /// 通过 code 获取 ConnectionStatus
  static ConnectionStatus fromCode(int code) {
    return ConnectionStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => ConnectionStatus.error,
    );
  }

  /// 是否为已连接状态
  bool get isConnected => this == ConnectionStatus.connected;

  /// 是否为断开状态
  bool get isDisconnected =>
      this == ConnectionStatus.disconnected ||
      this == ConnectionStatus.connectionLost ||
      this == ConnectionStatus.closed;

  /// 是否为错误状态
  bool get isError =>
      this == ConnectionStatus.error ||
      this == ConnectionStatus.connectionRefused;
}
