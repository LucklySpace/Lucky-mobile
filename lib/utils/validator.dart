import '../constants/app_constant.dart';

/// 数据验证工具类
///
/// 提供常用的数据验证方法，包括：
/// - 手机号验证
/// - 邮箱验证
/// - URL验证
/// - 文件大小验证
/// - 文本长度验证
class Validator {
  // 私有构造函数，防止实例化
  Validator._();

  // ==================== 基础验证 ====================

  /// 验证是否为空
  static bool isEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// 验证是否非空
  static bool isNotEmpty(String? value) {
    return !isEmpty(value);
  }

  // ==================== 手机号验证 ====================

  /// 验证手机号（中国大陆）
  static bool isValidPhone(String? phone) {
    if (isEmpty(phone)) return false;
    final regex = RegExp(AppConstants.regexPhoneChina);
    return regex.hasMatch(phone!);
  }

  /// 获取手机号验证错误信息
  static String? validatePhone(String? phone) {
    if (isEmpty(phone)) {
      return '请输入手机号';
    }
    if (!isValidPhone(phone)) {
      return '请输入正确的手机号格式';
    }
    return null;
  }

  // ==================== 邮箱验证 ====================

  /// 验证邮箱
  static bool isValidEmail(String? email) {
    if (isEmpty(email)) return false;
    final regex = RegExp(AppConstants.regexEmail);
    return regex.hasMatch(email!);
  }

  /// 获取邮箱验证错误信息
  static String? validateEmail(String? email) {
    if (isEmpty(email)) {
      return '请输入邮箱';
    }
    if (!isValidEmail(email)) {
      return '请输入正确的邮箱格式';
    }
    return null;
  }

  // ==================== URL验证 ====================

  /// 验证URL
  static bool isValidUrl(String? url) {
    if (isEmpty(url)) return false;
    final regex = RegExp(AppConstants.regexUrl);
    return regex.hasMatch(url!);
  }

  /// 获取URL验证错误信息
  static String? validateUrl(String? url) {
    if (isEmpty(url)) {
      return '请输入URL';
    }
    if (!isValidUrl(url)) {
      return '请输入正确的URL格式';
    }
    return null;
  }

  // ==================== 密码验证 ====================

  /// 验证密码强度
  ///
  /// 要求：
  /// - 长度6-20位
  /// - 可包含字母、数字、特殊字符
  static bool isValidPassword(String? password) {
    if (isEmpty(password)) return false;
    final length = password!.length;
    return length >= 6 && length <= 20;
  }

  /// 验证密码强度（强）
  ///
  /// 要求：
  /// - 长度8-20位
  /// - 必须包含字母和数字
  /// - 可包含特殊字符
  static bool isStrongPassword(String? password) {
    if (isEmpty(password)) return false;
    final regex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*?&]{8,20}$');
    return regex.hasMatch(password!);
  }

  /// 获取密码验证错误信息
  static String? validatePassword(String? password, {bool strong = false}) {
    if (isEmpty(password)) {
      return '请输入密码';
    }
    if (strong) {
      if (!isStrongPassword(password)) {
        return '密码长度8-20位，需包含字母和数字';
      }
    } else {
      if (!isValidPassword(password)) {
        return '密码长度6-20位';
      }
    }
    return null;
  }

  // ==================== 文本长度验证 ====================

  /// 验证文本长度
  static bool isValidLength(String? text, {int? min, int? max}) {
    if (isEmpty(text)) return min == null || min == 0;
    final length = text!.length;
    if (min != null && length < min) return false;
    if (max != null && length > max) return false;
    return true;
  }

  /// 获取文本长度验证错误信息
  static String? validateLength(
    String? text, {
    int? min,
    int? max,
    String? fieldName,
  }) {
    final name = fieldName ?? '输入内容';

    if (isEmpty(text)) {
      if (min != null && min > 0) {
        return '请输入$name';
      }
      return null;
    }

    final length = text!.length;

    if (min != null && length < min) {
      return '$name不能少于$min个字符';
    }

    if (max != null && length > max) {
      return '$name不能超过$max个字符';
    }

    return null;
  }

  /// 验证消息长度
  static String? validateMessageLength(String? message) {
    return validateLength(
      message,
      min: 1,
      max: AppConstants.maxMessageLength,
      fieldName: '消息',
    );
  }

  /// 验证昵称长度
  static String? validateNickname(String? nickname) {
    return validateLength(
      nickname,
      min: 1,
      max: AppConstants.maxNicknameLength,
      fieldName: '昵称',
    );
  }

  /// 验证群名称长度
  static String? validateGroupName(String? groupName) {
    return validateLength(
      groupName,
      min: 1,
      max: AppConstants.maxGroupNameLength,
      fieldName: '群名称',
    );
  }

  // ==================== 文件大小验证 ====================

  /// 验证文件大小
  static bool isValidFileSize(int size, int maxSize) {
    return size > 0 && size <= maxSize;
  }

  /// 验证图片大小
  static String? validateImageSize(int size) {
    if (size <= 0) {
      return '图片文件无效';
    }
    if (size > AppConstants.maxImageSize) {
      final maxMB = AppConstants.maxImageSize ~/ (1024 * 1024);
      return '图片大小不能超过${maxMB}MB';
    }
    return null;
  }

  /// 验证视频大小
  static String? validateVideoSize(int size) {
    if (size <= 0) {
      return '视频文件无效';
    }
    if (size > AppConstants.maxVideoSize) {
      final maxMB = AppConstants.maxVideoSize ~/ (1024 * 1024);
      return '视频大小不能超过${maxMB}MB';
    }
    return null;
  }

  /// 验证文件大小
  static String? validateFileSize(int size) {
    if (size <= 0) {
      return '文件无效';
    }
    if (size > AppConstants.maxFileSize) {
      final maxMB = AppConstants.maxFileSize ~/ (1024 * 1024);
      return '文件大小不能超过${maxMB}MB';
    }
    return null;
  }

  // ==================== 数字验证 ====================

  /// 验证是否为整数
  static bool isInteger(String? value) {
    if (isEmpty(value)) return false;
    return int.tryParse(value!) != null;
  }

  /// 验证是否为浮点数
  static bool isDouble(String? value) {
    if (isEmpty(value)) return false;
    return double.tryParse(value!) != null;
  }

  /// 验证数字范围
  static bool isInRange(num? value, {num? min, num? max}) {
    if (value == null) return false;
    if (min != null && value < min) return false;
    if (max != null && value > max) return false;
    return true;
  }

  // ==================== 身份证验证 ====================

  /// 验证身份证号（中国大陆）
  static bool isValidIdCard(String? idCard) {
    if (isEmpty(idCard)) return false;

    // 15位或18位身份证号
    final regex = RegExp(r'^\d{15}$|^\d{17}[\dXx]$');
    if (!regex.hasMatch(idCard!)) return false;

    // TODO: 可以添加更严格的校验逻辑（如校验位验证）
    return true;
  }

  // ==================== 银行卡验证 ====================

  /// 验证银行卡号
  static bool isValidBankCard(String? cardNumber) {
    if (isEmpty(cardNumber)) return false;

    // 银行卡号通常为16-19位数字
    final regex = RegExp(r'^\d{16,19}$');
    return regex.hasMatch(cardNumber!);
  }
}
