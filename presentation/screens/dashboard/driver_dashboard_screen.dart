import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/firebase_service.dart';
import '../../providers/auth_provider.dart';
import '../qr/qr_scan_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});
  @override State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  bool _isSharingLocation = false;
  String _status = 'Offline';

  Future<void> _toggleLocation() async {
    if (_isSharingLocation) {
      setState(() { _isSharingLocation = false; _status = 'Offline'; });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      setState(() { _isSharingLocation = true; _status = 'Live Tracking ON'; });
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen((Position position) {
        if (!_isSharingLocation) return;
        FirebaseService.updateDriverLocation('BUS-001', position.latitude, position.longitude);
      });
    }
  }

  void _broadcastStatus(String status) async {
    await FirebaseService.broadcastBusStatus('BUS-001', status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification sent: Bus $status'), backgroundColor: AppColors.success));
  }

  void _showAddStudentDialog() {
    final nameCtrl = TextEditingController();
    final studentIdCtrl = TextEditingController();
    final parentEmailCtrl = TextEditingController();
    final parentPassCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    bool isSearching = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Student'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: studentIdCtrl, decoration: const InputDecoration(labelText: 'Student ID (e.g. ANC001)')),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Student Name')),
              const SizedBox(height: 16),
              const Text('Parent Login Credentials', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              TextField(controller: parentEmailCtrl, decoration: const InputDecoration(labelText: 'Username (Email)')),
              TextField(controller: parentPassCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 16),
              const Text('Home Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              TextField(
                controller: addressCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Google Maps Link or Address',
                  hintText: 'Paste Google Maps link or type address',
                  suffixIcon: isSearching 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.link),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSearching ? null : () async {
                if (studentIdCtrl.text.isEmpty || addressCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields!')));
                  return;
                }

                setDialogState(() => isSearching = true);
                try {
                  String input = addressCtrl.text.trim();
                  double? lat, lng;

                  // Check if it's a Google Maps Link with coordinates
                  if (input.contains('@')) {
                    // Extract lat,lng from link like: https://www.google.com/maps/@6.9,79.8,15z
                    final parts = input.split('@')[1].split(',');
                    lat = double.tryParse(parts[0]);
                    lng = double.tryParse(parts[1]);
                  } else if (input.contains('q=')) {
                     // Extract from link like: https://maps.google.com/?q=6.9,79.8
                     final parts = input.split('q=')[1].split(',');
                     lat = double.tryParse(parts[0]);
                     lng = double.tryParse(parts[1]);
                  }

                  if (lat == null || lng == null) {
                    // Try geocoding if link extraction failed
                    List<Location> locations = await locationFromAddress(input);
                    if (locations.isNotEmpty) {
                      lat = locations.first.latitude;
                      lng = locations.first.longitude;
                    }
                  }

                  if (lat != null && lng != null) {
                    await FirebaseService.addStudent(
                      studentId: studentIdCtrl.text,
                      name: nameCtrl.text,
                      busNumber: 'BUS-001',
                      lat: lat,
                      lng: lng,
                      address: input.length > 50 ? "Google Maps Location" : input,
                      parentEmail: parentEmailCtrl.text,
                      parentPassword: parentPassCtrl.text,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student Registered successfully!')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not understand the address/link.')));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error finding location. Try typing the address instead.')));
                } finally {
                  setDialogState(() => isSearching = false);
                }
              },
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => auth.logout())],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(children: [
          _buildStatusCard(),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: _buildActionButton(icon: Icons.flight_takeoff, label: 'Departed', onTap: () => _broadcastStatus('Departed'), color: Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: _buildActionButton(icon: Icons.home, label: 'Arrived', onTap: () => _broadcastStatus('Arrived'), color: Colors.green)),
          ]),
          const SizedBox(height: 16),
          _buildActionButton(icon: Icons.person_add, label: 'Register New Student & Parent', onTap: _showAddStudentDialog, color: Colors.orange),
          const SizedBox(height: 16),
          _buildActionButton(icon: Icons.qr_code_scanner, label: 'Scan for Boarding/Arrival', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScanScreen())), color: AppColors.primary),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: _isSharingLocation ? Icons.location_off : Icons.location_on,
            label: _isSharingLocation ? 'Stop Sharing GPS' : 'Start Sharing GPS (Live)',
            onTap: _toggleLocation,
            color: _isSharingLocation ? AppColors.error : AppColors.success,
          ),
          const SizedBox(height: 24),
          const Align(alignment: Alignment.centerLeft, child: Text('Active Students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          StreamBuilder(
            stream: FirebaseService.getStudentsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final docs = snapshot.data!.docs;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(data['name'] ?? ''),
                    subtitle: Text('ID: ${data['studentId']} | ${data['address'] ?? ""}'),
                    trailing: Text(data['status'] ?? '', style: TextStyle(color: data['status'] == 'Boarded' ? Colors.green : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                  );
                },
              );
            },
          ),
        ]),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _isSharingLocation ? AppColors.cardGreen : AppColors.cardBlue, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.admin_panel_settings, size: 35, color: AppColors.primary)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Admin/Owner Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text('Status: $_status', style: TextStyle(color: _isSharingLocation ? AppColors.success : AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap, required Color color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(border: Border.all(color: color.withOpacity(0.3)), borderRadius: BorderRadius.circular(16), color: color.withOpacity(0.05)),
        child: Column(children: [Icon(icon, size: 36, color: color), const SizedBox(height: 8), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)]),
      ),
    );
  }
}
