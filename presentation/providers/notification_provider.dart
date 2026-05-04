import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/firebase_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  static const _channel = AndroidNotificationChannel(
    'anc_bus_channel', 'ANC Bus Alerts',
    description: 'School bus alerts and updates',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await FirebaseMessaging.instance.requestPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));

    // Handle Foreground Notifications
    FirebaseMessaging.onMessage.listen((msg) {
      _showLocal(
        msg.notification?.title ?? 'Bus Alert',
        msg.notification?.body ?? '',
        msg.data['type'] ?? 'alert',
      );
    });

    // Handle Global Broadcasts (Departed/Arrived)
    _listenToGlobalBroadcasts();
    
    _isInitialized = true;
  }

  void _listenToGlobalBroadcasts() {
    FirebaseFirestore.instance
        .collection('global_notifications')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snap) {
      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        final timestamp = data['timestamp'] as Timestamp?;
        // Only show if it happened in the last 5 minutes (to avoid old alerts on app start)
        if (timestamp != null && 
            DateTime.now().difference(timestamp.toDate()).inMinutes < 5) {
          _showLocal('Bus Update', data['message'] ?? '', 'broadcast');
        }
      }
    });
  }

  void listenToNotifications(String userId) {
    FirebaseService.notificationsStream(userId).listen((list) {
      _notifications = list;
      notifyListeners();
    });
  }

  Future<void> _showLocal(String title, String body, String type) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id, _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF0D47A1),
        playSound: true,
      ),
    );
    await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details);
  }

  Future<void> markRead(String userId, String notifId) async {
    await FirebaseService.markRead(userId, notifId);
  }
}
