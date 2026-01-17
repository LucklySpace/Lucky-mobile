/// 用户在线状态模型
class OnlineStatus {
  /// 用户ID
  final String userId;

  /// 在线状态 (0: 离线, 1: 在线, 2: 忙碌, 3: 隐身)
  final int status;

  /// 最后在线时间戳
  final int? lastSeen;

  /// 设备类型 (mobile, desktop, web)
  final String? device;

  /// 状态更新时间
  final int? updateTime;

  OnlineStatus({
    required this.userId,
    required this.status,
    this.lastSeen,
    this.device,
    this.updateTime,
  });

  factory OnlineStatus.fromJson(Map<String, dynamic> json) {
    return OnlineStatus(
      userId: json['userId']?.toString() ?? '',
      status: json['status'] is int
          ? json['status']
          : int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      lastSeen: json['lastSeen'] is int
          ? json['lastSeen']
          : (json['lastSeen'] != null
              ? int.tryParse(json['lastSeen'].toString())
              : null),
      device: json['device']?.toString(),
      updateTime: json['updateTime'] is int
          ? json['updateTime']
          : (json['updateTime'] != null
              ? int.tryParse(json['updateTime'].toString())
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'status': status,
      'lastSeen': lastSeen,
      'device': device,
      'updateTime': updateTime,
    };
  }

  /// 是否在线
  bool get isOnline => status == 1;

  /// 是否离线
  bool get isOffline => status == 0;

  /// 是否忙碌
  bool get isBusy => status == 2;

  /// 是否隐身
  bool get isInvisible => status == 3;

  @override
  String toString() =>
      'OnlineStatus(userId: $userId, status: ${statusEnum.description})';

  OnlineStatusEnum get statusEnum => OnlineStatusEnum.fromValue(status);
}

/// 在线状态枚举
enum OnlineStatusEnum {
  offline(0, '离线'),
  online(1, '在线'),
  busy(2, '忙碌'),
  invisible(3, '隐身');

  final int value;
  final String description;

  const OnlineStatusEnum(this.value, this.description);

  static OnlineStatusEnum fromValue(int value) {
    return OnlineStatusEnum.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OnlineStatusEnum.offline,
    );
  }
}

/// 设备类型枚举
enum DeviceType {
  mobile('mobile', '手机'),
  desktop('desktop', '电脑'),
  web('web', '网页'),
  tablet('tablet', '平板');

  final String code;
  final String description;

  const DeviceType(this.code, this.description);

  static DeviceType fromCode(String? code) {
    return DeviceType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => DeviceType.mobile,
    );
  }
}
