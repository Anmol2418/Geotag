// lib/models/attendance_model.dart

class AttendanceModel {
  final String? id;           // Record ID from the database
  final DateTime date;        // Attendance date
  final DateTime? clockInTime;
  final DateTime? clockOutTime;
  final Duration? duration;

  AttendanceModel({
    this.id,
    required this.date,
    this.clockInTime,
    this.clockOutTime,
    this.duration,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    final DateTime date = DateTime.parse(json['date']);
    final DateTime? clockInTime =
    json['clock_in_time'] != null ? DateTime.parse(json['clock_in_time']) : null;
    final DateTime? clockOutTime =
    json['clock_out_time'] != null ? DateTime.parse(json['clock_out_time']) : null;

    Duration? duration;
    if (json['duration'] != null) {
      duration = Duration(seconds: json['duration']);
    } else if (clockInTime != null) {
      final startWork = DateTime(date.year, date.month, date.day, 9, 30);
      final effectiveStart = clockInTime.isBefore(startWork) ? startWork : clockInTime;
      final end = clockOutTime ?? DateTime.now();
      duration = end.difference(effectiveStart);
      if (duration.isNegative) duration = Duration.zero;
    }


    return AttendanceModel(
      id: json['id']?.toString(), // MySQL may return int or string
      date: date,
      clockInTime: clockInTime,
      clockOutTime: clockOutTime,
      duration: duration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String(),
      'clock_in_time': clockInTime?.toIso8601String(),
      'clock_out_time': clockOutTime?.toIso8601String(),
      'duration': duration?.inSeconds,
    };
  }
}
