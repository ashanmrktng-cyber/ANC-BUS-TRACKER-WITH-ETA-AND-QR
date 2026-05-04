import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/bus_model.dart';
import '../../data/services/eta_service.dart';
import '../../data/services/firebase_service.dart';

class TrackingProvider extends ChangeNotifier {
  BusModel? _bus;
  String? _eta;
  bool _isLoading = false;
  LatLng? _destination;
  String _destinationName = 'Home';

  BusModel? get bus              => _bus;
  String? get eta                => _eta;
  bool get isLoading             => _isLoading;
  LatLng? get destination        => _destination;
  String get destinationName     => _destinationName;

  void setDestination(LatLng dest, [String name = 'Home']) {
    _destination = dest;
    _destinationName = name;
    notifyListeners();
  }

  // Stream live bus location and status from Firebase
  void startTracking(String busId) {
    // 1. Listen to location & speed
    FirebaseService.busLocationStream(busId).listen((data) async {
      if (data != null) {
        final lat = double.tryParse(data['latitude']?.toString() ?? data['lat']?.toString() ?? '');
        final lng = double.tryParse(data['longitude']?.toString() ?? data['lng']?.toString() ?? '');
        final speed = double.tryParse(data['speed']?.toString() ?? '') ?? 0;

        if (lat != null && lng != null) {
          _bus = BusModel(
            busId: busId,
            busNumber: _bus?.busNumber ?? 'BUS-001',
            driverName: _bus?.driverName ?? 'Driver',
            driverPhone: _bus?.driverPhone ?? '',
            latitude: lat,
            longitude: lng,
            speed: speed,
            status: speed > 2 ? 'moving' : 'stopped',
          );

          // Compute AI-based Traffic-Aware ETA
          if (_destination != null) {
            _eta = await EtaService.computeEta(
              busLocation: LatLng(lat, lng),
              destination: _destination!,
            );
          }
          notifyListeners();
        }
      }
    });

    // 2. Listen to bus trip type (to school / to home)
    FirebaseService.busStatusStream(busId).listen((snap) {
      if (snap.value is Map) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        // This is handled by DashboardScreen to set the correct LatLng
      }
    });
  }
}
