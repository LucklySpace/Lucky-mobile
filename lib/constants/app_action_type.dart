/// IM 操作类型枚举
/// 对应前端 MessageActionType.ts
///
/// 设计原则：
/// - 1-99: 消息相关
/// - 70+: 表情/反应
/// - 200-299: 群组成员/权限操作
/// - 300-399: 好友/联系人
/// - 600-699: 文件/传输
/// - 900-999: 系统/管理

/// IM 操作类型枚举
enum ActionType {
  // ========== 消息相关（1 - 99）==========
  /// 发送消息
  sendMessage(1, '发送消息'),

  /// 编辑消息
  editMessage(2, '编辑消息'),

  /// 删除消息
  deleteMessage(3, '删除消息'),

  /// 撤回消息
  recallMessage(4, '撤回消息'),

  /// 回复消息
  replyMessage(5, '回复消息'),

  /// 转发消息
  forwardMessage(6, '转发消息'),

  /// 已读回执
  markRead(7, '已读回执'),

  /// 正在输入
  typing(8, '正在输入'),

  /// 引用消息
  messageQuote(9, '引用消息'),

  // ========== 表情 / 反应（70+）==========
  /// 添加表情反应
  reactionAdd(70, '添加表情反应'),

  /// 移除表情反应
  reactionRemove(71, '移除表情反应'),

  // ========== 群组成员 / 权限操作（200 - 299）==========
  /// 创建群组
  createGroup(200, '创建群组'),

  /// 群组邀请
  inviteToGroup(201, '群组邀请'),

  /// 成员加入群组
  joinGroup(202, '成员加入群组'),

  /// 主动退出群组
  leaveGroup(203, '主动退出群组'),

  /// 移除群成员
  kickFromGroup(204, '移除群成员'),

  /// 设置管理员
  promoteToAdmin(205, '设置管理员'),

  /// 取消管理员
  demoteFromAdmin(206, '取消管理员'),

  /// 移交群主
  transferGroupOwner(207, '移交群主'),

  /// 修改群信息
  setGroupInfo(208, '修改群信息'),

  /// 设置群公告
  setGroupAnnouncement(209, '设置群公告'),

  /// 设置群加入方式
  setGroupJoinMode(210, '设置群加入方式'),

  /// 批准入群申请
  approveJoinRequest(211, '批准入群申请'),

  /// 拒绝入群申请
  rejectJoinRequest(212, '拒绝入群申请'),

  /// 群组加入审批
  joinApproveGroup(213, '群组加入审批'),

  /// 群组加入审批结果
  joinApproveResultGroup(214, '群组加入审批结果'),

  /// 单人禁言
  muteMember(215, '单人禁言'),

  /// 取消禁言
  unmuteMember(216, '取消禁言'),

  /// 全员禁言
  muteAll(217, '全员禁言'),

  /// 取消全员禁言
  unmuteAll(218, '取消全员禁言'),

  /// 设置群成员角色
  setMemberRole(219, '设置群成员角色'),

  /// 解散/删除群组
  removeGroup(220, '解散/删除群组'),

  // ========== 好友 / 联系人（300 - 399）==========
  /// 添加好友
  addFriend(300, '添加好友'),

  /// 删除好友
  removeFriend(301, '删除好友'),

  /// 拉黑用户
  blockUser(302, '拉黑用户'),

  /// 解除拉黑
  unblockUser(303, '解除拉黑'),

  /// 好友请求
  friendRequest(304, '好友请求'),

  // ========== 文件/传输（600 - 699）==========
  /// 文件上传
  uploadFile(600, '文件上传'),

  /// 文件下载
  downloadFile(601, '文件下载'),

  /// 文件分享
  shareFile(602, '文件分享'),

  /// 分片上传
  chunkUpload(603, '分片上传'),

  /// 分片合并完成
  chunkComplete(604, '分片合并完成'),

  // ========== 系统 / 管理（900 - 999）==========
  /// 系统通知
  systemNotification(900, '系统通知'),

  /// 平台管理操作
  moderationAction(901, '平台管理操作'),

  /// 审计日志记录
  auditLog(902, '审计日志记录'),

  /// 未知操作
  unknown(-1, '未知操作');

  final int code;
  final String description;

  const ActionType(this.code, this.description);

  /// 通过 code 获取 ActionType
  static ActionType fromCode(int code) {
    return ActionType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => ActionType.unknown,
    );
  }

  /// 判断是否为消息相关操作（code 1-99）
  bool get isMessageAction => code >= 1 && code <= 99;

  /// 判断是否为表情反应操作（code 70-79）
  bool get isReactionAction => code >= 70 && code <= 79;

  /// 判断是否为群组操作（code 200-299）
  bool get isGroupAction => code >= 200 && code <= 299;

  /// 判断是否为好友/联系人操作（code 300-399）
  bool get isFriendAction => code >= 300 && code <= 399;

  /// 判断是否为文件传输操作（code 600-699）
  bool get isFileTransferAction => code >= 600 && code <= 699;

  /// 判断是否为系统管理操作（code 900-999）
  bool get isSystemAction => code >= 900 && code <= 999;
}
