import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../services/location_service.dart';
import '../services/attendance_service.dart';
import '../utils/constants.dart';
import '../utils/geofence_utils.dart';
import '../services/face_verification_service.dart';
import '../utils/api_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MapClockScreen extends StatefulWidget {
  final String employeeId;
  final bool isClockIn;
  final VoidCallback onSuccess;
  final LatLng? officeLatLng;
  final double? radius;

  const MapClockScreen({
    Key? key,
    required this.employeeId,
    required this.isClockIn,
    required this.onSuccess,
    this.officeLatLng,
    this.radius,
  }) : super(key: key);

  @override
  State<MapClockScreen> createState() => _MapClockScreenState();
}

class _MapClockScreenState extends State<MapClockScreen> {
  final _location = LocationService();
  final _picker = ImagePicker();
  late final MapController _mapController;

  bool _mapReady = false;
  LatLng? _pendingCenter;
  Position? _pos;
  bool _inside = false;
  bool _busy = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getAndCheckLocation();
  }

  Future<void> _getAndCheckLocation() async {
    setState(() {
      _busy = true;
      _err = null;
    });

    try {
      final ok = await _location.requestPermission();
      if (!ok) throw 'Location permission denied';

      final p = await _location.getCurrentPosition();
      final inside = await GeofenceUtils.isWithinGeofence(p);

      setState(() {
        _pos = p;
        _inside = inside;
        _busy = false;
      });

      _pendingCenter = inside
          ? LatLng(p.latitude, p.longitude)
          : LatLng(Constants.geofenceLatitude, Constants.geofenceLongitude);

      if (_mapReady && _pendingCenter != null) {
        _mapController.move(_pendingCenter!, inside ? 17 : 15);
        _pendingCenter = null;
      }
    } catch (e) {
      setState(() {
        _err = e.toString();
        _busy = false;
      });
    }
  }

  Future<void> _saveClockTimeLocally(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    final key = widget.isClockIn
        ? 'clockInTime_${widget.employeeId}'
        : 'clockOutTime_${widget.employeeId}';
    await prefs.setString(key, now.toIso8601String());
    print('✅ Saved $key = ${now.toIso8601String()}');
  }

  Future<void> _sendToMySQLBackend(DateTime now) async {
    final url = widget.isClockIn
        ? 'http://172.16.18.188:3000/attendance/clock-in'
        : 'http://172.16.18.188:3000/attendance/clock-out';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'employeeId': widget.employeeId,
        'timestamp': now.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      final message = jsonDecode(response.body)['message'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Attendance recorded'), backgroundColor: Colors.green),
      );
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Attendance failed';
      throw Exception(error);
    }
  }

  Future<void> _verifyAndClock() async {
    print('📍 Entered _verifyAndClock()');

    if (!_inside) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be inside the geofence.')),
      );
      print('⚠️ User not inside geofence.');
      return;
    }

    final XFile? shot = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (shot == null) {
      print('⚠️ User cancelled image capture.');
      return;
    }

    setState(() => _busy = true);

    try {
      final data = await ApiClient.get('/employees/${widget.employeeId}', auth: true);
      final storedRelativePath = data['face_image_url'] as String;
      final storedFullUrl = 'http://172.16.18.188:5000$storedRelativePath';

      final matched = await FaceVerificationService.verifyFace(
        File(shot.path),
        storedFullUrl,
      );

      final confidence = FaceVerificationService.lastConfidence ?? 0.0;
      final threshold = FaceVerificationService.lastThreshold ?? 0.0;

      if (!matched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Face mismatch. Access denied.\nConfidence: $confidence vs Threshold: $threshold'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Face matched. Access granted.'),
          backgroundColor: Colors.green,
        ),
      );

      final now = DateTime.now();
      await _sendToMySQLBackend(now);
      await _saveClockTimeLocally(now);
      widget.onSuccess();
      print('⏱ Clock ${widget.isClockIn ? 'In' : 'Out'} completed at $now for ${widget.employeeId}');
      Navigator.pop(context);
    } catch (e) {
      print('❌ Error during face verification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final office = LatLng(Constants.geofenceLatitude, Constants.geofenceLongitude);

    return Scaffold(
      appBar: AppBar(title: Text(widget.isClockIn ? 'Clock In' : 'Clock Out')),
      body: _busy && _pos == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: office,
                initialZoom: 15,
                onMapReady: () {
                  _mapReady = true;
                  if (_pendingCenter != null) {
                    _mapController.move(_pendingCenter!, _inside ? 17 : 15);
                    _pendingCenter = null;
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                CircleLayer(circles: [
                  CircleMarker(
                    point: office,
                    radius: Constants.geofenceRadius,
                    useRadiusInMeter: true,
                    color: Colors.blue.withOpacity(0.15),
                    borderStrokeWidth: 2,
                    borderColor: Colors.blue,
                  ),
                ]),
                if (_pos != null)
                  MarkerLayer(markers: [
                    Marker(
                      width: 40,
                      height: 40,
                      point: LatLng(_pos!.latitude, _pos!.longitude),
                      child: const Icon(Icons.person_pin_circle,
                          color: Colors.red, size: 40),
                    ),
                  ]),
              ],
            ),
          ),
          if (_err != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_err!, style: const TextStyle(color: Colors.red)),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _verifyAndClock,
              icon: _busy
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Icon(widget.isClockIn ? Icons.login : Icons.logout),
              label: Text(widget.isClockIn ? 'Clock In' : 'Clock Out'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'refreshPos',
        onPressed: _getAndCheckLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
