import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/usuario.dart';
import 'carrito_service.dart';

const kPermitirCuentasLocales = true;

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _cuentasLocales = [
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
  bool _esLocal = false;
  StreamSubscription<User?>? _suscripcion;

  Usuario? get usuario => _usuario;

  String _claveFoto(String correo) => 'perfil_foto_${correo.toLowerCase()}';

  Future<String?> _leerFotoLocal(String correo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_claveFoto(correo));
    } catch (_) {
      return null;
    }
  }

  Future<void> actualizarFotoPerfil(String? base64Foto) async {
    final actual = _usuario;
    if (actual == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (base64Foto == null || base64Foto.isEmpty) {
        await prefs.remove(_claveFoto(actual.correo));
      } else {
        await prefs.setString(_claveFoto(actual.correo), base64Foto);
      }
    } catch (_) {}

    if (!_esLocal) {
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .set({
                'fotoBase64': base64Foto ?? '',
              }, SetOptions(merge: true));
        }
      } catch (_) {}
    }

    _usuario = base64Foto == null || base64Foto.isEmpty
        ? actual.copyWith(limpiarFoto: true)
        : actual.copyWith(fotoBase64: base64Foto);
    notifyListeners();
  }

  void iniciar() {
    _suscripcion ??= FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) async {
      if (_esLocal) return;
      if (user == null) {
        _fijar(null);
      } else {
        final perfil = await _perfil(user);
        if (kIsWeb && !perfil.esAdmin) {
          await cerrarSesion();
          return;
        }
        if (!kIsWeb && perfil.esAdmin) {
          await cerrarSesion();
          return;
        }
        _fijar(perfil);
      }
    });
  }

  String? _validarRol(Usuario u, Rol? rolRequerido) {
    if (rolRequerido == null) return null;
    if (rolRequerido == Rol.administrador && !u.esAdmin) {
      return 'Acceso restringido: la página web es exclusiva para administradores.';
    }
    if (rolRequerido == Rol.cliente && u.esAdmin) {
      return 'La aplicación móvil es solo para clientes. Usa la página web para administrar.';
    }
    return null;
  }

  Future<String?> iniciarSesion(
    String correo,
    String clave, {
    Rol? rolRequerido,
  }) async {
    final c = correo.trim().toLowerCase();
    if (kPermitirCuentasLocales) {
      for (final cuenta in _cuentasLocales) {
        if (cuenta.usuario.correo == c && cuenta.clave == clave) {
          final errorRol = _validarRol(cuenta.usuario, rolRequerido);
          if (errorRol != null) return errorRol;
          _esLocal = true;
          final foto = await _leerFotoLocal(c);
          _fijar(cuenta.usuario.copyWith(fotoBase64: foto));
          return null;
        }
      }
    }
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: c,
        password: clave,
      );
      final perfil = await _perfil(cred.user!);
      final errorRol = _validarRol(perfil, rolRequerido);
      if (errorRol != null) {
        try {
          await FirebaseAuth.instance.signOut();
        } catch (_) {}
        return errorRol;
      }
      _esLocal = false;
      _fijar(perfil);
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
      } catch (_) {}
      _esLocal = false;
      _fijar(usuario);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mensaje(e);
    } catch (_) {
      return 'No se pudo crear la cuenta. Revisa tu conexión.';
    }
  }

  Future<void> cerrarSesion() async {
    final eraLocal = _esLocal;
    _esLocal = false;
    _fijar(null);
    if (!eraLocal) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
  }

  void _fijar(Usuario? u) {
    _usuario = u;
    if (u == null || u.esAdmin) CarritoService.instance.vaciar();
    notifyListeners();
  }

  Future<Usuario> _perfil(User user) async {
    var rol = Rol.cliente;
    var nombre = user.displayName ?? '';
    String? foto;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      final datos = doc.data();
      if (datos != null) {
        if (datos['rol'] == 'administrador') rol = Rol.administrador;
        nombre = (datos['nombre'] ?? nombre).toString();
        final fotoDb = (datos['fotoBase64'] ?? '').toString();
        if (fotoDb.isNotEmpty) foto = fotoDb;
      }
    } catch (_) {}
    final correo = user.email ?? '';
    foto ??= await _leerFotoLocal(correo);
    return Usuario(
      nombre: nombre.isEmpty ? correo : nombre,
      correo: correo,
      rol: rol,
      fotoBase64: foto,
    );
  }

  String _mensaje(FirebaseAuthException e) => switch (e.code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Correo o contraseña incorrectos.',
    'invalid-email' => 'El correo no es válido.',
    'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
    'weak-password' => 'La contraseña debe tener al menos 6 caracteres.',
    'too-many-requests' => 'Demasiados intentos. Intenta más tarde.',
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
