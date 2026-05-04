import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EtaService {
  // Your Google Maps API Key for Traffic & AI
  static const String _mapsApiKey = 'AIzaSyDeMRRDMJs6bKv3afSjIg548EnHOrLrrEY';

  // ANC Campus Coordinates
  static const LatLng schoolLocation = LatLng(6.9142, 79.8515);

  // Compute AI-based ETA using Google Distance Matrix + live traffic
  static Future<String> computeEta({
    required LatLng busLocation,
    required LatLng destination,
  }) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json'
        '?origins=${busLocation.latitude},${busLocation.longitude}'
        '&destinations=${destination.latitude},${destination.longitude}'
        '&departure_time=now'
        '&traffic_model=best_guess'
        '&mode=driving'
        '&key=$_mapsApiKey',
      );

      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        
        if (data['status'] == 'REQUEST_DENIED') {
          print('Google Maps API Error: ${data['error_message']}');
          return _simpleEta(busLocation, destination, 30.0);
        }

        final element = data['rows']?[0]?['elements']?[0];
        if (element != null && element['status'] == 'OK') {
          // Duration in traffic is the AI part - it accounts for Colombo traffic
          final durationSec = element['duration_in_traffic']?['value']
              ?? element['duration']?['value'] ?? 0;
          
          final minutes = (durationSec / 60).ceil();

          if (minutes <= 0) return 'Arrived';
          if (minutes < 60) return '$minutes mins';
          return '${minutes ~/ 60}h ${minutes % 60}m';
        }
      }
    } catch (e) {
      print('AI ETA error: $e');
    }

    // Fallback: simple calculation
    return _simpleEta(busLocation, destination, 25.0);
  }

  static String _simpleEta(LatLng from, LatLng to, double speedKmh) {
    final distKm = _haversine(from, to);
    if (distKm < 0.2) return 'Arrived';
    final mins = ((distKm / speedKmh) * 60).ceil();
    return minutesToText(mins);
  }

  static String minutesToText(int minutes) {
    if (minutes <= 1) return '1 min';
    if (minutes < 60) return '$minutes mins';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }

  static double _haversine(LatLng from, LatLng to) {
    const R = 6371.0;
    final dLat = _rad(to.latitude  - from.latitude);
    final dLon = _rad(to.longitude - from.longitude);
    final a = _sin2(dLat / 2) +
        _cos(_rad(from.latitude)) * _cos(_rad(to.latitude)) * _sin2(dLon / 2);
    return R * 2 * _asin(_sqrt(a));
  }

  static double _rad(double d) => d * 3.14159265358979 / 180;
  static double _sin2(double x) => _sin(x) * _sin(x);
  static double _sin(double x) => x - x * x * x / 6 + x * x * x * x * x / 120;
  static double _cos(double x) => 1 - x * x / 2 + x * x * x * x / 24;
  static double _asin(double x) => x + x * x * x / 6;
  static double _sqrt(double x) => x > 0 ? x * (1 + (x - 1) / 2) : 0;
}
