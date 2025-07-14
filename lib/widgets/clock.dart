import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkingHoursTimer extends StatefulWidget {
  const WorkingHoursTimer({super.key});

  @override
  State<WorkingHoursTimer> createState() => _WorkingHoursTimerState();
}

class _WorkingHoursTimerState extends State<WorkingHoursTimer> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  DateTime? _clockInTime;
  DateTime? _clockOutTime;

  @override
  void initState() {
    super.initState();
    _loadTimes();
  }

  Future<void> _loadTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final clockInStr = prefs.getString('clockInTime');
    final clockOutStr = prefs.getString('clockOutTime');

    if (clockInStr != null) {
      _clockInTime = DateTime.parse(clockInStr);
    }
    if (clockOutStr != null) {
      _clockOutTime = DateTime.parse(clockOutStr);
    }

    if (_clockInTime != null && _clockOutTime == null) {
      _startTimer();
    } else {
      _updateElapsed();
    }
  }

  void _startTimer() {
    _updateElapsed();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _updateElapsed());
  }

  void _updateElapsed() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 9, 30);
    setState(() {
      if (_clockOutTime != null) {
        _elapsed = _clockOutTime!.isBefore(start)
            ? Duration.zero
            : _clockOutTime!.difference(start);
        _timer?.cancel();
      } else if (_clockInTime != null) {
        _elapsed = now.isBefore(start)
            ? Duration.zero
            : now.difference(start);
      }
    });
  }

  String _format(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inHours)}:${twoDigits(d.inMinutes % 60)}:${twoDigits(d.inSeconds % 60)}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_clockInTime == null) {
      return const Text("Not Clocked In",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500));
    }

    return Text("Working Time: ${_format(_elapsed)}",
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
  }
}
