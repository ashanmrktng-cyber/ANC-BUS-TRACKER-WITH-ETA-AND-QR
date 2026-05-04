import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/tracking_provider.dart';
import '../../providers/auth_provider.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});
  @override State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  GoogleMapController? _mapCtrl;
  static const _default = LatLng(6.9271, 79.8612);
  Set<Marker> _markers = {};
  LatLng? _homeLoc;

  @override
  void initState() {
    super.initState();
    _loadHomeAndStartTracking();
  }

  Future<void> _loadHomeAndStartTracking() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final tp = Provider.of<TrackingProvider>(context, listen: false);
    
    if (auth.user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(auth.user!.userId).get();
      final studentId = userDoc.data()?['studentId'];
      if (studentId != null) {
        final studentDoc = await FirebaseFirestore.instance.collection('students').doc(studentId).get();
        final data = studentDoc.data();
        if (data != null && data['latitude'] != null) {
          setState(() {
            _homeLoc = LatLng(data['latitude'], data['longitude']);
          });
          tp.setDestination(_homeLoc!);
        }
      }
      tp.startTracking('BUS-001');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Bus Tracking'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.my_location), onPressed: _centerOnBus),
        ],
      ),
      body: Consumer<TrackingProvider>(builder: (_, tp, __) {
        final bus = tp.bus;
        _markers = {};
        
        if (bus?.latitude != null) {
          _markers.add(Marker(
            markerId: const MarkerId('bus'),
            position: LatLng(bus!.latitude!, bus.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(title: 'Bus ${bus.busNumber}', snippet: 'Speed: ${bus.speed?.toStringAsFixed(0)} km/h'),
          ));
        }

        if (_homeLoc != null) {
          _markers.add(Marker(
            markerId: const MarkerId('home'),
            position: _homeLoc!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: const InfoWindow(title: 'My Home'),
          ));
        }

        return Stack(children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: _default, zoom: 13),
            onMapCreated: (c) {
              _mapCtrl = c;
              if (bus != null) _centerOnBus();
            },
            markers: _markers,
            myLocationEnabled: true,
            trafficEnabled: true,
          ),

          // ETA Card
          if (tp.eta != null || bus != null)
            Positioned(
              top: 16, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bus?.isMoving == true ? AppColors.cardGreen : AppColors.cardOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      bus?.isMoving == true ? Icons.directions_bus : Icons.pause_circle,
                      color: bus?.isMoving == true ? AppColors.success : AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      bus?.isMoving == true ? 'Bus is Moving' : 'Bus is Stopped',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (tp.eta != null)
                      Text('Arriving in: ${tp.eta}',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ])),
                  if (tp.eta != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                      child: Column(children: [
                        const Text('ETA', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        Text(tp.eta!.split(' ').first, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ]),
                    ),
                ]),
              ),
            ),

          // Bottom Feature Indicators
          Positioned(
            bottom: 20, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _featureIcon(Icons.traffic_rounded, 'Traffic Live', Colors.green),
                _featureDivider(),
                _featureIcon(Icons.psychology_rounded, 'AI Prediction', Colors.blue),
                _featureDivider(),
                _featureIcon(Icons.alt_route_rounded, 'Smart Route', Colors.purple),
              ]),
            ),
          ),
        ]);
      }),
    );
  }

  Widget _featureIcon(IconData icon, String label, Color color) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    ]);
  }

  Widget _featureDivider() {
    return Container(height: 20, width: 1, color: AppColors.divider);
  }

  void _centerOnBus() {
    final tp = Provider.of<TrackingProvider>(context, listen: false);
    if (tp.bus?.latitude != null) {
      _mapCtrl?.animateCamera(CameraUpdate.newLatLng(LatLng(tp.bus!.latitude!, tp.bus!.longitude!)));
    }
  }
}
