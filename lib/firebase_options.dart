// Datos de conexión al proyecto de Firebase ("fitbooktravel-294a5").
// Android: mismos valores de android/app/google-services.json.
// Funciona tanto en modo Debug (DEV) como en Release/APK (PROD).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return android;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA7uANehpAWOcT4m7d_Ixt8A7HZ2OjfvcY',
    appId: '1:109460273958:android:aadc64b3ca1e2ce8145fe7',
    messagingSenderId: '109460273958',
    projectId: 'fitbooktravel-294a5',
    storageBucket: 'fitbooktravel-294a5.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA-TzY8gmwhZayNZrktqNeIJizJi4fz6Qk',
    appId: '1:109460273958:ios:01ab63264590bb39145fe7',
    messagingSenderId: '109460273958',
    projectId: 'fitbooktravel-294a5',
    storageBucket: 'fitbooktravel-294a5.firebasestorage.app',
    iosBundleId: 'com.renzoq.fitbooktravel',
  );
}
