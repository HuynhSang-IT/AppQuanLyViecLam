import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAS5qWwI-l1CIURJP6O9CBYbyHx3ofZx9Q',
    authDomain: 'app-quan-ly-viec-lam.firebaseapp.com',
    projectId: 'app-quan-ly-viec-lam',
    storageBucket: 'app-quan-ly-viec-lam.firebasestorage.app',
    messagingSenderId: '387067821055',
    appId: '1:387067821055:web:12354d910628450a7f05ca',
    measurementId: 'G-PKSX60M3LX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAS5qWwI-l1CIURJP6O9CBYbyHx3ofZx9Q',
    appId: '1:387067821055:android:xxxxx',
    messagingSenderId: '387067821055',
    projectId: 'app-quan-ly-viec-lam',
    storageBucket: 'app-quan-ly-viec-lam.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAS5qWwI-l1CIURJP6O9CBYbyHx3ofZx9Q',
    appId: '1:387067821055:ios:xxxxx',
    messagingSenderId: '387067821055',
    projectId: 'app-quan-ly-viec-lam',
    storageBucket: 'app-quan-ly-viec-lam.firebasestorage.app',
    iosBundleId: 'com.example.appQuanlyvieclam',
  );
}