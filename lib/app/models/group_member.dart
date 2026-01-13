/// 群成员模型
/// 对应后端 GroupMemberVo
class GroupMember {
  /// 用户ID
  final String userId;

  /// 用户名称
  final String? name;

  /// 头像
  final String? avatar;

  /// 性别 (0: 未知, 1: 男, 2: 女)
  final int? gender;

  /// 生日
  final String? birthDay;

  /// 地区
  final String? location;

  /// 个性签名
  final String? selfSignature;

  /// 是否禁言 (0: 否, 1: 是)
  final int? mute;

  /// 群内昵称
  final String? alias;

  /// 角色 (0: 普通成员, 1: 管理员, 2: 群主)
  final int? role;

  /// 加入方式
  final String? joinType;

  const GroupMember({
    required this.userId,
    this.name,
    this.avatar,
    this.gender,
    this.birthDay,
    this.location,
    this.selfSignature,
    this.mute,
    this.alias,
    this.role,
    this.joinType,
  });

  /// 从 JSON 解析
  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['userId'] as String,
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      gender: json['gender'] as int?,
      birthDay: json['birthDay'] as String?,
      location: json['location'] as String?,
      selfSignature: json['selfSignature'] as String?,
      mute: json['mute'] as int?,
      alias: json['alias'] as String?,
      role: json['role'] as int?,
      joinType: json['joinType'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'avatar': avatar,
      'gender': gender,
      'birthDay': birthDay,
      'location': location,
      'selfSignature': selfSignature,
      'mute': mute,
      'alias': alias,
      'role': role,
      'joinType': joinType,
    };
  }

  /// 获取显示名称（优先使用群内昵称）
  String get displayName =>
      alias?.isNotEmpty == true ? alias! : (name ?? '未知用户');

  /// 是否为群主
  bool get isOwner => role == 2;

  /// 是否为管理员
  bool get isAdmin => role == 1;

  /// 是否被禁言
  bool get isMuted => mute == 1;

  @override
  String toString() =>
      'GroupMember(userId: $userId, name: $displayName, role: $role)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupMember &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}

/// 群成员角色枚举
enum GroupMemberRole {
  owner(0, '群主'),
  admin(1, '管理员'),
  member(3, '普通成员');

  final int code;
  final String description;

  const GroupMemberRole(this.code, this.description);

  static GroupMemberRole fromCode(int? code) {
    return GroupMemberRole.values.firstWhere(
      (role) => role.code == code,
      orElse: () => GroupMemberRole.member,
    );
  }
}
