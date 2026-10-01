// File generated for fatloss-plan Firebase project
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
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC_3dJybfohwBfz66_dJg955OGud0CYhU4',
    appId: '1:80481245178:web:cc8c282a8ce4cdc862b643',
    messagingSenderId: '80481245178',
    projectId: 'fatloss-plan',
    authDomain: 'fatloss-plan.firebaseapp.com',
    databaseURL: 'https://fatloss-plan-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'fatloss-plan.firebasestorage.app',
    measurementId: 'G-0YVG0BHHZW',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC_3dJybfohwBfz66_dJg955OGud0CYhU4',
    appId: '1:80481245178:android:cc8c282a8ce4cdc862b643',
    messagingSenderId: '80481245178',
    projectId: 'fatloss-plan',
    databaseURL: 'https://fatloss-plan-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'fatloss-plan.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC_3dJybfohwBfz66_dJg955OGud0CYhU4',
    appId: '1:80481245178:ios:cc8c282a8ce4cdc862b643',
    messagingSenderId: '80481245178',
    projectId: 'fatloss-plan',
    databaseURL: 'https://fatloss-plan-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'fatloss-plan.firebasestorage.app',
  );
}
