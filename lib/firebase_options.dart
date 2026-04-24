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
        throw UnsupportedError('iOS not configured yet');
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBER4gbNzWcXyV4BJJcc7TRVYYpf7VLVQk',
    authDomain: 'fairlens-b0ef3.firebaseapp.com',
    projectId: 'fairlens-b0ef3',
    storageBucket: 'fairlens-b0ef3.firebasestorage.app',
    messagingSenderId: '199087054231',
    appId: '1:199087054231:web:1944e4acef3ab2374fb8d2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBER4gbNzWcXyV4BJJcc7TRVYYpf7VLVQk',
    projectId: 'fairlens-b0ef3',
    storageBucket: 'fairlens-b0ef3.firebasestorage.app',
    messagingSenderId: '199087054231',
    appId: '1:199087054231:android:1944e4acef3ab2374fb8d2',
  );
}
