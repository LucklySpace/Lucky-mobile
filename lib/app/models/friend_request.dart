/// 好友请求模型
/// 对应后端 FriendRequestVo
class FriendRequest {
  /// 请求ID
  final String id;

  /// 发送者用户ID
  final String fromId;

  /// 接收者用户ID
  final String toId;

  /// 发送者名称
  final String name;

  /// 发送者头像
  final String? avatar;

  /// 验证消息
  final String? message;

  /// 审批状态 (0: 待处理, 1: 已同意, 2: 已拒绝)
  final int approveStatus;

  /// 请求时间
  final int? createTime;

  /// 处理时间
  final int? handleTime;

  FriendRequest({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.name,
    this.avatar,
    this.message,
    required this.approveStatus,
    this.createTime,
    this.handleTime,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id']?.toString() ?? '',
      fromId: json['fromId']?.toString() ?? '',
      toId: json['toId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      message: json['message']?.toString(),
      approveStatus: json['approveStatus'] is int
          ? json['approveStatus']
          : (json['approveStatus'] != null
              ? int.tryParse(json['approveStatus'].toString())
              : 0),
      createTime: json['createTime'] is int
          ? json['createTime']
          : (json['createTime'] != null
              ? int.tryParse(json['createTime'].toString())
              : null),
      handleTime: json['handleTime'] is int
          ? json['handleTime']
          : (json['handleTime'] != null
              ? int.tryParse(json['handleTime'].toString())
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromId': fromId,
      'toId': toId,
      'name': name,
      'avatar': avatar,
      'message': message,
      'approveStatus': approveStatus,
      'createTime': createTime,
      'handleTime': handleTime,
    };
  }

  /// 是否待处理
  bool get isPending => approveStatus == 0;

  /// 是否已同意
  bool get isApproved => approveStatus == 1;

  /// 是否已拒绝
  bool get isRejected => approveStatus == 2;

  @override
  String toString() =>
      'FriendRequest(id: $id, fromId: $fromId, status: ${statusEnum.description})';

  FriendRequestStatus get statusEnum =>
      FriendRequestStatus.fromValue(approveStatus);
}

/// 好友请求状态枚举
enum FriendRequestStatus {
  pending(0, '待处理'),
  approved(1, '已同意'),
  rejected(2, '已拒绝');

  final int value;
  final String description;

  const FriendRequestStatus(this.value, this.description);

  static FriendRequestStatus fromValue(int value) {
    return FriendRequestStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => FriendRequestStatus.pending,
    );
  }
}
