// 定义消息类型枚举
enum IMessageType {
  error(-1, '信息异常'),
  loginOver(900, '登录过期'),
  refreshToken(999, '刷新token'),
  login(1000, '登录'),
  heartBeat(1001, '心跳'),
  forceLogout(1002, '强制下线'),
  singleMessage(1003, '私聊消息'),
  groupMessage(1004, '群发消息'),
  videoMessage(1005, '视频通话'),
  audioMessage(1006, '音频通话'),
  createGroup(1500, '创建群聊'),
  groupInvite(1501, '群聊邀请'),
  robot(2000, '机器人'),
  publicAccount(2001, '公众号'),
  messageAction(3000, '消息更新');

  // 定义字段
  final int code;
  final String description;

  int getCode() {
    return code;
  }

  // 构造函数
  const IMessageType(this.code, this.description);

  // 通过code获取MessageType的工厂方法
  static IMessageType? fromCode(int code) {
    return IMessageType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => IMessageType.error,
    );
  }
}

enum IMessageReadStatus {
  UNREAD(0, "未读"),
  ALREADY_READ(1, "已读"),
  RECALL(2, "已撤回");

  // 定义字段
  final int code;
  final String description;

  const IMessageReadStatus(this.code, this.description);
}

// 定义消息内容类型枚举
enum IMessageContentType {
// 定义消息内容类型枚举
  unknown(0, '未知'),
  text(1, '文字'),
  image(2, '图片'),
  video(3, '视频'),
  audio(4, '语音'),
  file(5, '文件'),
  location(6, '位置'),
  complex(7, '混合'),
  groupInvite(8, '群组邀请'),
  groupJoinApprove(9, '群组加入审批'),
  tip(10, '系统提示'),
  rtcCall(101, '呼叫'),
  rtcAccept(102, '接受'),
  rtcReject(103, '拒绝'),
  rtcCancel(104, '取消呼叫'),
  rtcFailed(105, '呼叫失败'),
  rtcHangup(106, '挂断'),
  rtcCandidate(107, '同步candidate');

  // 定义字段
  final int code;
  final String type;

  // 构造函数
  const IMessageContentType(this.code, this.type);

  // 通过code获取MessageContentType的工厂方法
  static IMessageContentType fromCode(int code) {
    return IMessageContentType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => IMessageContentType.unknown,
    );
  }
}
