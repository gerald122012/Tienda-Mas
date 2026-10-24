# Catálogo comercial de 40 productos

La app abre en Catálogo y lee la colección `productos_mass` de Cloud Firestore.
Los documentos `catalogo_001` a `catalogo_040` identifican productos comerciales de marcas concretas.
Cada registro conserva su stock, disponibilidad, fecha y valoración; se corrigieron nombre, marca, presentación, precio referencial y foto.

## Nombre y empaque

La selección está documentada en `catalogo_marcas/productos_verificados.json`.
Cada producto contiene el nombre comercial, marca, presentación, ID del producto fuente, SKU y enlace a la misma ficha de la que procede la foto.
Coca-Cola corresponde a botella de 500 ml. Field ChokoSoda corresponde a paquete de 6 unidades.
Lay's Clásicas corresponde a bolsa de 140 g: se priorizó el contenido visible en el empaque y el nombre comercial sobre una especificación secundaria inconsistente de la tienda.
Los precios son referenciales para este prototipo; no son una oferta oficial de Tiendas Mass.

## Fotos

Las 40 fotos del empaque están en `assets/productos/marcas/`. Firestore guarda su referencia local y, cuando se utiliza la foto comercial original, también su URL.
La app muestra la imagen completa, sin recortar el empaque, y usa el archivo local mientras carga la URL o si falla la conexión.
El icono de información permite consultar la ficha comercial fuente.
`assets/productos/marcas/FUENTES.md` contiene la procedencia de cada imagen.
Se sustituyeron 25 fotos que tenían franjas o carteles exteriores: cinco por fotografías comerciales limpias y 20 por ediciones de la fotografía original realizadas con la herramienta integrada de imágenes. Estas últimas usan exclusivamente el recurso local para evitar que se vuelva a mostrar la URL antigua con publicidad. El registro de edición está en `catalogo_marcas/ediciones_fotos_limpias.json`.
Las fuentes comerciales son plazaVea y Metro; sus derechos y las marcas pertenecen a sus respectivos titulares. No se presentan como material Creative Commons.
Las fotos genéricas anteriores ya no se usan en los 40 registros ni se incluyen como recursos del catálogo actual.

Firebase Storage sigue pendiente de habilitación. Los enlaces de las imágenes se guardan en Firestore.

Después de cambiar recursos locales, detener la ejecución con `q` y volver a ejecutar `flutter run -d emulator-5554`. La recarga en caliente no incorpora por sí sola todos los recursos nuevos.

## Mantenimiento

- `catalogo_40.json`: datos iniciales de los 40 productos comerciales.
- `catalogo_imagenes.json`: fotos y fuentes.
- `sincronizar_catalogo_marcas.py`: sincroniza solo los campos corregidos, con control de versión y verificación del inventario conservado.
- `cargar_catalogo_firebase.py`: agrega únicamente documentos inexistentes.
- `actualizar_fotos_firebase.py`: actualiza campos de imagen sin sobrescribir una foto personalizada diferente.
- `sincronizar_fotos_limpias.py`: aplica esta corrección a los campos de imagen, con respaldo previo y comprobación de que ningún otro campo cambió.
- `catalogo_marcas/firestore_antes_marcas.json`: respaldo previo a la corrección.

## Verificación

14 pruebas automáticas cubren datos, marcas, presentaciones, recursos locales, compatibilidad de tarjetas y acceso a las fuentes de las fotos.
Se verificó que los 40 registros de Firestore coinciden con el catálogo corregido y conservan su inventario.
