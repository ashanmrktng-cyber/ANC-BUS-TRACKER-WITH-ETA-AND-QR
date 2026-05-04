import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS:     return ios;
      default: throw UnsupportedError(
        'DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyDeMRRDMJs6bKv3afSjIg548EnHOrLrrEY',
    appId:             '1:3572867628:android:1dd931f4862aef8ea62789',
    messagingSenderId: '3572867628',
    projectId:         'anc-bus-tracker',
    storageBucket:     'anc-bus-tracker.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'AIzaSyDeMRRDMJs6bKv3afSjIg548EnHOrLrrEY',
    appId:             '1:3572867628:ios:placeholder',
    messagingSenderId: '3572867628',
    projectId:         'anc-bus-tracker',
    storageBucket:     'anc-bus-tracker.firebasestorage.app',
    iosBundleId:       'com.ancschool.bustracker',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyDeMRRDMJs6bKv3afSjIg548EnHOrLrrEY',
    appId:             '1:3572867628:web:placeholder',
    messagingSenderId: '3572867628',
    projectId:         'anc-bus-tracker',
    storageBucket:     'anc-bus-tracker.firebasestorage.app',
    authDomain:        'anc-bus-tracker.firebaseapp.com',
  );
}
