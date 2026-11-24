import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cupon.dart';
import '../models/producto.dart';
import '../models/respuesta_massbot.dart';
import '../models/tienda.dart';
import 'catalogo_inicial_service.dart';
import 'catalogo_sesion.dart';

/// MassBot dentro de la app: responde con el catálogo, las tiendas y los
/// cupones de Firebase cuando el servidor con IA no está disponible.
class MassBotLocal {
  final Future<List<Producto>> Function()? cargarProductos;
  final Future<List<Tienda>> Function()? cargarTiendas;
  final Future<List<CuponDescuento>> Function()? cargarCupones;

  const MassBotLocal({
    this.cargarProductos,
    this.cargarTiendas,
    this.cargarCupones,
  });

  static const _espera = Duration(seconds: 6);

  Future<RespuestaMassBot> responder(String mensaje) async {
    final texto = normalizar(mensaje);

    if (RegExp(
      r'ignora|instrucciones|api key|clave|contrasena|password|system prompt',
    ).hasMatch(texto)) {
      return _respuesta(
        'Solo puedo ayudarte con productos, precios, tiendas y cupones de Mass.',
      );
    }
    if (RegExp(r'devolucion|devolver|cambiar un producto|cambio').hasMatch(texto)) {
      return _respuesta(
        'Puedes cambiar un producto en cualquier tienda Mass presentando tu '
        'pedido. Revisa el detalle en Mis Compras.',
      );
    }
    if (RegExp(r'promocion|cupon|oferta|descuento').hasMatch(texto)) {
      final cupones = await _cupones();
      return _respuesta(
        cupones.isEmpty
            ? 'Por ahora no hay cupones vigentes.'
            : 'Estos son los cupones vigentes. Aplícalos en tu carrito:',
        cupones: [
          for (final c in cupones.take(4))
            CuponMassBot(
              codigo: c.codigo,
              descripcion: c.descripcion,
              tipo: c.tipo,
              valor: c.valor,
              montoMinimo: c.montoMinimo,
            ),
        ],
      );
    }
    if (RegExp(r'donde|tienda|horario|ubicacion|sucursal|local').hasMatch(texto)) {
      final todas = await _tiendas();
      final ciudad = Tienda.ciudades.firstWhere(
        (c) => texto.contains(normalizar(c)),
        orElse: () => '',
      );
      final lista = ciudad.isEmpty
          ? todas
          : todas.where((t) => normalizar(t.ciudad) == normalizar(ciudad)).toList();
      return _respuesta(
        lista.isEmpty
            ? 'No encontré tiendas${ciudad.isEmpty ? '' : ' en $ciudad'}. Revisa la pestaña Ubícame.'
            : 'Estas son tiendas Mass${ciudad.isEmpty ? '' : ' en $ciudad'}:',
        tiendas: [
          for (final t in lista.take(3))
            TiendaMassBot(
              nombre: t.nombre,
              distrito: t.distrito,
              direccion: t.direccion,
              horario: t.horario,
              abierta: t.estaAbierta,
            ),
        ],
      );
    }
    if (RegExp(r'clima|lluvia|tarea|matematica|politica|futbol|dolar|bitcoin')
        .hasMatch(texto)) {
      return _respuesta(
        'Solo puedo ayudarte con tu compra en Mass: productos, precios, '
        'presupuesto, tiendas y cupones.',
      );
    }

    final productos = (await _productos())
        .where((p) => p.disponible && p.stock > 0)
        .toList();
    if (productos.isEmpty) {
      return _respuesta('No pude cargar el catálogo. Revisa tu conexión.');
    }

    final monto = RegExp(r'(\d+(?:[.,]\d{1,2})?)\s*(?:soles?|s/)')
            .firstMatch(texto) ??
        RegExp(r's/\s*(\d+(?:[.,]\d{1,2})?)').firstMatch(texto);
    final preferencia = ['desayuno', 'almuerzo', 'cena', 'limpieza']
        .firstWhere(texto.contains, orElse: () => '');
    if (monto != null || preferencia.isNotEmpty) {
      final presupuesto =
          monto == null ? 50.0 : double.parse(monto.group(1)!.replaceAll(',', '.'));
      return _armarLista(productos, presupuesto, preferencia);
    }

    final consulta = _palabrasClave(texto);
    if (RegExp(r'economico|barato|compara|diferencia').hasMatch(texto)) {
      final encontrados = _buscar(productos, consulta)
        ..sort((a, b) => a.precio.compareTo(b.precio));
      if (encontrados.isEmpty) return _sinResultados();
      return _respuesta(
        'Ordené las opciones de menor a mayor precio:',
        productos: [for (final p in encontrados.take(3)) _producto(p)],
      );
    }
    if (consulta.isEmpty || RegExp(r'que productos|disponibles|que hay').hasMatch(texto)) {
      final baratos = [...productos]..sort((a, b) => a.precio.compareTo(b.precio));
      return _respuesta(
        'Tenemos ${productos.length} productos disponibles. Algunos de los más económicos:',
        productos: [for (final p in baratos.take(4)) _producto(p)],
      );
    }
    final encontrados = _buscar(productos, consulta);
    if (encontrados.isEmpty) return _sinResultados();
    return _respuesta(
      'Encontré ${encontrados.length == 1 ? 'este producto' : 'estos productos'}:',
      productos: [for (final p in encontrados.take(4)) _producto(p)],
    );
  }

