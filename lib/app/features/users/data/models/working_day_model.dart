import 'package:flutter/material.dart';

/// Represents a configured working day and shift hours for a user.
class WorkingDayModel {
  final int? id;
  final int userId;
  final int day; // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
  final String fromTime; // format: "HH:mm:ss" or "HH:mm"
  final String toTime; // format: "HH:mm:ss" or "HH:mm"

  const WorkingDayModel({
    this.id,
    required this.userId,
    required this.day,
    required this.fromTime,
    required this.toTime,
  });

  /// Arabic name of the day
  String get dayNameAr {
    switch (day) {
      case 0:
        return 'الأحد';
      case 1:
        return 'الاثنين';
      case 2:
        return 'الثلاثاء';
      case 3:
        return 'الأربعاء';
      case 4:
        return 'الخميس';
      case 5:
        return 'الجمعة';
      case 6:
        return 'السبت';
      default:
        return 'يوم $day';
    }
  }

  /// English name of the day
  String get dayNameEn {
    switch (day) {
      case 0:
        return 'Sunday';
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      default:
        return 'Day $day';
    }
  }

  /// Parses fromTime to TimeOfDay
  TimeOfDay get fromTimeOfDay {
    return _parseTime(fromTime, defaultHour: 8, defaultMinute: 0);
  }

  /// Parses toTime to TimeOfDay
  TimeOfDay get toTimeOfDay {
    return _parseTime(toTime, defaultHour: 17, defaultMinute: 0);
  }

  static TimeOfDay _parseTime(String timeStr, {required int defaultHour, required int defaultMinute}) {
    try {
      final parts = timeStr.trim().split(':');
      if (parts.isNotEmpty) {
        final hour = int.parse(parts[0]);
        final minute = parts.length > 1 ? int.parse(parts[1]) : 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}
    return TimeOfDay(hour: defaultHour, minute: defaultMinute);
  }

  /// Formatted localized time display (e.g., "08:00 ص" or "05:00 م")
  static String formatTimeDisplay(String timeStr, {bool isArabic = true}) {
    final tod = _parseTime(timeStr, defaultHour: 8, defaultMinute: 0);
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final isAm = tod.period == DayPeriod.am;

    if (isArabic) {
      final period = isAm ? 'ص' : 'م';
      return '$hour:$minute $period';
    } else {
      final period = isAm ? 'AM' : 'PM';
      return '$hour:$minute $period';
    }
  }

  String get fromTimeFormatted => formatTimeDisplay(fromTime);
  String get toTimeFormatted => formatTimeDisplay(toTime);

  WorkingDayModel copyWith({
    int? id,
    int? userId,
    int? day,
    String? fromTime,
    String? toTime,
  }) {
    return WorkingDayModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      day: day ?? this.day,
      fromTime: fromTime ?? this.fromTime,
      toTime: toTime ?? this.toTime,
    );
  }

  factory WorkingDayModel.fromMap(Map<String, dynamic> map) {
    return WorkingDayModel(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      userId: map['userId'] is int
          ? map['userId']
          : int.tryParse(map['userId']?.toString() ?? '0') ?? 0,
      day: map['day'] is int
          ? map['day']
          : int.tryParse(map['day']?.toString() ?? '0') ?? 0,
      fromTime: map['fromTime']?.toString() ?? '08:00:00',
      toTime: map['toTime']?.toString() ?? '17:00:00',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'day': day,
      'fromTime': fromTime,
      'toTime': toTime,
    };
  }

  /// Formats TimeOfDay to standard backend time format "HH:mm:ss"
  static String formatForApi(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }
}
