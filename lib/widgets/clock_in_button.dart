// clock_in_button.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../screens/map_clock_screen.dart';
import '../services/location_service.dart';


class ClockInButton extends StatefulWidget {
  final String employeeId;
  final VoidCallback onSuccess;
  const ClockInButton({super.key, required this.employeeId, required this.onSuccess});

  @override
  State<ClockInButton> createState() => _ClockInButtonState();
}

class _ClockInButtonState extends State<ClockInButton> {
  bool _isLoading = false;

  Future<void> _openMap() async {
    setState(() => _isLoading = true);

    final locService = LocationService();
    final granted = await locService.requestPermission();
    if (!granted) {
      _showMessage('Location permission denied. Cannot open map.');
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MapClockScreen(
          officeLatLng: LatLng(
            LocationService.officeLatitude,
            LocationService.officeLongitude,
          ),
          radius: 100.0,
          employeeId: widget.employeeId,
          isClockIn: true,
          onSuccess: widget.onSuccess,
        ),
      ),
    );

    if (success == true) {
      _showMessage('Clock‑in successful!');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showMessage(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _openMap,
      icon: _isLoading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.map),
      label: const Text('Clock In'),
    );
  }
}