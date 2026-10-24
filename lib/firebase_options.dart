// Datos de conexión al proyecto de Firebase "FitBookTravel" (solo Android).
// Son los mismos valores del archivo android/app/google-services.json.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: 'AIzaSyA7uANehpAWOcT4m7d_Ixt8A7HZ2OjfvcY',
    appId: '1:109460273958:android:aadc64b3ca1e2ce8145fe7',
    messagingSenderId: '109460273958',
    projectId: 'fitbooktravel-294a5',
    storageBucket: 'fitbooktravel-294a5.firebasestorage.app',
  );
}
