// lib/screens/attendance_history_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import '../models/attendance_model.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  static const routeName = '/attendance-history';

  const AttendanceHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final AuthService _authService = AuthService();
  final AttendanceService _attendanceService = AttendanceService();

  List<AttendanceModel> _fullList = [];
  List<AttendanceModel> _filteredList = [];
  bool _isLoading = true;
  DateTime? _selectedMonth;

  Duration get _weeklyTotal {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    return _filteredList
        .where((entry) => entry.date.isAfter(monday.subtract(const Duration(days: 1))))
        .fold(Duration.zero, (sum, att) => sum + (att.duration ?? Duration.zero));
  }

  @override
  void initState() {
    super.initState();
    _loadAttendanceHistory();
  }

  Future<void> _loadAttendanceHistory() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        Navigator.of(context).pop();
        return;
      }

      final list = await _attendanceService.getAttendanceHistory(user.employeeId);
      list.sort((a, b) => b.date.compareTo(a.date)); // recent first
      setState(() {
        _fullList = list;
        _filteredList = list;
        _isLoading = false;
      });
    } catch (e) {
      _showError('Failed to load attendance history: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    final snackBar = SnackBar(content: Text(message), backgroundColor: Colors.redAccent);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '-';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  Widget _buildAttendanceCard(AttendanceModel attendance) {
    final dateFormatted = DateFormat.yMMMMEEEEd().format(attendance.date);
    final clockInStr = attendance.clockInTime != null
        ? DateFormat('hh:mm a').format(attendance.clockInTime!)
        : '-';
    final clockOutStr = attendance.clockOutTime != null
        ? DateFormat('hh:mm a').format(attendance.clockOutTime!)
        : '-';
    final durationStr = _formatDuration(attendance.duration);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        title: Text(
          dateFormatted,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.login, size: 18, color: Colors.green),
                  const SizedBox(width: 4),
                  Text('In: $clockInStr'),
                  const SizedBox(width: 16),
                  const Icon(Icons.logout, size: 18, color: Colors.redAccent),
                  const SizedBox(width: 4),
                  Text('Out: $clockOutStr'),
                ],
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer, color: Colors.blue),
            const SizedBox(height: 4),
            Text(durationStr),
          ],
        ),
      ),
    );
  }

  void _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      helpText: 'Select month to filter',
      fieldHintText: 'yyyy-mm',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (picked != null) {
      final newMonth = DateTime(picked.year, picked.month);
      setState(() {
        _selectedMonth = newMonth;
        _filteredList = _fullList.where((entry) =>
        entry.date.year == newMonth.year && entry.date.month == newMonth.month).toList();
      });
    }
  }

  void _clearFilter() {
    setState(() {
      _selectedMonth = null;
      _filteredList = _fullList;
    });
  }

  @override
  Widget build(BuildContext context) {
    final weekHours = _formatDuration(_weeklyTotal);
    final monthLabel = _selectedMonth != null
        ? DateFormat.yMMMM().format(_selectedMonth!)
        : 'All Time';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Filter by Month',
            onPressed: _pickMonth,
          ),
          if (_selectedMonth != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear Filter',
              onPressed: _clearFilter,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredList.isEmpty
          ? const Center(child: Text('No attendance records found.'))
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade100, Colors.white],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Showing: $monthLabel',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total Hours This Week: $weekHours',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredList.length,
              itemBuilder: (context, index) {
                return _buildAttendanceCard(_filteredList[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}