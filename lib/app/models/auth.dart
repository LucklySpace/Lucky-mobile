/// 登录请求模型
class LoginRequest {
  final String username;
  final String password;
  final String? deviceId;
  final String? deviceType;

  LoginRequest({
    required this.username,
    required this.password,
    this.deviceId,
    this.deviceType,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      if (deviceId != null) 'deviceId': deviceId,
      if (deviceType != null) 'deviceType': deviceType,
    };
  }
}

/// 登录响应模型
class LoginResponse {
  final String accessToken;
  final String? refreshToken;
  final String userId;
  final String username;
  final String? avatar;
  final int? expireTime;

  LoginResponse({
    required this.accessToken,
    required this.userId,
    required this.username,
    this.refreshToken,
    this.avatar,
    this.expireTime,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      refreshToken: json['refreshToken']?.toString() ?? '',
      expireTime: json['expireTime'] is int
          ? json['expireTime']
          : (json['expireTime'] != null
              ? int.tryParse(json['expireTime'].toString())
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'userId': userId,
      'username': username,
      'avatar': avatar,
      'refreshToken': refreshToken,
      'expireTime': expireTime,
    };
  }
}

/// 注册请求模型
class RegisterRequest {
  final String username;
  final String password;
  final String? phone;
  final String? email;
  final String? verificationCode;

  RegisterRequest({
    required this.username,
    required this.password,
    this.phone,
    this.email,
    this.verificationCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (verificationCode != null) 'verificationCode': verificationCode,
    };
  }
}

/// 短信验证码请求
class SmsRequest {
  final String phone;
  final String? type; // login, register, reset_password

  SmsRequest({
    required this.phone,
    this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      if (type != null) 'type': type,
    };
  }
}

/// 二维码响应模型
class QRCodeResponse {
  final String qrCode;
  final String? qrId;
  final int? expireTime;

  QRCodeResponse({
    required this.qrCode,
    this.qrId,
    this.expireTime,
  });

  factory QRCodeResponse.fromJson(Map<String, dynamic> json) {
    return QRCodeResponse(
      qrCode: json['qrCode']?.toString() ?? '',
      qrId: json['qrId']?.toString(),
      expireTime: json['expireTime'] is int
          ? json['expireTime']
          : (json['expireTime'] != null
              ? int.tryParse(json['expireTime'].toString())
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'qrCode': qrCode,
      'qrId': qrId,
      'expireTime': expireTime,
    };
  }
}

/// 扫码登录请求
class ScanQRCodeRequest {
  final String qrId;
  final String? deviceId;

  ScanQRCodeRequest({
    required this.qrId,
    this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'qrId': qrId,
      if (deviceId != null) 'deviceId': deviceId,
    };
  }
}

/// 二维码状态响应
class QRCodeStatusResponse {
  final int status; // 0: 待扫描, 1: 已扫描, 2: 已确认, 3: 已取消, 4: 已过期
  final String? userId;
  final String? username;
  final String? avatar;

  QRCodeStatusResponse({
    required this.status,
    this.userId,
    this.username,
    this.avatar,
  });

  factory QRCodeStatusResponse.fromJson(Map<String, dynamic> json) {
    return QRCodeStatusResponse(
      status: json['status'] is int
          ? json['status']
          : int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      userId: json['userId']?.toString(),
      username: json['username']?.toString(),
      avatar: json['avatar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'userId': userId,
      'username': username,
      'avatar': avatar,
    };
  }
}

/// 二维码状态枚举
enum QRCodeStatus {
  pending(0, '待扫描'),
  scanned(1, '已扫描'),
  confirmed(2, '已确认'),
  cancelled(3, '已取消'),
  expired(4, '已过期');

  final int code;
  final String description;

  const QRCodeStatus(this.code, this.description);

  static QRCodeStatus fromCode(int code) {
    return QRCodeStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => QRCodeStatus.pending,
    );
  }
}
