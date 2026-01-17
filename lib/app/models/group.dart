/// 群组信息模型
/// 对应后端 GroupVo
class Group {
  /// 群组ID
  final String groupId;

  /// 群名称
  final String groupName;

  /// 群头像
  final String? groupAvatar;

  /// 群主ID
  final String ownerId;

  /// 群类型 (0: 普通群, 1: 企业群)
  final int? groupType;

  /// 群成员数量
  final int? memberCount;

  /// 群简介
  final String? introduction;

  /// 群公告
  final String? announcement;

  /// 创建时间
  final int? createTime;

  /// 入群方式 (0: 直接加入, 1: 需要审核)
  final int? joinType;

  /// 是否全员禁言 (0: 否, 1: 是)
  final int? muteAll;

  /// 群状态 (0: 正常, 1: 已解散)
  final int? status;

  const Group({
    required this.groupId,
    required this.groupName,
    this.groupAvatar,
    required this.ownerId,
    this.groupType,
    this.memberCount,
    this.introduction,
    this.announcement,
    this.createTime,
    this.joinType,
    this.muteAll,
    this.status,
  });

  /// 从 JSON 解析
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      groupId: json['groupId']?.toString() ?? '',
      groupName: json['groupName']?.toString() ?? '',
      groupAvatar: json['groupAvatar']?.toString(),
      ownerId: json['ownerId']?.toString() ?? '',
      groupType: json['groupType'] is int
          ? json['groupType']
          : (json['groupType'] != null
              ? int.tryParse(json['groupType'].toString())
              : null),
      memberCount: json['memberCount'] is int
          ? json['memberCount']
          : (json['memberCount'] != null
              ? int.tryParse(json['memberCount'].toString())
              : null),
      introduction: json['introduction']?.toString(),
      announcement: json['announcement']?.toString(),
      createTime: json['createTime'] is int
          ? json['createTime']
          : (json['createTime'] != null
              ? int.tryParse(json['createTime'].toString())
              : null),
      joinType: json['joinType'] is int
          ? json['joinType']
          : (json['joinType'] != null
              ? int.tryParse(json['joinType'].toString())
              : null),
      muteAll: json['muteAll'] is int
          ? json['muteAll']
          : (json['muteAll'] != null
              ? int.tryParse(json['muteAll'].toString())
              : null),
      status: json['status'] is int
          ? json['status']
          : (json['status'] != null
              ? int.tryParse(json['status'].toString())
              : null),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'groupAvatar': groupAvatar,
      'ownerId': ownerId,
      'groupType': groupType,
      'memberCount': memberCount,
      'introduction': introduction,
      'announcement': announcement,
      'createTime': createTime,
      'joinType': joinType,
      'muteAll': muteAll,
      'status': status,
    };
  }

  /// 是否为正常状态
  bool get isActive => status == 0 || status == null;

  /// 是否全员禁言
  bool get isAllMuted => muteAll == 1;

  @override
  String toString() =>
      'Group(groupId: $groupId, groupName: $groupName, memberCount: $memberCount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Group &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId;

  @override
  int get hashCode => groupId.hashCode;
}

/// 群组类型枚举
enum GroupType {
  normal(0, '普通群'),
  enterprise(1, '企业群');

  final int code;
  final String description;

  const GroupType(this.code, this.description);

  static GroupType fromCode(int? code) {
    return GroupType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => GroupType.normal,
    );
  }
}

/// 入群方式枚举
enum GroupJoinType {
  direct(0, '直接加入'),
  approval(1, '需要审核');

  final int code;
  final String description;

  const GroupJoinType(this.code, this.description);

  static GroupJoinType fromCode(int? code) {
    return GroupJoinType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => GroupJoinType.direct,
    );
  }
}

/// 群组状态枚举
enum GroupStatus {
  normal(0, '正常'),
  dismissed(1, '已解散');

  final int code;
  final String description;

  const GroupStatus(this.code, this.description);

  static GroupStatus fromCode(int? code) {
    return GroupStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => GroupStatus.normal,
    );
  }
}
