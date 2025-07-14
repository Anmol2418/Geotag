// lib/utils/constants.dart
import 'package:flutter/material.dart';

class Constants {
  // Geofence center coordinates
  static const double geofenceLatitude = 31.089258214289433; // Example: Googleplex latitude
  static const double geofenceLongitude = 77.1947923817082; // Example: Googleplex longitude

  // Geofence radius in meters
  static const double geofenceRadius = 100;

  // Work start time is always fixed at 9:30 AM local time
  static const int workStartHour = 9;
  static const int workStartMinute = 30;
}