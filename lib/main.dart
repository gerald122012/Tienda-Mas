import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MiApp());
}

// Colores oficiales de la web de Tiendas Mass (https://www.tiendasmass.com.pe)
const kMassYellow = Color(0xFFFFD100);
const kMassBlue = Color(0xFF082EB7);
const kMassMint = Color(0xFFD6F8F4);
const kMassCream = Color(0xFFFFF8D9);
const kMassTurquoise = Color(0xFF33DDC8);
const kMassDark = Color(0xFF1E1E1E);

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tiendas Mass | Lleva Mass pagando Menos',
      debugShowCheckedModeBanner: false,
      // Permite desplazar las pantallas arrastrando con mouse o touchpad.
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kMassBlue,
          primary: kMassBlue,
          secondary: kMassYellow,
        ),
        scaffoldBackgroundColor: kMassCream,
        // Barra superior amarilla con letras azules como el navbar de la web Mass.
        appBarTheme: const AppBarTheme(
          backgroundColor: kMassYellow,
          foregroundColor: kMassBlue,
          centerTitle: false,
          elevation: 2,
          titleTextStyle: TextStyle(
            color: kMassBlue,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kMassBlue,
            foregroundColor: kMassYellow,
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: kMassBlue,
          foregroundColor: kMassYellow,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
