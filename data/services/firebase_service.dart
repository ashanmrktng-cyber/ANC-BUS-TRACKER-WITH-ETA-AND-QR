import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/notification_model.dart';

class FirebaseService {
  static final _auth    = FirebaseAuth.instance;
  static final _db      = FirebaseFirestore.instance;
  static final _rtdb    = FirebaseDatabase.instance;
  static final _fcm     = FirebaseMessaging.instance;

  // Email/Password Auth
  static Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Admin: Add Student and Create Real Parent Account
  static Future<void> addStudent({
    required String studentId,
    required String name,
    required String busNumber,
    required double lat,
    required double lng,
    required String address,
    required String parentEmail,
    required String parentPassword,
  }) async {
    FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: 'SecondaryApp',
      options: Firebase.app().options,
    );
    
    try {
      UserCredential credential = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(email: parentEmail, password: parentPassword);
      
      String uid = credential.user!.uid;

      await _db.collection('users').doc(uid).set({
        'email': parentEmail,
        'password': parentPassword,
        'name': '$name Parent',
        'role': 'parent',
        'studentId': studentId,
      });

      await _db.collection('students').doc(studentId).set({
        'studentId': studentId,
        'name': name,
        'busNumber': busNumber,
        'latitude': lat,
        'longitude': lng,
        'address': address,
        'parentEmail': parentEmail,
        'parentUid': uid,
        'status': 'absent',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } finally {
      await secondaryApp.delete();
    }
  }

  // Admin: Broadcast Bus Status (Departed/Arrived)
  static Future<void> broadcastBusStatus(String busId, String status) async {
    final message = status == 'Departed' 
      ? '🚀 The bus has departed from ANC Campus!'
      : '✅ The bus has arrived at ANC Campus.';

    // Update trip type in Realtime Database for AI ETA logic
    // status == 'Departed' usually means heading HOME
    // We can also add an explicit 'Heading to School' status if needed
    await _rtdb.ref('buses/$busId').update({
      'tripType': status == 'Departed' ? 'to_home' : 'to_school',
      'lastStatus': status,
      'statusTimestamp': ServerValue.timestamp,
    });

    await _db.collection('global_notifications').add({
      'busId': busId,
      'status': status,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Admin: Notify Parent on QR Scan
  static Future<String> notifyStudentStatus(String studentId) async {
    final studentDoc = await _db.collection('students').doc(studentId).get();
    if (!studentDoc.exists) return 'error';

    final data = studentDoc.data()!;
    final studentName = data['name'];
    final parentUid = data['parentUid'];
    final currentStatus = data['status'] ?? 'absent';

    String newStatus = currentStatus == 'Boarded' ? 'Dropped' : 'Boarded';
    String emoji = newStatus == 'Boarded' ? '🚌' : '🏠';
    String action = newStatus == 'Boarded' ? 'successfully boarded the bus' : 'safely reached the destination';

    final message = '$emoji $studentName has $action.';

    await _db.collection('students').doc(studentId).update({'status': newStatus});

    if (parentUid != null) {
      await saveNotification(parentUid, {
        'title': 'Student Update: $newStatus',
        'body': message,
        'type': 'status_update',
      });
    }
    
    return newStatus;
  }

  static Stream<QuerySnapshot> getStudentsStream() => _db.collection('students').orderBy('name').snapshots();

  static Future<void> updateDriverLocation(String busId, double lat, double lng) async {
    await _rtdb.ref('buses/$busId/location').set({
      'latitude': lat, 'longitude': lng, 'timestamp': ServerValue.timestamp,
    });
  }

  // Listen to Bus Status (for ETA Logic)
  static Stream<DataSnapshot> busStatusStream(String busId) {
    return _rtdb.ref('buses/$busId').onValue.map((event) => event.snapshot);
  }

  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data();
  }

  static User? get currentUser => _auth.currentUser;
  static Future<void> signOut() => _auth.signOut();
  static Future<String?> getFcmToken() => _fcm.getToken();

  static Future<void> saveFcmToken(String userId, String token) async {
    await _db.collection('users').doc(userId).set(
      {'fcmToken': token, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  static Stream<Map<String, dynamic>?> busLocationStream(String busId) {
    return _rtdb.ref('buses/$busId/location').onValue.map((event) {
      final data = event.snapshot.value;
      if (data is Map) return Map<String, dynamic>.from(data);
      return null;
    });
  }

  static Future<void> saveNotification(String userId, Map<String, dynamic> notif) async {
    await _db.collection('users/$userId/notifications').add({
      ...notif,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  static Stream<List<NotificationModel>> notificationsStream(String userId) {
    return _db.collection('users/$userId/notifications').orderBy('timestamp', descending: true).limit(50).snapshots().map((snap) => snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return NotificationModel.fromMap(data);
      }).toList());
  }

  static Future<void> markRead(String userId, String notifId) async {
    await _db.collection('users/$userId/notifications').doc(notifId).update({'isRead': true});
  }

  static Future<void> updateBusEta(String busId, String eta) async {
    await _rtdb.ref('buses/$busId/eta').set(eta);
  }
}
