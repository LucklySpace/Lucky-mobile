import 'package:floor/floor.dart';

import '../../config/app_config.dart';

/// 好友关系模型（数据库表：friend）
///
/// 对应后端 FriendVo
/// 使用联合主键：userId + friendId
@Entity(
  tableName: 'friend',
  primaryKeys: ['userId', 'friendId'],
  indices: [
    Index(value: ['userId', 'friendId', 'name']),
  ],
)
class Friend {
  /// 用户ID（主键之一，必填）
  String userId;

  /// 好友ID（主键之一，必填）
  String friendId;

  /// 好友名称（必填）
  String name;

  /// 备注名（别名）
  String? alias;

  /// 头像URL
  String? avatar;

  /// 性别 (0: 未知, 1: 男, 2: 女)
  int? gender;

  /// 地区
  String? location;

  /// 是否拉黑 (1: 正常, 2: 已拉黑)
  int? black;

  /// 标志位
  int? flag;

  /// 生日
  String? birthday;

  /// 个性签名
  String? selfSignature;

  /// 序列号（用于增量同步）
  int? sequence;

  Friend({
    required this.userId,
    required this.friendId,
    required this.name,
    this.alias,
    this.avatar,
    this.gender,
    this.location,
    this.black,
    this.flag,
    this.birthday,
    this.selfSignature,
    this.sequence,
  });

  /// 从 JSON 解析
  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      userId: json['userId']?.toString() ?? '',
      friendId: json['friendId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      alias: json['alias']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      gender: json['gender'] is int
          ? json['gender']
          : (json['gender'] != null
              ? int.tryParse(json['gender'].toString() ?? '')
              : null),
      location: json['location']?.toString() ?? '',
      black: json['black'] is int
          ? json['black']
          : (json['black'] != null
              ? int.tryParse(json['black'].toString() ?? '')
              : null),
      flag: json['flag'] is int
          ? json['flag']
          : (json['flag'] != null
              ? int.tryParse(json['flag'].toString() ?? '')
              : null),
      birthday: json['birthday']?.toString() ?? '',
      selfSignature: json['selfSignature']?.toString() ?? '',
      sequence: json['sequence'] is int
          ? json['sequence']
          : (json['sequence'] != null
              ? int.tryParse(json['sequence'].toString() ?? '')
              : null),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'friendId': friendId,
      'name': name,
      'alias': alias,
      'avatar': avatar,
      'gender': gender,
      'location': location,
      'black': black,
      'flag': flag,
      'birthday': birthday,
      'selfSignature': selfSignature,
      'sequence': sequence,
    };
  }

  /// 获取显示名称（优先使用备注名）
  String get displayName => alias?.isNotEmpty == true ? alias! : name;

  /// 是否已拉黑
  bool get isBlacklisted => black == 2;

  /// 是否为正常状态
  bool get isNormal => black != 2;

  /// 获取完整头像URL
  String get fullAvatar => AppConfig.getFullUrl(avatar);

  @override
  String toString() =>
      'Friend(userId: $userId, friendId: $friendId, name: $displayName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Friend &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          friendId == other.friendId;

  @override
  int get hashCode => userId.hashCode ^ friendId.hashCode;
}
