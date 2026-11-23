import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final CollectionReference<Map<String, dynamic>> coleccion;

  FirebaseService(String nombre)
    : coleccion = FirebaseFirestore.instance.collection(nombre);

  Future<void> guardar(String id, Map<String, dynamic> datos) {
    if (id.isEmpty) return coleccion.add(datos);
    return coleccion.doc(id).update(datos);
  }

  Future<void> eliminar(String id) => coleccion.doc(id).delete();

  Future<void> restaurar(String id, Map<String, dynamic> datos) {
    return coleccion.doc(id).set(datos);
  }
}
