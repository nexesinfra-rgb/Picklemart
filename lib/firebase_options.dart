// File generated to provide Firebase configuration for all platforms
// This file contains Firebase options for web, Android, and iOS platforms

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC5rDRqRo0dJzdN9CHbc29SVK6NpoeoMIg',
    appId: '1:841284842794:web:f93ac9e5511653e9bc9a53',
    messagingSenderId: '841284842794',
    projectId: 'picklemart-9a4b0',
    authDomain: 'picklemart-9a4b0.firebaseapp.com',
    storageBucket: 'picklemart-9a4b0.firebasestorage.app',
    measurementId: 'G-W2J3298KW0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDMFgxHHUpikbDUGZJTRXaM0Cobhs3Kgew',
    appId: '1:841284842794:android:fa6ee0566a3f28e7bc9a53',
    messagingSenderId: '841284842794',
    projectId: 'picklemart-9a4b0',
    storageBucket: 'picklemart-9a4b0.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCUaU_Qir5redO1AjxtlU7jnPJ2yaa9mTA',
    appId: '1:841284842794:ios:e0e9b51e6b880b68bc9a53',
    messagingSenderId: '841284842794',
    projectId: 'picklemart-9a4b0',
    storageBucket: 'picklemart-9a4b0.firebasestorage.app',
    iosBundleId: 'com.picklemart.app',
  );
}

