# Explicación del proyecto – Evaluación Parcial DAM

## Estructura (arquitectura modular)

```
lib/
├── main.dart                  → inicia Firebase y la app
├── firebase_options.dart      → claves del proyecto Firebase "FitBookTravel"
├── models/                    → una clase por módulo (datos + toMap/fromMap)
│   ├── producto.dart          (FitZone)
│   ├── libro.dart             (BookPoint)
│   └── reserva.dart           (TravelGo, incluye calcularPrecioFinal)
├── services/
│   └── firebase_service.dart  → guardar (crear/editar), eliminar y restaurar en Firestore
├── utils/
│   ├── validaciones.dart      → funciones validator de los formularios
│   └── utilidades.dart        → formato de fecha, SnackBar, diálogo de confirmación
├── widgets/                   → piezas reutilizadas en los 3 formularios
│   ├── campo_fecha.dart       (DatePicker)
│   ├── campo_lista.dart       (agregar tallas / etiquetas como chips)
│   └── botones_acciones.dart  (botones duplicar / editar / eliminar de cada tarjeta)
└── screens/
    ├── home_screen.dart       → BottomNavigationBar con los 3 módulos
    ├── fitzone/   productos_screen.dart (lista) + producto_form_screen.dart (formulario)
    ├── bookpoint/ libros_screen.dart    (lista) + libro_form_screen.dart
    └── travelgo/  reservas_screen.dart  (lista) + reserva_form_screen.dart
```

## Conexión con Firebase (solo Android)
1. En la consola de Firebase se creó el proyecto **FitBookTravel** y la base **Cloud Firestore** en modo de prueba.
2. Se registró la app Android con el paquete `com.example.flutter_application_1`
   (está en `android/app/build.gradle.kts` → `applicationId`).
3. Se descargó `google-services.json` y se colocó en `android/app/`.
4. En Gradle se activó el plugin `com.google.gms.google-services`
   (`android/settings.gradle.kts` y `android/app/build.gradle.kts`), que lee ese archivo.
5. En `pubspec.yaml` se agregaron `firebase_core` y `cloud_firestore`.
6. En `main.dart` se inicia Firebase antes de abrir la app:
   `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);`
   (`firebase_options.dart` tiene los mismos datos del `google-services.json`).

## Cómo funciona el CRUD con Cloud Firestore
Base de datos: proyecto **FitBookTravel** (`fitbooktravel-294a5`), colecciones `productos`, `libros` y `reservas`.

| Operación | Código | Dónde |
|---|---|---|
| Crear | `coleccion.add(datos)` → Firestore genera el **id automático** | `firebase_service.dart` |
| Leer | `StreamBuilder` escuchando `coleccion.snapshots()` (se actualiza en tiempo real) | pantallas de lista |
| Editar | `coleccion.doc(id).update(datos)` | `firebase_service.dart` |
| Eliminar | `coleccion.doc(id).delete()` tras `confirmarEliminar()` | pantallas de lista |

Cada documento se convierte en objeto con `Modelo.fromMap(doc.id, doc.data())` y para guardar se usa `modelo.toMap()`.
Las fechas (`DateTime`) se guardan como `Timestamp.fromDate(fecha)` y se leen con `(dato as Timestamp).toDate()`.
Las reservas se leen con `orderBy('fechaViaje')` para mostrarlas ordenadas.

## Tipos de datos usados
`String` (nombre, categoría), `int` (stock, cantidad), `double` (precio, valoración),
`bool` (disponible, incluyeSeguro), `DateTime` (fechas), `List<String>` (tallas, etiquetas, servicios).

## Validaciones (como en la Guía N° 8: `GlobalKey<FormState>` + `validator`)
- `obligatorio`, `minimoCaracteres` (nombre, título y autor ≥ 3), `mayorACero` (precios),
  `enteroMinimo` (stock ≥ 0, personas ≥ 1), `numeroEnRango` (valoración 0–5, descuento 0–100),
  `documentoValido` (RegExp `^\d{8}$`), `fechaNoFutura`, `puedeCambiarEstado`.
- Las validaciones que no son de un TextField (lista vacía, fechas, precio final) se revisan
  en `_guardar()` y muestran un SnackBar.
- BookPoint: si la cantidad es 0 se guarda `disponible = false` (y el getter `estaDisponible` lo refuerza).
- TravelGo: una reserva `cancelado` no puede pasar a `confirmado` (en el formulario y en el cambio rápido de la lista).

## Precio final (TravelGo)
```
total = precioBase × personas
total = total − total × descuento / 100
si incluye seguro: total = total + 50 × personas
```
Se recalcula en vivo con `setState` cada vez que cambia un campo.

## Funcionalidades extra
1. **Deshacer eliminación**: después de eliminar aparece un SnackBar con el botón *DESHACER* durante 5 s.
   Antes de borrar se guarda el objeto; si se pulsa *DESHACER* se vuelve a crear con el mismo id
   (`coleccion.doc(id).set(datos)` en `restaurar()`).
2. **Duplicar registro**: el botón 📋 abre el formulario con los datos copiados pero sin id
   (`Producto.fromMap('', producto.toMap())`), así al guardar se crea un registro nuevo. Útil para
   productos de varias tallas/colores, libros de una misma saga o reservas repetidas de un cliente.

## Detalles técnicos (por si preguntan)
- **`heroTag` en los FloatingActionButton**: los 3 módulos están en un `IndexedStack`, así que existen
  3 botones al mismo tiempo. Si comparten el tag por defecto, la animación al abrir el formulario falla
  y el Navigator queda bloqueado (error `!_debugLocked`). Por eso cada uno tiene su propio `heroTag`.
- **`_guardando`** en los formularios: mientras se guarda, el botón se desactiva y muestra
  "Guardando...". Así se evita guardar el mismo registro varias veces si se toca el botón repetidas veces.
- **Botón Guardar fijo abajo** (`bottomNavigationBar` del formulario) y **`Scrollbar`** visible para
  desplazarse; en `main.dart` el `scrollBehavior` permite arrastrar con mouse o touchpad.