  RespuestaMassBot _armarLista(
    List<Producto> productos,
    double presupuesto,
    String preferencia,
  ) {
    const afines = {
      'desayuno': ['leche', 'avena', 'cafe', 'pan', 'yogurt', 'mantequilla', 'azucar'],
      'almuerzo': ['arroz', 'aceite', 'fideo', 'atun', 'lenteja', 'sal', 'mayonesa'],
      'cena': ['fideo', 'atun', 'leche', 'queso', 'galleta'],
      'limpieza': ['detergente', 'lejia', 'lavavajilla', 'jabon', 'esponja', 'papel'],
    };
    final claves = afines[preferencia] ?? const <String>[];
    final candidatos = [...productos]
      ..sort((a, b) {
        final pa = claves.any((k) => normalizar(a.nombre).contains(k)) ? 0 : 1;
        final pb = claves.any((k) => normalizar(b.nombre).contains(k)) ? 0 : 1;
        return pa != pb ? pa - pb : a.precio.compareTo(b.precio);
      });
    final elegidos = <Producto>[];
    var total = 0.0;
    for (final p in candidatos) {
      if (elegidos.length == 4) break;
      if (total + p.precio <= presupuesto) {
        elegidos.add(p);
        total += p.precio;
      }
    }
    if (elegidos.isEmpty) {
      return _respuesta(
        'Con S/ ${presupuesto.toStringAsFixed(2)} no alcanza para ningún producto del catálogo.',
      );
    }
    return RespuestaMassBot(
      texto: 'Con S/ ${presupuesto.toStringAsFixed(2)} te propongo esta lista'
          '${preferencia.isEmpty ? '' : ' para $preferencia'}:',
      productos: [
        for (final p in elegidos) _producto(p, cantidad: 1, subtotal: p.precio),
      ],
      tiendas: const [],
      cupones: const [],
      presupuesto: presupuesto,
      total: total,
      restante: presupuesto - total,
      consultadoEn: DateTime.now().toIso8601String(),
      simulado: false,
      sinConexion: true,
    );
  }

  List<Producto> _buscar(List<Producto> productos, List<String> palabras) {
    int puntaje(Producto p) {
      final campo = normalizar('${p.nombre} ${p.marca} ${p.categoria}');
      return palabras.where(campo.contains).length;
    }

    final conPuntos = [
      for (final p in productos)
        if (puntaje(p) > 0) p,
    ]..sort((a, b) => puntaje(b).compareTo(puntaje(a)));
    return conPuntos;
  }

  List<String> _palabrasClave(String texto) {
    const ruido = {
      'hola', 'quiero', 'busco', 'tienes', 'tienen', 'hay', 'precio', 'cuanto',
      'cuesta', 'el', 'la', 'los', 'las', 'un', 'una', 'de', 'del', 'que', 'me',
      'mas', 'mejor', 'economico', 'barato', 'compara', 'comparar', 'para',
      'por', 'favor', 'y', 'o', 'con', 'en', 'productos', 'producto', 'algo',
    };
    return texto
        .split(RegExp(r'[^a-z0-9]+'))
        .where((p) => p.length > 2 && !ruido.contains(p))
        .map((p) => p.endsWith('s') && p.length > 4 ? p.substring(0, p.length - 1) : p)
        .toList();
  }

  RespuestaMassBot _sinResultados() => _respuesta(
    'No encontré ese producto. Prueba con otra palabra, por ejemplo '
    '"arroz", "leche" o "gaseosa".',
  );

  ProductoMassBot _producto(Producto p, {int cantidad = 0, double? subtotal}) {
    return ProductoMassBot(
      id: p.id,
      nombre: p.nombre,
      marca: p.marca,
      categoria: p.categoria,
      presentaciones: p.presentaciones,
      precio: p.precio,
      stock: p.stock,
      disponible: p.disponible,
      cantidad: cantidad,
      subtotal: subtotal,
      imagenAsset: p.imagenAsset,
    );
  }

  RespuestaMassBot _respuesta(
    String texto, {
    List<ProductoMassBot> productos = const [],
    List<TiendaMassBot> tiendas = const [],
    List<CuponMassBot> cupones = const [],
  }) {
    return RespuestaMassBot(
      texto: texto,
      productos: productos,
      tiendas: tiendas,
      cupones: cupones,
      presupuesto: null,
      total: null,
      restante: null,
      consultadoEn: DateTime.now().toIso8601String(),
      simulado: false,
      sinConexion: true,
    );
  }

  Future<List<Producto>> _productos() async {
    if (cargarProductos != null) return cargarProductos!();
    final sesion = CatalogoSesion.instancia.productos;
    if (sesion.isNotEmpty) return sesion;
    try {
      final datos = await FirebaseFirestore.instance
          .collection('productos_mass')
          .get()
          .timeout(_espera);
      if (datos.docs.isNotEmpty) {
        return [for (final d in datos.docs) Producto.fromMap(d.id, d.data())];
      }
    } catch (_) {}
    try {
      return await CatalogoInicialService.productosLocales();
    } catch (_) {
      return const [];
    }
  }

  Future<List<Tienda>> _tiendas() async {
    if (cargarTiendas != null) return cargarTiendas!();
    try {
      final datos = await FirebaseFirestore.instance
          .collection('tiendas_mass')
          .get()
          .timeout(_espera);
      return [for (final d in datos.docs) Tienda.fromMap(d.id, d.data())];
    } catch (_) {
      return const [];
    }
  }

  Future<List<CuponDescuento>> _cupones() async {
    if (cargarCupones != null) return cargarCupones!();
    return CuponDescuento.predeterminados.where((c) => c.activo).toList();
  }

  static String normalizar(String valor) {
    const con = 'áéíóúüñ';
    const sin = 'aeiouun';
    final buffer = StringBuffer();
    for (final c in valor.toLowerCase().split('')) {
      final i = con.indexOf(c);
      buffer.write(i >= 0 ? sin[i] : c);
    }
    return buffer.toString();
  }
}
