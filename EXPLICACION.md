# Tienda Más — documentación técnica actualizada

Esta copia fue desvinculada de la configuración Firebase anterior.
**NO se ha eliminado ningún proyecto ni dato remoto de Firebase.**

## Módulos existentes

- Conóceme: contenido informativo.
- Catálogo: `productos_mass`.
- Ubícame: `tiendas_mass`.
- Alquila tu Local: `locales_mass`.

## Nuevos módulos propuestos

- Carrito de compras: `carritos` (pendiente de implementación).
- Pedidos: `pedidos` (pendiente de implementación).

## Configurar Firebase del equipo

Sigue el archivo `CONFIGURAR_FIREBASE_NUEVO.md`.

El proyecto incluye `firebase_core` y `cloud_firestore`, que deben conservarse.
No intentes ejecutar Flutter antes de generar `lib/firebase_options.dart`
y `android/app/google-services.json` correspondientes al nuevo proyecto.

Las colecciones Cloud Firestore se crean al escribir el primer documento;
no se importaron documentos de la cuenta del propietario anterior.
Los productos y tiendas de ejemplo que aparecen en el código NO son
una copia verificada de los datos remotos.
