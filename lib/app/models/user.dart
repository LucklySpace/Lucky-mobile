import '../../config/app_config.dart';

/// 用户信息模型
/// 对应后端 UserVo
class User {
  /// 用户ID
  final String userId;

  /// 用户名（登录名）
  final String? username;

  /// 昵称（显示名称）
  final String name;

  /// 头像URL
  final String avatar;

  /// 性别 (0: 未知, 1: 男, 2: 女)
  final int gender;

  /// 生日
  final String? birthday;

  /// 地区
  final String? location;

  /// 个性签名
  final String? selfSignature;

  /// 邮箱
  final String? email;

  /// 手机号
  final String? phone;

  /// 注册时间
  final int? createTime;

  /// 最后登录时间
  final int? lastLoginTime;

  const User({
    required this.userId,
    this.username,
    required this.name,
    required this.avatar,
    required this.gender,
    this.birthday,
    this.location,
    this.selfSignature,
    this.email,
    this.phone,
    this.createTime,
    this.lastLoginTime,
  });

  /// 从 JSON 解析
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId']?.toString() ?? '',
      username: json['username']?.toString(),
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      gender: json['gender'] is int
          ? json['gender']
          : int.tryParse(json['gender']?.toString() ?? '0') ?? 0,
      birthday: json['birthday']?.toString(),
      location: json['location']?.toString(),
      selfSignature: json['selfSignature']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      createTime: json['createTime'] is int
          ? json['createTime']
          : (json['createTime'] != null
              ? int.tryParse(json['createTime'].toString())
              : null),
      lastLoginTime: json['lastLoginTime'] is int
          ? json['lastLoginTime']
          : (json['lastLoginTime'] != null
              ? int.tryParse(json['lastLoginTime'].toString())
              : null),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'name': name,
      'avatar': avatar,
      'gender': gender,
      'birthday': birthday,
      'location': location,
      'selfSignature': selfSignature,
      'email': email,
      'phone': phone,
      'createTime': createTime,
      'lastLoginTime': lastLoginTime,
    };
  }

  /// 获取显示名称（优先使用昵称，用户名作为备选）
  String get displayName => name.isNotEmpty ? name : (username ?? '未知用户');

  /// 是否为男性
  bool get isMale => gender == 1;

  /// 是否为女性
  bool get isFemale => gender == 2;

  /// 获取完整头像URL
  String get fullAvatar => AppConfig.getFullUrl(avatar);

  @override
  String toString() => 'User(userId: $userId, name: $displayName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}
