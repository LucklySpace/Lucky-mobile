import 'package:intl/intl.dart';

import '../config/app_config.dart';

class DateUtil {
  /// 格式化日期对象为指定格式的字符串
  /// [date] 需要格式化的日期对象
  /// [fmt] 格式化字符串，例如 "yyyy-MM-dd hh:mm:ss"
  /// 返回格式化后的日期字符串
  static String formatDate(DateTime date, String fmt) {
    // 定义一个 Map，存储需要替换的部分及对应的值
    Map<String, int> o = {
      "M+": date.month, // 月份（1-12）
      "d+": date.day, // 日
      "h+": date.hour, // 小时（0-23）
      "m+": date.minute, // 分钟
      "s+": date.second, // 秒
      "q+": ((date.month + 2) ~/ 3), // 季度（1-4）
      "S": date.millisecond, // 毫秒
    };

    // 替换年份部分，例如 "yyyy" 或 "yy"
    fmt = fmt.replaceAllMapped(RegExp(r'(y+)'), (Match m) {
      String yearStr = date.year.toString();
      int len = m.group(0)!.length;
      // 根据格式要求截取年份的后几位
      return yearStr.substring(yearStr.length - len);
    });

    // 遍历 Map 中的其他格式标识符，并进行替换
    o.forEach((k, v) {
      fmt = fmt.replaceAllMapped(RegExp('($k)'), (Match m) {
        String val = v.toString();
        // 如果格式标识符长度大于1，则在数字前面补零
        if (m.group(0)!.length > 1) {
          return val.padLeft(m.group(0)!.length, '0');
        } else {
          return val;
        }
      });
    });

    return fmt;
  }

  /// 根据时间戳获取用户友好的时间显示格式
  /// [timestamp] 时间戳（毫秒），例如：DateTime.now().millisecondsSinceEpoch
  /// [timeFormat] 需要显示的时间格式，例如 "yy/MM/dd"
  /// [mustIncludeTime] 显示日期时是否必须包含时间（小时和分钟）
  /// 返回友好的时间显示字符串
  static String getTimeToDisplay(
      int timestamp, String timeFormat, bool mustIncludeTime) {
    DateTime currentDate = DateTime.now();
    DateTime srcDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    int deltaTime = currentDate.millisecondsSinceEpoch - timestamp;
    String timeExtraStr =
        mustIncludeTime ? " " + formatDate(srcDate, "hh:mm") : "";

    // 如果时间差小于60秒，返回 "刚刚"
    if (deltaTime < 60 * 1000) return "刚刚";

    // 如果是同一天，则只显示时间
    if (currentDate.year == srcDate.year &&
        currentDate.month == srcDate.month &&
        currentDate.day == srcDate.day) {
      return formatDate(srcDate, "hh:mm");
    }

    // 简单计算日期差值（注意：跨月或跨年的情况可能需要更精确的处理）
    int dayDiff = currentDate.day - srcDate.day;
    if (dayDiff == 1) return "昨天" + timeExtraStr;
    if (dayDiff == 2) return "前天" + timeExtraStr;

    // 如果时间差小于7天，返回对应的星期几（中文）加上时间
    if (deltaTime < 7 * 24 * 3600 * 1000) {
      // Dart 中，weekday 返回 1（星期一）到 7（星期日）
      List<String> weekDays = ["星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日"];
      String weekday = weekDays[srcDate.weekday - 1];
      return weekday + timeExtraStr;
    }

    // 超过7天，则按照指定的格式返回日期，并附加时间（如果需要）
    return formatDate(srcDate, timeFormat) + timeExtraStr;
  }

  /// 判断是否需要显示时间
  /// [currentTime] 当前消息的时间
  /// [prevTime] 上一条消息的时间，如果为 null 则返回 true
  /// [showTime] 显示时间的间隔（分钟），默认为 5 分钟
  static bool shouldDisplayTime(dynamic currentTime, dynamic prevTime,
      {int showTime = AppConfig.messageTimeDisplayInterval}) {
    // 如果 prevTime 为 null，则返回 true
    if (prevTime == null) return true;

    // 将 currentTime 转换为 DateTime 类型
    DateTime currentDateTime;
    if (currentTime is int) {
      currentDateTime = DateTime.fromMillisecondsSinceEpoch(currentTime);
    } else if (currentTime is DateTime) {
      currentDateTime = currentTime;
    } else {
      throw ArgumentError(
          'currentTime must be either int (timestamp) or DateTime');
    }

    // 将 prevTime 转换为 DateTime 类型
    DateTime prevDateTime;
    if (prevTime is int) {
      prevDateTime = DateTime.fromMillisecondsSinceEpoch(prevTime);
    } else if (prevTime is DateTime) {
      prevDateTime = prevTime;
    } else {
      throw ArgumentError(
          'prevTime must be either int (timestamp) or DateTime');
    }

    // 计算当前消息与上一条消息的时间差（分钟）
    return currentDateTime.difference(prevDateTime).inMinutes >= showTime;
  }

  /// 获取当前时间
  static DateTime getCurrentTime() {
    return DateTime.now();
  }

  /// 解析字符串为日期
  static DateTime parseDate(String dateString, {String format = 'yyyy-MM-dd'}) {
    return DateFormat(format).parse(dateString);
  }

  /// 计算两个日期之间的天数差
  static int getDaysBetween(DateTime startDate, DateTime endDate) {
    return endDate.difference(startDate).inDays;
  }

  /// 判断两个日期是否为同一天
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 获取当前时间的字符串
  static String getCurrentTimeString({String format = 'yyyy-MM-dd HH:mm:ss'}) {
    return formatDate(DateTime.now(), format);
  }

  /// 获取某一天的开始时间（00:00:00）
  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 获取某一天的结束时间（23:59:59）
  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }
}

// 示例：如何使用
// void main() {
//   DateTime now = DateTime.now();
//   DateTime fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
//   DateTime threeMinutesAgo = now.subtract(const Duration(minutes: 3));

//   print(shouldDisplayTime(now, fiveMinutesAgo));    // 输出: true（正好5分钟）
//   print(shouldDisplayTime(now, threeMinutesAgo));     // 输出: false（小于5分钟）
//   print(shouldDisplayTime(now, null));                // 输出: true（第一条消息）
//   DateTime now = DateTime.now();
//   print("当前时间格式化: ${formatDate(now, "yyyy-MM-dd hh:mm:ss")}");

//   // 模拟一个过去的时间戳
//   int pastTimestamp =
//       now.subtract(const Duration(days: 2, hours: 3)).millisecondsSinceEpoch;
//   print("友好显示时间: ${getTimeToDisplay(pastTimestamp, "yy/MM/dd", true)}");
// }
