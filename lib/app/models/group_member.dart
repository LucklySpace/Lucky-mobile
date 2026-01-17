/// 群成员模型
/// 对应后端 GroupMemberVo
class GroupMember {
  /// 用户ID
  final String memberId;

  /// 用户名称
  final String name;

  /// 头像
  final String avatar;

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

  /// 角色 (0: 群主, 1: 管理员, 2: 普通成员)
  final int? role;

  /// 加入方式
  final String? joinType;

  const GroupMember({
    required this.memberId,
    required this.name,
    required this.avatar,
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
      memberId: json['memberId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      gender: _parseIntSafely(json['gender']),
      birthDay: json['birthDay']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      selfSignature: json['selfSignature']?.toString() ?? '',
      mute: _parseIntSafely(json['mute']),
      alias: json['alias']?.toString() ?? '',
      role: _parseIntSafely(json['role']),
      joinType: json['joinType']?.toString() ?? '',
    );
  }

  /// 辅助方法：安全解析整数
  static int _parseIntSafely(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is bool) return value ? 1 : 0;
    return 0;
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
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
      alias?.isNotEmpty == true ? alias! : (name.isNotEmpty ? name : '未知用户');

  /// 是否为群主
  bool get isOwner => role == 0;

  /// 是否为管理员
  bool get isAdmin => role == 1;

  /// 是否为普通成员
  bool get isMember => role == 2;

  /// 是否被禁言
  bool get isMuted => mute == 1;

  @override
  String toString() =>
      'GroupMember(memberId: $memberId, name: $displayName, role: $role)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupMember &&
          runtimeType == other.runtimeType &&
          memberId == other.memberId;

  @override
  int get hashCode => memberId.hashCode;
}

/// 群成员角色枚举
enum GroupMemberRole {
  owner(0, '群主'),
  admin(1, '管理员'),
  member(2, '普通成员');

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
