import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import 'carrito_service.dart';

// Cuentas locales de PRUEBA que funcionan sin configurar nada en Firebase.
// Ponlo en false antes de publicar la app.
const kPermitirCuentasDemo = true;

// Sesión de la app con Firebase Authentication (correo y contraseña).
// El rol vive en Firestore: usuarios/{uid}.rol ("cliente" o "administrador").
// Quien se registra desde la app siempre queda como cliente; para crear un
// administrador se cambia el campo "rol" a mano en la consola de Firebase.
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _demo = [
    _Cuenta(
      clave: 'Admin123',
      usuario: Usuario(
        nombre: 'Administrador Mass',
        correo: 'admin@tiendamass.pe',
        rol: Rol.administrador,
      ),
    ),
    _Cuenta(
      clave: 'Cliente123',
      usuario: Usuario(
        nombre: 'Cliente Mass',
        correo: 'cliente@tiendamass.pe',
        rol: Rol.cliente,
      ),
    ),
  ];

  Usuario? _usuario;
  bool _esDemo = false;
  StreamSubscription<User?>? _suscripcion;

  // null = invitado (anónimo): puede ver todo y armar su carrito.
  Usuario? get usuario => _usuario;

  // Restaura la sesión de Firebase al abrir la app.
  void iniciar() {
    _suscripcion ??= FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) async {
      if (_esDemo) return;
      if (user == null) {
        _fijar(null);
      } else {
        _fijar(await _perfil(user));
      }
    });
  }

  // Devuelve null si todo salió bien, o el mensaje de error para mostrar.
  Future<String?> iniciarSesion(String correo, String clave) async {
    final c = correo.trim().toLowerCase();
    if (kPermitirCuentasDemo) {
      for (final cuenta in _demo) {
        if (cuenta.usuario.correo == c && cuenta.clave == clave) {
          _esDemo = true;
          _fijar(cuenta.usuario);
          return null;
        }
      }
    }
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: c,
        password: clave,
      );
      _esDemo = false;
      _fijar(await _perfil(cred.user!));
      return null;
    } on FirebaseAuthException catch (e) {
      return _mensaje(e);
    } catch (_) {
      return 'No se pudo iniciar sesión. Revisa tu conexión.';
    }
  }

  Future<String?> registrar(String nombre, String correo, String clave) async {
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: correo.trim().toLowerCase(),
        password: clave,
      );
      final user = cred.user!;
      await user.updateDisplayName(nombre.trim());
      final usuario = Usuario(
        nombre: nombre.trim(),
        correo: user.email ?? correo.trim(),
        rol: Rol.cliente,
      );
      try {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .set({
              'nombre': usuario.nombre,
              'correo': usuario.correo,
              'rol': 'cliente',
              'fechaRegistro': Timestamp.now(),
            });
      } catch (_) {
        // Si Firestore rechaza la escritura, la cuenta igual queda como cliente.
      }
      _esDemo = false;
      _fijar(usuario);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mensaje(e);
    } catch (_) {
      return 'No se pudo crear la cuenta. Revisa tu conexión.';
    }
  }

  Future<void> cerrarSesion() async {
    final eraDemo = _esDemo;
    _esDemo = false;
    _fijar(null);
    if (!eraDemo) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
  }

  void _fijar(Usuario? u) {
    _usuario = u;
    // El carrito de invitado solo aplica a clientes; al salir se descarta.
    if (u == null || u.esAdmin) CarritoService.instance.vaciar();
    notifyListeners();
  }

  Future<Usuario> _perfil(User user) async {
    var rol = Rol.cliente;
    var nombre = user.displayName ?? '';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      final datos = doc.data();
      if (datos != null) {
        if (datos['rol'] == 'administrador') rol = Rol.administrador;
        nombre = (datos['nombre'] ?? nombre).toString();
      }
    } catch (_) {}
    final correo = user.email ?? '';
    return Usuario(
      nombre: nombre.isEmpty ? correo : nombre,
      correo: correo,
      rol: rol,
    );
  }

  String _mensaje(FirebaseAuthException e) => switch (e.code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Correo o contraseña incorrectos.',
    'invalid-email' => 'El correo no es válido.',
    'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
    'weak-password' => 'La contraseña debe tener al menos 6 caracteres.',
    'too-many-requests' => 'Demasiados intentos. Prueba más tarde.',
    'network-request-failed' => 'Sin conexión. Revisa tu internet.',
    'operation-not-allowed' =>
      'El acceso con correo no está activado en Firebase.',
    _ => 'No se pudo completar la operación (${e.code}).',
  };
}

class _Cuenta {
  final String clave;
  final Usuario usuario;
  const _Cuenta({required this.clave, required this.usuario});
}
