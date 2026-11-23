import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../models/producto.dart';

// Carga los 40 productos de assets/catalogo/catalogo_inicial.json en
// productos_mass. Solo funciona con un administrador de Firebase (reglas).
class CatalogoInicialService {
  static Future<List<Map<String, dynamic>>> _filas() async {
    final texto = await rootBundle.loadString(
      'assets/catalogo/catalogo_inicial.json',
    );
    return (jsonDecode(texto) as List).cast<Map<String, dynamic>>();
  }

  // Respaldo para el cliente mientras Firebase aún no tiene productos.
  static Future<List<Producto>> productosLocales() async {
    final filas = await _filas();
    return [for (final f in filas) Producto.fromMap(f['id'] as String, f)];
  }

  static Future<int> cargar() async {
    final filas = await _filas();
    final coleccion = FirebaseFirestore.instance.collection('productos_mass');
    final existentes = (await coleccion.get()).docs.map((d) => d.id).toSet();

    final lote = FirebaseFirestore.instance.batch();
    var nuevos = 0;
    for (final fila in filas) {
      final id = fila['id'] as String;
      if (existentes.contains(id)) continue;
      final datos = Map<String, dynamic>.from(fila)..remove('id');
      datos['fechaRegistro'] = Timestamp.now();
      lote.set(coleccion.doc(id), datos);
      nuevos++;
    }
    if (nuevos > 0) await lote.commit();
    return nuevos;
  }
}
