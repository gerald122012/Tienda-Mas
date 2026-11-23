// Conexión al proyecto de Firebase "TiendasMass" (tiendasmass-abc06).
// Android usa los mismos valores de android/app/google-services.json
// e iOS/macOS los de GoogleService-Info.plist.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCG8OSqAJ9cwTEIjBswWKxOpLZPjiEw4Ck',
    appId: '1:1062532282339:web:59a7c1bd22b7f9d79f92d6',
    messagingSenderId: '1062532282339',
    projectId: 'tiendasmass-abc06',
    authDomain: 'tiendasmass-abc06.firebaseapp.com',
    storageBucket: 'tiendasmass-abc06.firebasestorage.app',
    measurementId: 'G-N2QZ4ZWPWX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDX0cUVzpK15ThMFAc8rVAH3FisLwsdT_0',
    appId: '1:1062532282339:android:0eaae2462b0b0db69f92d6',
    messagingSenderId: '1062532282339',
    projectId: 'tiendasmass-abc06',
    storageBucket: 'tiendasmass-abc06.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBicieX2ndPcXKyf-kCIiN6ThexAroQF28',
    appId: '1:1062532282339:ios:ddbf60fb9015be099f92d6',
    messagingSenderId: '1062532282339',
    projectId: 'tiendasmass-abc06',
    storageBucket: 'tiendasmass-abc06.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );
}
