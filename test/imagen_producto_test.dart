import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/producto.dart';
import 'package:flutter_application_1/widgets/producto_catalogo_card.dart';
import 'package:flutter_test/flutter_test.dart';

const _pngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

Producto _producto({
  String imagenBase64 = '',
  String imagenUrl = '',
  String imagenAsset = '',
  double precio = 20,
}) {
  return Producto(
    nombre: 'Arroz Extra',
    descripcion: 'Arroz Extra',
    marca: 'COSTEÑO',
    precio: precio,
    stock: 10,
    categoria: 'abarrotes',
    disponible: true,
    fechaRegistro: DateTime(2026, 1, 1),
    presentaciones: const ['Bolsa 5Kg'],
    valoracion: 5,
    imagenBase64: imagenBase64,
    imagenUrl: imagenUrl,
    imagenAsset: imagenAsset,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final pngBytes = base64Decode(_pngBase64);

  test('un producto antiguo sin imagenBase64 sigue leyéndose', () {
    final recuperado = Producto.fromMap('catalogo_001', {
      'nombre': 'Arroz',
      'precio': 20.9,
      'stock': 30,
      'imagenUrl': 'https://ejemplo.test/arroz.jpg',
      'imagenAsset': 'assets/productos/marcas/catalogo_001.jpg',
    });

    expect(recuperado.imagenBase64, isEmpty);
    expect(recuperado.imagenUrl, 'https://ejemplo.test/arroz.jpg');
    expect(recuperado.imagenAsset, 'assets/productos/marcas/catalogo_001.jpg');
    expect(recuperado.nombre, 'Arroz');
  });

  test('serializa y deserializa imagenBase64 sin prefijo data:image', () {
    final original = _producto(
      imagenBase64: 'data:image/png;base64,$_pngBase64',
      imagenUrl: 'https://ejemplo.test/arroz.jpg',
    );

    final mapa = original.toMap();
    expect(mapa['imagenBase64'], _pngBase64);
    expect((mapa['imagenBase64'] as String).startsWith('data:image'), isFalse);
    expect(mapa['imagenUrl'], 'https://ejemplo.test/arroz.jpg');

    final copia = Producto.fromMap('', mapa);
    expect(copia.id, isEmpty);
    expect(copia.imagenBase64, _pngBase64);
    expect(copia.imagenUrl, original.imagenUrl);
    expect(copia.imagenAsset, original.imagenAsset);
  });

  test('codifica y decodifica una imagen PNG válida', () async {
    expect(esPng(pngBytes), isTrue);
    expect(decodificarImagenProducto(_pngBase64), pngBytes);
    expect(await validarImagenProducto(pngBytes), isNull);
    expect(base64Encode(pngBytes), _pngBase64);
  });

  test('rechaza una imagen cuya resolución supera 600 × 600', () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 601, 8), Paint());
    final imagen = await recorder.endRecording().toImage(601, 8);
    final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
    imagen.dispose();

    final bytes = datos!.buffer.asUint8List();
    expect(bytes.length <= kMaxBytesImagenProducto, isTrue);
    expect(
      await validarImagenProducto(bytes),
      contains('supera el máximo de 600 × 600'),
    );
  });

  test(
    'rechaza una imagen que supera 150 KB y conserva el mensaje anterior',
    () async {
      final grande = Uint8List(kMaxBytesImagenProducto + 1);
      grande[0] = 0xFF;
      grande[1] = 0xD8;
      grande[2] = 0xFF;

      final error = await validarImagenProducto(grande);

      expect(error, contains('150 KB'));
      expect(error, contains('Se conservó la imagen anterior'));
      expect(
        imagenBase64ParaGuardar(anterior: _pngBase64, nueva: null),
        _pngBase64,
      );
    },
  );

  test(
    'rechaza contenido que no es JPG ni PNG y una cadena Base64 inválida',
    () async {
      expect(
        await validarImagenProducto(
          Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]),
        ),
        contains('JPG o PNG'),
      );
      expect(decodificarImagenProducto('%%%no-es-base64%%%'), isNull);
      expect(decodificarImagenProducto(''), isNull);

      final cabeceraJpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0x00, 0x11]);
      expect(
        await validarImagenProducto(cabeceraJpeg),
        contains('No se pudo leer la imagen'),
      );
    },
  );

  test('conserva, reemplaza, quita y cancela la selección', () {
    expect(
      imagenBase64ParaGuardar(anterior: _pngBase64, nueva: null, quitar: false),
      _pngBase64,
    );

    final reemplazo = Uint8List.fromList(pngBytes);
    expect(
      imagenBase64ParaGuardar(anterior: 'anterior', nueva: reemplazo),
      _pngBase64,
    );

    expect(
      imagenBase64ParaGuardar(anterior: _pngBase64, nueva: null, quitar: true),
      isEmpty,
    );

    const seleccionCancelada = null;
    expect(
      imagenBase64ParaGuardar(
        anterior: _pngBase64,
        nueva: seleccionCancelada,
        quitar: false,
      ),
      _pngBase64,
    );
  });

  test('la prioridad es Base64, luego URL, asset y marcador vacío', () {
    expect(
      fuenteDeImagenProducto(
        _producto(
          imagenBase64: _pngBase64,
          imagenUrl: 'https://ejemplo.test/a.jpg',
        ),
      ),
      FuenteDeImagen.base64,
    );
    expect(
      fuenteDeImagenProducto(
        _producto(
          imagenBase64: '%%%',
          imagenUrl: 'https://ejemplo.test/a.jpg',
          imagenAsset: 'assets/productos/marcas/catalogo_001.jpg',
        ),
      ),
      FuenteDeImagen.url,
    );
    expect(
      fuenteDeImagenProducto(
        _producto(imagenAsset: 'assets/productos/marcas/catalogo_001.jpg'),
      ),
      FuenteDeImagen.asset,
    );
    expect(fuenteDeImagenProducto(_producto()), FuenteDeImagen.ninguna);
  });

  test('editar otro atributo no borra la imagen codificada', () {
    final original = _producto(imagenBase64: _pngBase64, precio: 20);
    final editado = Producto(
      id: original.id,
      nombre: original.nombre,
      descripcion: original.descripcion,
      marca: original.marca,
      precio: 21.5,
      stock: original.stock,
      categoria: original.categoria,
      disponible: original.disponible,
      fechaRegistro: original.fechaRegistro,
      presentaciones: original.presentaciones,
      valoracion: original.valoracion,
      imagenUrl: original.imagenUrl,
      imagenAsset: original.imagenAsset,
      imagenBase64: imagenBase64ParaGuardar(
        anterior: original.imagenBase64,
        nueva: null,
      ),
    );

    expect(editado.precio, 21.5);
    expect(editado.imagenBase64, original.imagenBase64);
    expect(editado.toMap()['imagenBase64'], _pngBase64);
    expect(editado.toMap()['precio'], 21.5);
  });

  testWidgets(
    'la tarjeta muestra la imagen Base64 y el respaldo si es inválida',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductoCatalogoCard(
              producto: _producto(imagenBase64: _pngBase64),
              onAgregar: () {},
            ),
          ),
        ),
      );

      final imagen = tester.widget<Image>(find.byType(Image));
      expect(imagen.image, isA<MemoryImage>());
      expect((imagen.image as MemoryImage).bytes, pngBytes);
      expect(find.text('Sin imagen'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductoCatalogoCard(
              producto: _producto(imagenBase64: '%%%'),
              onAgregar: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Sin imagen'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    },
  );
}
