/// 黑名单用户模型
/// 对应后端 BlacklistUser
class BlacklistUser {
  /// 用户ID
  final String userId;

  /// 用户名称
  final String? name;

  /// 头像
  final String? avatar;

  /// 性别 (0: 未知, 1: 男, 2: 女)
  final int? gender;

  /// 地区
  final String? location;

  /// 个性签名
  final String? selfSignature;

  /// 添加到黑名单的时间
  final int? addTime;

  const BlacklistUser({
    required this.userId,
    this.name,
    this.avatar,
    this.gender,
    this.location,
    this.selfSignature,
    this.addTime,
  });

  /// 从 JSON 解析
  factory BlacklistUser.fromJson(Map<String, dynamic> json) {
    return BlacklistUser(
      userId: json['userId'] as String,
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      gender: json['gender'] as int?,
      location: json['location'] as String?,
      selfSignature: json['selfSignature'] as String?,
      addTime: json['addTime'] is int
          ? json['addTime']
          : (json['addTime'] != null
              ? int.tryParse(json['addTime'].toString())
              : null),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'avatar': avatar,
      'gender': gender,
      'location': location,
      'selfSignature': selfSignature,
      'addTime': addTime,
    };
  }

  @override
  String toString() => 'BlacklistUser(userId: $userId, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlacklistUser &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}
