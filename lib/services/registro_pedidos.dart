import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pedido.dart';
import 'pedidos_local_service.dart';

enum AcuseEscritura { confirmada, rechazada, sinConfirmar, ausente }

enum TipoResultadoRegistro { confirmado, rechazado, sinConfirmar }

class ResultadoRegistro {
  final TipoResultadoRegistro tipo;
  final String id;
  final bool copiaLocalGuardada;
  final bool escrituraEnviada;

  const ResultadoRegistro({
    required this.tipo,
    required this.id,
    required this.copiaLocalGuardada,
    required this.escrituraEnviada,
  });

  bool get confirmado => tipo == TipoResultadoRegistro.confirmado;
}

class IntentoRegistro {
  final String id;
  final bool escrituraEnviada;

  const IntentoRegistro({required this.id, required this.escrituraEnviada});
}

class IntentoRegistroPedido {
  static const clave = 'intento_registro_pedido_v1';

  static String cuenta({required String uid, required String correo}) {
    final identificador = uid.trim();
    if (identificador.isNotEmpty) return 'uid:$identificador';
    final correoNormalizado = correo.trim().toLowerCase();
    if (correoNormalizado.isNotEmpty) return 'correo:$correoNormalizado';
    return '';
  }

  static Future<IntentoRegistro?> leer({
    String uid = '',
    String correo = '',
  }) async {
    final claveCuenta = cuenta(uid: uid, correo: correo);
    if (claveCuenta.isEmpty) return null;
    final mapa = await _mapa();
    final cuentas = mapa['cuentas'];
    if (cuentas is! Map) return null;
    return _intento(cuentas[claveCuenta]);
  }

  static Future<void> guardar(
    IntentoRegistro intento, {
    String uid = '',
    String correo = '',
  }) async {
    final claveCuenta = cuenta(uid: uid, correo: correo);
    if (claveCuenta.isEmpty) return;
    final mapa = await _mapa();
    final cuentas = mapa['cuentas'] is Map
        ? Map<String, dynamic>.from(mapa['cuentas'] as Map)
        : <String, dynamic>{};
    cuentas[claveCuenta] = {
      'id': intento.id,
      'escrituraEnviada': intento.escrituraEnviada,
    };
    mapa['cuentas'] = cuentas;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(clave, jsonEncode(mapa));
  }

  /// Sin cuenta, borra la marca completa. Con cuenta, solo la de esa persona.
  /// Un intento legado, guardado antes de separar cuentas, se conserva y no
  /// se asigna a nadie.
  static Future<void> limpiar({String? uid, String? correo}) async {
    final prefs = await SharedPreferences.getInstance();
    if (uid == null && correo == null) {
      await prefs.remove(clave);
      return;
    }
    final mapa = await _mapa();
    final cuentas = mapa['cuentas'] is Map
        ? Map<String, dynamic>.from(mapa['cuentas'] as Map)
        : <String, dynamic>{};
    cuentas.remove(cuenta(uid: uid ?? '', correo: correo ?? ''));
    mapa['cuentas'] = cuentas;
    await prefs.setString(clave, jsonEncode(mapa));
  }

  static Future<Map<String, dynamic>> _mapa() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(clave);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      final mapa = jsonDecode(raw);
      if (mapa is! Map) return <String, dynamic>{};
      if (mapa.containsKey('cuentas') || mapa.containsKey('legado')) {
        return Map<String, dynamic>.from(mapa);
      }
      final intento = _intento(mapa);
      if (intento == null) return <String, dynamic>{};
      final migrado = <String, dynamic>{
        'legado': {
          'id': intento.id,
          'escrituraEnviada': intento.escrituraEnviada,
        },
        'cuentas': <String, dynamic>{},
      };
      await prefs.setString(clave, jsonEncode(migrado));
      return migrado;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static IntentoRegistro? _intento(Object? raw) {
    if (raw is! Map) return null;
    final id = (raw['id'] ?? '').toString();
    if (id.isEmpty) return null;
    return IntentoRegistro(
      id: id,
      escrituraEnviada: raw['escrituraEnviada'] == true,
    );
  }
}

/// El acuse remoto exige un documento existente, sin escrituras pendientes y
/// procedente del servidor. Una instantánea de caché no confirma el pedido.
AcuseEscritura acuseDeInstantanea({
  required bool existe,
  required bool escrituraPendiente,
  required bool desdeCache,
}) {
  if (existe && !escrituraPendiente && !desdeCache) {
    return AcuseEscritura.confirmada;
  }
  return AcuseEscritura.sinConfirmar;
}

String crearIdIntento(String uid) {
  final base = uid.trim().isEmpty
      ? 'sesion'
      : uid.trim().replaceAll('/', '_');
  return 'p_${base}_${DateTime.now().millisecondsSinceEpoch}';
}

AcuseEscritura acuseDeErrorFirebase(String code) {
  switch (code) {
    case 'permission-denied':
    case 'unauthenticated':
    case 'invalid-argument':
    case 'failed-precondition':
    case 'already-exists':
      return AcuseEscritura.rechazada;
    default:
      return AcuseEscritura.sinConfirmar;
  }
}

