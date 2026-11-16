# Guía de migración a un Firebase único — Tienda Más

## Qué se retiró

Se quitaron únicamente dos archivos locales que vinculaban la aplicación
al Firebase anterior:

- `lib/firebase_options.dart`
- `android/app/google-services.json`

No se borraron datos del backend antiguo y no se modificó el proyecto remoto.
Las dependencias `firebase_core` y `cloud_firestore` permanecen intactas.

**IMPORTANTE: La app no compilará hasta configurar el Firebase nuevo.**

## Paso 1. Crear un proyecto Firebase para todo el equipo

1. Ingresar a https://console.firebase.google.com/ con la cuenta que administrará el equipo.
2. Crear un proyecto nuevo, por ejemplo `tienda-mas-equipo` (el ID único puede variar).
3. Crear Cloud Firestore con ubicación elegida conscientemente y reglas de seguridad iniciales en **modo producción**.
4. NO usar el antiguo proyecto del desarrollador anterior.

## Paso 2. Instalar herramientas en la computadora

Con Flutter y Dart ya configurados, instalar Firebase CLI y FlutterFire CLI
siguiendo https://firebase.google.com/docs/flutter/setup

- Firebase CLI (requiere Node.js): `npm install -g firebase-tools`
- Autenticarse: `firebase login`
- FlutterFire CLI: `dart pub global activate flutterfire_cli`

## Paso 3. Generar el nuevo enlace con Firebase

Desde la carpeta raíz del proyecto (donde está `pubspec.yaml`):

```powershell
flutter pub get
flutterfire configure
```

Elegir **exclusivamente el nuevo proyecto Firebase del equipo**, y registrar
Android (y otras plataformas si se van a utilizar). Mantener el package name
Android ya presente en el proyecto: `com.example.flutter_application_1`;
si se decide cambiarlo, hay que hacerlo de forma coordinada.

Verificar que se generen:

- `lib/firebase_options.dart`
- `android/app/google-services.json`

Comprobar que ambos archivos apunten al **ID del nuevo proyecto** antes de ejecutar.

## Paso 4. Revisar reglas y roles

Cloud Firestore creado en modo producción normalmente deniega lecturas y escrituras
hasta establecer reglas apropiadas. Eso es intencional.

Antes de probar CRUD, definir autenticación, propietarios de datos, roles de
administración e identificar qué pantallas deben escribir o leer qué colecciones.
No habilitar reglas públicas sin restricciones.

## Paso 5. Colecciones del código actual

- `productos_mass` (modelo `lib/models/producto.dart`)
- `tiendas_mass` (modelo `lib/models/tienda.dart`)
- `locales_mass` (modelo `lib/models/local_comercial.dart`)

Al crear un documento, Firestore creará automáticamente la colección si no existe.
No se ha migrado información del Firebase anterior. Hay datos de ejemplo en
el código; NO interpretarlos como datos de Firestore.

## Paso 6. Nuevo carrito (pendiente)

Planificar documentos por usuario:

- `carritos/{uid}/items/{itemId}`
- `pedidos/{pedidoId}`

La app todavía no tiene autenticación de usuarios. Debe agregarse para permitir
carritos individuales seguros; también se requieren reglas de Firestore.
El precio final y el stock deben validarse al confirmar el pedido, no confiar
en el total calculado por el cliente.

## Paso 7. Compartir sin compartir contraseñas

Firebase Console > Configuración del proyecto > Usuarios y permisos:
invitar a cada integrante por su correo y asignar el rol mínimo necesario.
Compartir el repositorio Flutter con las nuevas configuraciones generadas;
no enviar contraseñas, claves privadas de cuentas de servicio ni archivos secretos.

## Notas

- Scripts en `tools/` interactúan con Firestore: no ejecutarlos antes de
  revisar a qué nuevo proyecto apuntan y su efecto.
- No se ha verificado compilación ni conexión remota en esta preparación.
- Documentación: https://firebase.google.com/docs/flutter/setup
