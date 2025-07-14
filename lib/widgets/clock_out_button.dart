// lib/widgets/clock_out_button.dart
import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../services/attendance_service.dart';
import '../utils/geofence_utils.dart';

class ClockOutButton extends StatefulWidget {
  final String employeeId;
  final VoidCallback onSuccess;

  const ClockOutButton({
    Key? key,
    required this.employeeId,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<ClockOutButton> createState() => _ClockOutButtonState();
}

class _ClockOutButtonState extends State<ClockOutButton> {
  final LocationService _locationService = LocationService();
  final AttendanceService _attendanceService = AttendanceService();

  bool _isLoading = false;

  Future<void> _handleClockOut() async {
    setState(() => _isLoading = true);
    try {
      final permissionGranted = await _locationService.requestPermission();
      if (!permissionGranted) {
        _showMessage('Location permission denied. Cannot clock out.');
        return;
      }

      final position = await _locationService.getCurrentPosition();

      final insideGeofence = await GeofenceUtils.isWithinGeofence(position);
      if (!insideGeofence) {
        _showMessage('You must be inside the geofenced area to clock out.');
        return;
      }

      final now = DateTime.now();
      final success = await _attendanceService.clockOut(widget.employeeId, now);
      _showMessage('Clock Out successful!');
      widget.onSuccess();
    } catch (e) {
      _showMessage('Clock Out failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg) {
    final snackBar = SnackBar(content: Text(msg));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: _isLoading
          ? const SizedBox(
              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.logout),
      label: const Text('Clock Out'),
      onPressed: _isLoading ? null : _handleClockOut,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}