abstract class EscritorPedidos {
  Future<AcuseEscritura> consultar(String id);
  Future<AcuseEscritura> escribir(String id, Map<String, dynamic> datos);
}

class EscritorPedidosFirestore implements EscritorPedidos {
  final FirebaseFirestore firestore;
  final Duration esperaConfirmacion;

  EscritorPedidosFirestore({
    FirebaseFirestore? firestore,
    this.esperaConfirmacion = const Duration(seconds: 8),
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _ref(String id) =>
      firestore.collection('pedidos').doc(id);

  @override
  Future<AcuseEscritura> consultar(String id) async {
    try {
      final snap = await _ref(id).get(const GetOptions(source: Source.server));
      return snap.exists ? AcuseEscritura.confirmada : AcuseEscritura.ausente;
    } on FirebaseException catch (error) {
      return acuseDeErrorFirebase(error.code);
    } catch (_) {
      return AcuseEscritura.sinConfirmar;
    }
  }

  @override
  Future<AcuseEscritura> escribir(String id, Map<String, dynamic> datos) async {
    final ref = _ref(id);
    try {
      await ref.set(datos);
    } on FirebaseException catch (error) {
      return acuseDeErrorFirebase(error.code);
    } catch (_) {
      return AcuseEscritura.sinConfirmar;
    }

    try {
      final snap = await ref
          .snapshots(includeMetadataChanges: true)
          .firstWhere(
            (dato) =>
                acuseDeInstantanea(
                  existe: dato.exists,
                  escrituraPendiente: dato.metadata.hasPendingWrites,
                  desdeCache: dato.metadata.isFromCache,
                ) ==
                AcuseEscritura.confirmada,
          )
          .timeout(esperaConfirmacion);
      return acuseDeInstantanea(
        existe: snap.exists,
        escrituraPendiente: snap.metadata.hasPendingWrites,
        desdeCache: snap.metadata.isFromCache,
      );
    } on TimeoutException {
      return AcuseEscritura.sinConfirmar;
    } on FirebaseException catch (error) {
      return acuseDeErrorFirebase(error.code);
    } catch (_) {
      return AcuseEscritura.sinConfirmar;
    }
  }
}

class RegistroPedidos {
  final EscritorPedidos escritor;
  final Future<bool> Function(Pedido pedido) guardarLocal;

  const RegistroPedidos({required this.escritor, required this.guardarLocal});

  factory RegistroPedidos.firestore() {
    return RegistroPedidos(
      escritor: EscritorPedidosFirestore(),
      guardarLocal: PedidosLocalService.instance.guardarPedido,
    );
  }

  Future<ResultadoRegistro> registrar(
    Pedido borrador, {
    required bool escrituraEnviada,
  }) async {
    final id = borrador.id;
    final consulta = await _consultar(id);
    if (consulta == AcuseEscritura.confirmada) {
      final copia = await _copiaLocal(borrador);
      return ResultadoRegistro(
        tipo: TipoResultadoRegistro.confirmado,
        id: id,
        copiaLocalGuardada: copia,
        escrituraEnviada: true,
      );
    }
    if (escrituraEnviada && consulta != AcuseEscritura.ausente) {
      if (consulta == AcuseEscritura.rechazada) {
        return ResultadoRegistro(
          tipo: TipoResultadoRegistro.rechazado,
          id: id,
          copiaLocalGuardada: false,
          escrituraEnviada: false,
        );
      }
      return ResultadoRegistro(
        tipo: TipoResultadoRegistro.sinConfirmar,
        id: id,
        copiaLocalGuardada: false,
        escrituraEnviada: true,
      );
    }

    final acuse = await _escribir(id, borrador.toFirestoreMap());
    if (acuse == AcuseEscritura.confirmada) {
      final copia = await _copiaLocal(borrador);
      return ResultadoRegistro(
        tipo: TipoResultadoRegistro.confirmado,
        id: id,
        copiaLocalGuardada: copia,
        escrituraEnviada: true,
      );
    }
    if (acuse == AcuseEscritura.rechazada) {
      return ResultadoRegistro(
        tipo: TipoResultadoRegistro.rechazado,
        id: id,
        copiaLocalGuardada: false,
        escrituraEnviada: false,
      );
    }
    return ResultadoRegistro(
      tipo: TipoResultadoRegistro.sinConfirmar,
      id: id,
      copiaLocalGuardada: false,
      escrituraEnviada: true,
    );
  }

  Future<AcuseEscritura> _consultar(String id) async {
    try {
      return await escritor.consultar(id);
    } catch (_) {
      return AcuseEscritura.sinConfirmar;
    }
  }

  Future<AcuseEscritura> _escribir(String id, Map<String, dynamic> datos) async {
    try {
      return await escritor.escribir(id, datos);
    } catch (_) {
      return AcuseEscritura.sinConfirmar;
    }
  }

  Future<bool> _copiaLocal(Pedido pedido) async {
    try {
      return await guardarLocal(pedido);
    } catch (_) {
      return false;
    }
  }
}
