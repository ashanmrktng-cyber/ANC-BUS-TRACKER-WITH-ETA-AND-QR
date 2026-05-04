import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/tracking_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/tracking/live_tracking_screen.dart';
import 'presentation/screens/attendance/attendance_screen.dart';
import 'presentation/screens/notifications/notifications_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/qr/qr_scan_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    debugPrint('Firebase already initialized or error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TrackingProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()..initialize()),
      ],
      child: MaterialApp(
        title: 'ANC Bus Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash:        (_) => const SplashScreen(),
          AppRoutes.login:         (_) => const LoginScreen(),
          AppRoutes.dashboard:     (_) => const DashboardScreen(),
          AppRoutes.liveTracking:  (_) => const LiveTrackingScreen(),
          AppRoutes.attendance:    (_) => const AttendanceScreen(),
          AppRoutes.notifications: (_) => const NotificationsScreen(),
          AppRoutes.profile:       (_) => const ProfileScreen(),
          AppRoutes.qrScan:        (_) => const QrScanScreen(),
        },
      ),
    );
  }
}
