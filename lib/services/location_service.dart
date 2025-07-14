// lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';
import '../utils/geofence_utils.dart';
class LocationService {
  static const double officeLatitude = 31.089258214289433;
  static const double officeLongitude = 77.1947923817082;
  static const double allowedRadius = 100; // ← You can increase this to 200–300 for debugging

  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    print('🔐 Initial permission status: $permission');

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      print('🔐 After request: $permission');
    }

    final isEnabled = await Geolocator.isLocationServiceEnabled();
    print('📡 Location services enabled: $isEnabled');

    if (!isEnabled || permission == LocationPermission.deniedForever) {
      print('❌ Location not available or permanently denied');
      return false;
    }

    return true;
  }

  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      // Use LocationSettings (per new geolocator version)
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<bool> isWithinAllowedArea() async {
    try {
      final pos = await getCurrentPosition();

      final distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        officeLatitude,
        officeLongitude,
      );

      print('📏 Distance from office: $distance meters');
      print('✅ Inside geofence? ${distance <= allowedRadius}');

      return distance <= allowedRadius;
    } catch (e) {
      print('⚠️ Error getting location: $e');
      return false;
    }
  }
}
