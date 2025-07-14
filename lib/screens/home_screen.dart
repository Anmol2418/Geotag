// lib/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/attendance_service.dart';
import '../utils/constants.dart';
import 'attendance_history_screen.dart';
import 'login_screen.dart';
import '../models/attendance_model.dart';
import 'map_clock_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  final UserModel user;

  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();
  final AttendanceService _attendanceService = AttendanceService();
  String get _clockInKey => 'clockInTime_${widget.user.employeeId}';
  String get _clockOutKey => 'clockOutTime_${widget.user.employeeId}';
  bool _locationPermissionGranted = false;
  bool _checkingPermission = true;

  Timer? _timer;
  String _workingHoursText = '---';
  DateTime? _clockInTime;
  DateTime? _clockOutTime;

  @override
  void initState() {
    super.initState();
    _initPermissionsAndLoadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initPermissionsAndLoadData() async {
    await _checkLocationPermission();
    await _loadClockTimes();
  }

  Future<void> _checkLocationPermission() async {
    final granted = await _locationService.requestPermission();
    setState(() {
      _locationPermissionGranted = granted;
      _checkingPermission = false;
    });
  }

  Future<void> _loadClockTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final clockInStr = prefs.getString(_clockInKey);
    final clockOutStr = prefs.getString(_clockOutKey);

    DateTime? clockIn;
    DateTime? clockOut;

    if (clockInStr != null) {
      final dt = DateTime.tryParse(clockInStr);
      if (dt != null && dt.year == today.year && dt.month == today.month && dt.day == today.day) {
        clockIn = dt;
      }
    }

    if (clockOutStr != null) {
      final dt = DateTime.tryParse(clockOutStr);
      if (dt != null && dt.year == today.year && dt.month == today.month && dt.day == today.day) {
        clockOut = dt;
      }
    }

    if (clockIn == null) {
      final attendanceList = await _attendanceService.getAttendanceHistory(widget.user.employeeId);
      final todayRecord = attendanceList.firstWhere(
            (att) => att.date.year == today.year && att.date.month == today.month && att.date.day == today.day,
        orElse: () => AttendanceModel(date: today),
      );
      clockIn = todayRecord.clockInTime;
      clockOut = todayRecord.clockOutTime;
    }

    if (clockIn == null) {
      setState(() {
        _workingHoursText = 'Not clocked in';
        _clockInTime = null;
        _clockOutTime = null;
      });
      _timer?.cancel();
      return;
    }

    setState(() {
      _clockInTime = clockIn;
      _clockOutTime = clockOut;
    });

    _startTimer();
  }

  void _startTimer() {
    _updateWorkingHours();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateWorkingHours());
  }

  void _updateWorkingHours() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, Constants.workStartHour, Constants.workStartMinute);

    DateTime effectiveStart = (_clockInTime != null && _clockInTime!.isAfter(startOfDay))
        ? _clockInTime!
        : startOfDay;

    Duration duration;
    if (_clockOutTime != null) {
      duration = _clockOutTime!.difference(effectiveStart);
      _timer?.cancel();
    } else {
      duration = now.difference(effectiveStart);
    }

    if (duration.isNegative) duration = Duration.zero;

    setState(() {
      _workingHoursText = _formatDuration(duration);
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _navigateToAttendanceHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
    );
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    Navigator.of(context).pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
  }

  Future<void> _handleClockAction(bool isClockIn) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MapClockScreen(
        employeeId: widget.user.employeeId,
        isClockIn: isClockIn,
        onSuccess: _loadClockTimes,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${widget.user.name} 👋'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _navigateToAttendanceHistory,
            icon: const Icon(Icons.history),
            tooltip: 'View History',
          ),
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _checkingPermission
          ? const Center(child: CircularProgressIndicator())
          : Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFBBDEFB), Color(0xFFE3F2FD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(20),
                    leading: const Icon(Icons.access_time, size: 36, color: Colors.blue),
                    title: const Text('Working Hours Today',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _workingHoursText,
                        style: const TextStyle(fontSize: 22, color: Colors.black87),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _handleClockAction(true),
                child: const Text('Clock In'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _handleClockAction(false),
                child: const Text('Clock Out'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
