import 'package:cloud_firestore/cloud_firestore.dart';

// Clase reutilizada por los 3 módulos para leer y escribir en Cloud Firestore.
class FirebaseService {
  final CollectionReference<Map<String, dynamic>> coleccion;

  FirebaseService(String nombre)
    : coleccion = FirebaseFirestore.instance.collection(nombre);

  // Si el id está vacío se crea un documento nuevo (add genera el id automático).
  // Si tiene id se actualiza el documento existente.
  Future<void> guardar(String id, Map<String, dynamic> datos) {
    if (id.isEmpty) return coleccion.add(datos);
    return coleccion.doc(id).update(datos);
  }

  Future<void> eliminar(String id) => coleccion.doc(id).delete();

  // Vuelve a crear un documento eliminado con su mismo id (para "Deshacer").
  Future<void> restaurar(String id, Map<String, dynamic> datos) {
    return coleccion.doc(id).set(datos);
  }
}
