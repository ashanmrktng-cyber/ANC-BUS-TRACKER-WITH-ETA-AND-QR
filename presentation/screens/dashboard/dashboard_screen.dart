import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/eta_service.dart';
import '../../../data/services/firebase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/tracking_provider.dart';
import '../tracking/live_tracking_screen.dart';
import '../attendance/attendance_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import 'driver_dashboard_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user != null) {
        Provider.of<NotificationProvider>(context, listen: false)
            .listenToNotifications(auth.user!.userId);
            
        if (auth.user!.role == UserRole.parent) {
          _setupDynamicParentTracking(auth.user!.userId);
        }
      }
    });
  }

  Future<void> _setupDynamicParentTracking(String userId) async {
    final tp = Provider.of<TrackingProvider>(context, listen: false);
    
    // 1. Get Student Home Location
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final studentId = userDoc.data()?['studentId'];
    LatLng? homeLoc;
    
    if (studentId != null) {
      final studentDoc = await FirebaseFirestore.instance.collection('students').doc(studentId).get();
      final data = studentDoc.data();
      if (data != null && data['latitude'] != null) {
        homeLoc = LatLng(data['latitude'], data['longitude']);
      }
    }

    // 2. Listen to Bus Status to Decide Destination (School or Home)
    FirebaseService.busStatusStream('BUS-001').listen((snap) {
      if (snap.value is Map) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        final tripType = data['tripType'] ?? 'to_school'; // default morning trip

        if (tripType == 'to_home' && homeLoc != null) {
          tp.setDestination(homeLoc, 'Home');
        } else {
          tp.setDestination(EtaService.schoolLocation, 'ANC Campus');
        }
      }
    });
    
    tp.startTracking('BUS-001');
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (user?.role == UserRole.driver) {
      return const DriverDashboardScreen();
    }

    final screens = const [
      _HomeTab(),
      LiveTrackingScreen(),
      AttendanceScreen(),
      NotificationsScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Consumer<NotificationProvider>(
        builder: (_, np, __) => BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            const BottomNavigationBarItem(icon: Icon(Icons.location_on_rounded), label: 'Track'),
            const BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'Attendance'),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: np.unreadCount > 0,
                label: Text('${np.unreadCount}'),
                child: const Icon(Icons.notifications_rounded),
              ),
              label: 'Alerts',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final np   = Provider.of<NotificationProvider>(context);
    final tp   = Provider.of<TrackingProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 160,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primaryLight],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Hello, ${user?.name ?? "Parent"}!',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text(AppStrings.schoolName,
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ])),
                      IconButton(
                        icon: Badge(
                          isLabelVisible: np.unreadCount > 0,
                          label: Text('${np.unreadCount}'),
                          child: const Icon(Icons.notifications_outlined, color: Colors.white),
                        ),
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
                      ),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // AI Dynamic Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: tp.bus?.status == 'moving' 
                      ? [AppColors.primary, AppColors.primaryLight]
                      : [Colors.blueGrey, Colors.blueGrey.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(14)),
                    child: Icon(
                      tp.bus?.status == 'moving' ? Icons.directions_bus : Icons.pause_circle,
                      color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      tp.bus?.status == 'moving' ? 'Bus is Heading to ${tp.destinationName}' : 'Bus is Currently Stopped', 
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      tp.bus?.status == 'moving' ? 'Tracking with Live Traffic AI' : 'Waiting for departure...',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        tp.eta != null ? 'ETA: ${tp.eta}' : 'ETA: Calculating...', 
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ])),
                ]),
              ),

              const SizedBox(height: 24),
              const Text('Quick Actions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.4,
                children: [
                  _quickAction(context, Icons.location_on_rounded, 'Live Track', AppColors.cardBlue, AppColors.primary, AppRoutes.liveTracking),
                  _quickAction(context, Icons.qr_code_scanner, 'QR Check-in', AppColors.cardGreen, AppColors.success, AppRoutes.qrScan),
                  _quickAction(context, Icons.calendar_today_rounded, 'Attendance', AppColors.cardOrange, AppColors.warning, AppRoutes.attendance),
                  _quickAction(context, Icons.notifications_active_rounded, 'Alerts', AppColors.cardRed, AppColors.error, AppRoutes.notifications),
                ],
              ),

              const SizedBox(height: 24),
              const Text('Today\'s Student Status', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              
              // Real-time student status list
              StreamBuilder(
                stream: FirebaseFirestore.instance.collection('students').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  
                  // Find the child for the current parent
                  final user = Provider.of<AuthProvider>(context).user;
                  final myStudent = snapshot.data!.docs.where((d) => d.data()['parentUid'] == user?.userId).firstOrNull;

                  if (myStudent == null) return const Text('No student assigned.');
                  
                  final data = myStudent.data();
                  final status = data['status'] ?? 'absent';
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
                    child: Row(children: [
                      CircleAvatar(backgroundColor: AppColors.cardBlue, child: Icon(Icons.person, color: AppColors.primary)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(data['name'] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Student ID: ${data['studentId']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'Boarded' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(status.toUpperCase(), style: TextStyle(color: status == 'Boarded' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ]),
                  );
                }
              ),
              
              const SizedBox(height: 30),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _quickAction(BuildContext ctx, IconData icon, String label, Color bg, Color iconColor, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(ctx, route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _featureRow(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.cardBlue, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppColors.primary, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        const Icon(Icons.check_circle, color: AppColors.success, size: 18),
      ]),
    );
  }
}
