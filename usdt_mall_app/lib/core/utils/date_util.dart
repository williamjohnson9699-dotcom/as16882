import 'package:intl/intl.dart';

/// 日期时间工具类
class DateUtil {
  /// 格式化日期时间为本地时间
  ///
  /// 后端返回的时间格式通常为: "2024-01-01 12:00:00" 或 "2024-01-01T12:00:00"
  /// 后端返回的时间是UTC时间，需要转换为本地时间显示
  ///
  /// 参数:
  /// - dateTime: 日期时间字符串或DateTime对象
  /// - format: 输出格式，默认为 "yyyy-MM-dd HH:mm"
  ///
  /// 返回: 格式化后的本地时间字符串
  static String formatDateTime(dynamic dateTime, {String format = 'yyyy-MM-dd HH:mm'}) {
    if (dateTime == null) return '';

    try {
      DateTime dt;

      if (dateTime is DateTime) {
        dt = dateTime;
      } else {
        String dateTimeStr = dateTime.toString().trim();

        // 如果字符串包含 'T'，替换为空格以统一格式
        dateTimeStr = dateTimeStr.replaceAll('T', ' ');

        // 移除可能存在的时区信息（如 +08:00, Z 等）
        dateTimeStr = dateTimeStr.split('+')[0].split('Z')[0].trim();

        // 解析为UTC时间，然后转换为本地时间
        dt = _parseAsUtc(dateTimeStr).toLocal();
      }

      // 使用 intl 包格式化日期时间
      final formatter = DateFormat(format);
      return formatter.format(dt);
    } catch (e) {
      // 如果解析失败，返回原始字符串
      return dateTime.toString();
    }
  }

  /// 将日期时间字符串解析为UTC时间
  static DateTime _parseAsUtc(String dateTimeStr) {
    // 分割日期和时间部分
    final parts = dateTimeStr.split(' ');
    if (parts.isEmpty) {
      throw FormatException('Invalid date time format: $dateTimeStr');
    }

    // 解析日期部分
    final dateParts = parts[0].split('-');
    if (dateParts.length != 3) {
      throw FormatException('Invalid date format: ${parts[0]}');
    }

    final year = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final day = int.parse(dateParts[2]);

    // 解析时间部分（如果存在）
    int hour = 0, minute = 0, second = 0;
    if (parts.length > 1) {
      final timeParts = parts[1].split(':');
      if (timeParts.isNotEmpty) hour = int.parse(timeParts[0]);
      if (timeParts.length > 1) minute = int.parse(timeParts[1]);
      if (timeParts.length > 2) {
        // 处理可能包含毫秒的秒数
        final secondStr = timeParts[2].split('.')[0];
        second = int.parse(secondStr);
      }
    }

    // 创建UTC时间
    return DateTime.utc(year, month, day, hour, minute, second);
  }

  /// 将日期时间字符串解析为本地时间（已废弃，保留用于兼容）
  static DateTime _parseAsLocal(String dateTimeStr) {
    // 分割日期和时间部分
    final parts = dateTimeStr.split(' ');
    if (parts.isEmpty) {
      throw FormatException('Invalid date time format: $dateTimeStr');
    }

    // 解析日期部分
    final dateParts = parts[0].split('-');
    if (dateParts.length != 3) {
      throw FormatException('Invalid date format: ${parts[0]}');
    }

    final year = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final day = int.parse(dateParts[2]);

    // 解析时间部分（如果存在）
    int hour = 0, minute = 0, second = 0;
    if (parts.length > 1) {
      final timeParts = parts[1].split(':');
      if (timeParts.isNotEmpty) hour = int.parse(timeParts[0]);
      if (timeParts.length > 1) minute = int.parse(timeParts[1]);
      if (timeParts.length > 2) {
        // 处理可能包含毫秒的秒数
        final secondStr = timeParts[2].split('.')[0];
        second = int.parse(secondStr);
      }
    }

    // 创建本地时间
    return DateTime(year, month, day, hour, minute, second);
  }

  /// 格式化为日期（不含时间）
  static String formatDate(dynamic dateTime) {
    return formatDateTime(dateTime, format: 'yyyy-MM-dd');
  }

  /// 格式化为时间（不含日期）
  static String formatTime(dynamic dateTime) {
    return formatDateTime(dateTime, format: 'HH:mm:ss');
  }

  /// 解析日期时间字符串为DateTime对象（将UTC时间转换为本地时间）
  static DateTime? parseAsLocalDateTime(dynamic dateTime) {
    if (dateTime == null) return null;

    try {
      if (dateTime is DateTime) {
        return dateTime;
      }

      String dateTimeStr = dateTime.toString().trim();
      dateTimeStr = dateTimeStr.replaceAll('T', ' ');
      dateTimeStr = dateTimeStr.split('+')[0].split('Z')[0].trim();
      // 解析为UTC时间，然后转换为本地时间
      return _parseAsUtc(dateTimeStr).toLocal();
    } catch (e) {
      return null;
    }
  }

  /// 格式化为相对时间（如：刚刚、5分钟前、昨天等）
  static String formatRelativeTime(dynamic dateTime) {
    if (dateTime == null) return '';

    try {
      DateTime dt;
      if (dateTime is DateTime) {
        dt = dateTime;
      } else {
        String dateTimeStr = dateTime.toString().trim();
        dateTimeStr = dateTimeStr.replaceAll('T', ' ');
        dateTimeStr = dateTimeStr.split('+')[0].split('Z')[0].trim();
        // 解析为UTC时间，然后转换为本地时间
        dt = _parseAsUtc(dateTimeStr).toLocal();
      }

      final now = DateTime.now();
      final difference = now.difference(dt);

      if (difference.inSeconds < 60) {
        return '刚刚';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}分钟前';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}小时前';
      } else if (difference.inDays == 1) {
        return '昨天';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}天前';
      } else {
        return formatDate(dt);
      }
    } catch (e) {
      return dateTime.toString();
    }
  }
}
