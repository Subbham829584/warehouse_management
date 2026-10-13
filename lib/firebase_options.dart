// File: lib/firebase_options.dart
// Configured for Firebase Project: warehouse-management-50e0f

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  /// Live Firebase is active
  static const bool isConfigured = true;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      default:
        return web;
    }
  }

  /// Web Firebase configuration for project: warehouse-management-50e0f
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB6rzafdbTdNUgNk8KTWRvfRe4H6sjub_o',
    appId: '1:490067730160:web:6eabac58e1141eb6852c35',
    messagingSenderId: '490067730160',
    projectId: 'warehouse-management-50e0f',
    authDomain: 'warehouse-management-50e0f.firebaseapp.com',
    storageBucket: 'warehouse-management-50e0f.firebasestorage.app',
    measurementId: 'G-GH9Z9M9GHJ',
  );

  /// Android Firebase configuration
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB6rzafdbTdNUgNk8KTWRvfRe4H6sjub_o',
    appId: '1:490067730160:android:6eabac58e1141eb6852c35',
    messagingSenderId: '490067730160',
    projectId: 'warehouse-management-50e0f',
    storageBucket: 'warehouse-management-50e0f.firebasestorage.app',
  );

  /// Windows Firebase configuration
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB6rzafdbTdNUgNk8KTWRvfRe4H6sjub_o',
    appId: '1:490067730160:windows:6eabac58e1141eb6852c35',
    messagingSenderId: '490067730160',
    projectId: 'warehouse-management-50e0f',
    storageBucket: 'warehouse-management-50e0f.firebasestorage.app',
  );
}
