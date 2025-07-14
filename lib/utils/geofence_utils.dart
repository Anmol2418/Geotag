// lib/utils/geofence_utils.dart
import 'package:geolocator/geolocator.dart';
import 'constants.dart';

class GeofenceUtils {
  /// Check if [position] is within geofence radius from defined geofence center.
  static Future<bool> isWithinGeofence(Position position) async {
    final double distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      Constants.geofenceLatitude,
      Constants.geofenceLongitude,
    );
    return distanceInMeters <= Constants.geofenceRadius;
  }
}