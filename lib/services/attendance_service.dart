// lib/services/attendance_service.dart
import '../models/attendance_model.dart';
import '../utils/constants.dart';
import '../utils/api_client.dart';

/// AttendanceService now talks to the Express + MySQL REST API instead of Supabase.
/// Back‑end routes (see routes/attendance.js):
///   POST /attendance/get-today    { employee_id }
///   POST /attendance/clock-in     { employee_id, clock_in_time }
///   POST /attendance/clock-out    { employee_id, clock_out_time, duration }
///   POST /attendance/history      { employee_id }
class AttendanceService {
  /*────────────── CLOCK‑IN ──────────────*/
  Future<AttendanceModel> clockIn(
      String employeeId, DateTime actualClockInTime) async {
    final today = DateTime(
        actualClockInTime.year, actualClockInTime.month, actualClockInTime.day);

    final storedClockInTime = actualClockInTime;

    /// 1) Does a row already exist for today?
    final existing = await ApiClient.post('/attendance/get-today',
        {'employeeId': employeeId},
        auth: true);

    if (existing.isNotEmpty && existing['clock_in_time'] != null) {
      throw 'Already clocked in today.';
    }

    /// 2) Insert (or update) via API
    final res = await ApiClient.post('/attendance/clock-in', {
      'employeeId': employeeId,
      'clock_in_time': storedClockInTime.toIso8601String(),
    }, auth: true);

    return AttendanceModel.fromJson(res);
  }

  /*────────────── CLOCK‑OUT ─────────────*/
  Future<AttendanceModel> clockOut(
      String employeeId, DateTime actualClockOutTime) async {
    /// 1) Fetch today row
    final record = await ApiClient.post('/attendance/get-today',
        {'employeeId': employeeId},
        auth: true);

    if (record.isEmpty) throw 'No clock‑in record today.';
    if (record['clock_in_time'] == null) throw 'Must clock in first.';
    if (record['clock_out_time'] != null) throw 'Already clocked out today.';

    final clockInTime = DateTime.parse(record['clock_in_time']);
    final clockOutTime =
    actualClockOutTime.isBefore(clockInTime) ? clockInTime : actualClockOutTime;

    final workStart = DateTime(clockInTime.year, clockInTime.month,
        clockInTime.day, Constants.workStartHour, Constants.workStartMinute);

    final effectiveStart = workStart.isAfter(clockInTime) ? workStart : clockInTime;
    final durationSecs = clockOutTime.difference(effectiveStart).inSeconds;

    /// 2) Update via API
    final res = await ApiClient.post('/attendance/clock-out', {
      'employeeId': employeeId,
      'clock_out_time': clockOutTime.toIso8601String(),
      'duration': durationSecs,
    }, auth: true);

    return AttendanceModel.fromJson(res);
  }

  /*───────── ATTENDANCE HISTORY ─────────*/
  Future<List<AttendanceModel>> getAttendanceHistory(String employeeId) async {
    final res = await ApiClient.post('/attendance/history',
        {'employeeId': employeeId},
        auth: true);
    print('📦 API Response: $res');
    final rows = (res['rows'] as List);
    return rows
        .map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
