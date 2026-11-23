import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/admin/admin_web_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/pedidos_local_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  }
  try {
    AuthService.instance.iniciar();
  } catch (_) {}
  await PedidosLocalService.instance.cargar();
  runApp(const MiApp());
}

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
      title: kIsWeb ? 'TiendasMass · Administrador' : 'TiendasMass',
      debugShowCheckedModeBanner: false,
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
        appBarTheme: const AppBarTheme(
          backgroundColor: kMassYellow,
          foregroundColor: kMassBlue,
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 2,
          titleTextStyle: TextStyle(
            color: kMassBlue,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kMassBlue,
            foregroundColor: kMassYellow,
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: kMassBlue,
          foregroundColor: kMassYellow,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1.5,
          shadowColor: kMassBlue.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: kMassBlue.withValues(alpha: 0.08)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: kMassBlue.withValues(alpha: 0.18)),
          ),
        ),
      ),
      home: ListenableBuilder(
        listenable: AuthService.instance,
        builder: (context, _) {
          final usuario = AuthService.instance.usuario;
          if (kIsWeb) {
            if (usuario == null || !usuario.esAdmin) {
              return const LoginScreen(soloAdmin: true);
            }
            return AdminWebShell(
              key: ValueKey('admin_${usuario.correo}'),
              usuario: usuario,
            );
          }
          final cliente = (usuario != null && !usuario.esAdmin)
              ? usuario
              : null;
          return HomeScreen(
            key: ValueKey(cliente?.correo ?? 'invitado'),
            usuario: cliente,
          );
        },
      ),
    );
  }
}
