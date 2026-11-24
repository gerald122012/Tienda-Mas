import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/producto.dart';
import 'package:flutter_application_1/models/respuesta_massbot.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/screens/inicio/inicio_screen.dart';
import 'package:flutter_application_1/screens/massbot/conversacion_massbot.dart';
import 'package:flutter_application_1/screens/massbot/massbot_screen.dart';
import 'package:flutter_application_1/screens/massbot/ventana_massbot.dart';
import 'package:flutter_application_1/screens/massbot/widgets/boton_flotante_massbot.dart';
import 'package:flutter_application_1/screens/massbot/widgets/zona_asistente.dart';
import 'package:flutter_application_1/services/catalogo_visual.dart';
import 'package:flutter_application_1/services/massbot_service.dart';
import 'package:flutter_test/flutter_test.dart';

RespuestaMassBot _respuesta({
  String texto = 'La Leche Light GLORIA está a S/ 4.40 y hay 40 unidades.',
  List<ProductoMassBot>? productos,
  double? presupuesto,
  double? total,
  double? restante,
}) {
  return RespuestaMassBot(
    texto: texto,
    productos:
        productos ??
        const [
          ProductoMassBot(
            id: 'catalogo_019',
            nombre: 'Leche Light GLORIA Lata 390g',
            marca: 'GLORIA',
            categoria: 'lácteos',
            presentaciones: ['Lata 390g'],
            precio: 4.4,
            stock: 40,
            disponible: true,
            imagenAsset: 'assets/productos/marcas/catalogo_019.jpg',
          ),
        ],
    tiendas: const [],
    cupones: const [],
    presupuesto: presupuesto,
    total: total,
    restante: restante,
    consultadoEn: '2026-11-23T15:00:00.000Z',
    simulado: true,
  );
}

MassBotServicio _servicio(RespuestaMassBot respuesta) {
  return MassBotServicio(
    enviarDirecto: (mensaje, historial) async => respuesta,
  );
}

Future<void> _abrir(WidgetTester tester, MassBotServicio servicio) async {
  await tester.pumpWidget(MaterialApp(home: MassBotScreen(servicio: servicio)));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    CatalogoVisual.lecturaRemota = false;
  });

  tearDown(() {
    CatalogoVisual.instancia.limpiar();
    CatalogoVisual.lecturaRemota = true;
  });

  test('la respuesta conserva el precio estructurado', () {
    final respuesta = RespuestaMassBot.fromJson({
      'texto': 'Encontré un producto.',
      'productos': [
        {
          'id': 'catalogo_003',
          'nombre': 'Aceite',
          'marca': 'PRIMOR',
          'precio': 8.5,
          'stock': 40,
          'disponible': true,
          'imagenBase64': 'no-debe-usarse',
        },
      ],
      'simulado': true,
      'consultadoEn': '2026-11-23T15:00:00.000Z',
    });
    expect(respuesta.productos.single.precio, 8.5);
    expect(respuesta.productos.single.imagenAsset, isEmpty);
  });

  testWidgets(
    'Inicio ya no muestra la tarjeta y conserva el icono de persona',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(actions: const [BotonCuentaAppBar(usuario: null)]),
            body: InicioScreen(
              onCambiarPestana: (_) {},
              mostrarAlquiler: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('INGRESAR'), findsNothing);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
      expect(find.text('Pregunta por precios y tu lista'), findsNothing);
      expect(find.text('Compra por categoría'), findsOneWidget);
    },
  );

  testWidgets('una consulta muestra tarjetas y abre el catálogo', (
    tester,
  ) async {
    var catalogo = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MassBotScreen(
          servicio: _servicio(_respuesta()),
          alVerCatalogo: () => catalogo = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Encuentra el mejor precio'));
    await tester.pumpAndSettle();

    expect(find.text('Leche Light GLORIA Lata 390g'), findsOneWidget);
    expect(find.text('S/ 4.40'), findsWidgets);
    expect(find.text('Demostración con datos simulados.'), findsOneWidget);
    await tester.tap(find.text('Ver en catálogo'));
    await tester.pump();
    expect(catalogo, isTrue);
  });

  testWidgets('el presupuesto se muestra desde el total calculado', (
    tester,
  ) async {
    await _abrir(
      tester,
      _servicio(
        _respuesta(
          texto: 'Armé una lista por S/ 20.30.',
          presupuesto: 30,
          total: 20.3,
          restante: 9.7,
          productos: const [
            ProductoMassBot(
              id: 'catalogo_019',
              nombre: 'Leche Light GLORIA Lata 390g',
              marca: 'GLORIA',
              categoria: 'lácteos',
              presentaciones: ['Lata 390g'],
              precio: 4.4,
              stock: 40,
              disponible: true,
              cantidad: 1,
              subtotal: 4.4,
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Tengo S/ 30 para comprar'));
    await tester.pumpAndSettle();

    expect(find.text('Total de la lista'), findsOneWidget);
    expect(find.text('S/ 20.30'), findsOneWidget);
    expect(find.text('S/ 9.70'), findsOneWidget);
  });

  testWidgets('muestra el proceso, el error y el reintento', (tester) async {
    var llamadas = 0;
    final espera = Completer<void>();
    final servicio = MassBotServicio(
      enviarDirecto: (mensaje, historial) async {
        llamadas += 1;
        if (llamadas == 1) {
          await espera.future;
          throw const MassBotException('MassBot no está disponible.');
        }
        return _respuesta();
      },
    );
    await _abrir(tester, servicio);
    await tester.tap(find.text('Consultar promociones'));
    await tester.pump();
    expect(find.text('Consultando'), findsOneWidget);

    espera.complete();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Leche Light GLORIA Lata 390g'), findsOneWidget);
    expect(llamadas, 2);
  });

  testWidgets('cabe en una pantalla pequeña con el teclado abierto', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(viewInsets: const EdgeInsets.only(bottom: 280)),
          child: child!,
        ),
        home: MassBotScreen(servicio: _servicio(_respuesta())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'leche');
    expect(tester.getSize(find.byType(Scaffold)), const Size(320, 640));
    final envio = tester.getRect(find.byTooltip('Enviar'));
    expect(envio.bottom, lessThanOrEqualTo(360), reason: '$envio');
    await tester.tap(find.byTooltip('Enviar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('Leche Light GLORIA Lata 390g', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byTooltip('Enviar'), findsOneWidget);
  });

  testWidgets('la ventana mantiene el compositor sobre el teclado', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final conversacion = ConversacionMassBot();
    addTearDown(conversacion.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            viewInsets: const EdgeInsets.only(bottom: 300),
            viewPadding: const EdgeInsets.only(top: 24, bottom: 20),
          ),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => abrirVentanaMassBot(
                context,
                conversacion: conversacion,
                alVerCatalogo: () {},
              ),
              child: const Text('Abrir asistente'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir asistente'));
    await tester.pumpAndSettle();

    final envio = tester.getRect(find.byTooltip('Enviar'));
    expect(envio.bottom, lessThanOrEqualTo(500), reason: '$envio');
    expect(tester.takeException(), isNull);
  });

  test('cambiar de cuenta o cerrar sesión borra la conversación', () async {
    final conversacion = ConversacionMassBot(servicio: _servicio(_respuesta()));
    addTearDown(conversacion.dispose);
    conversacion.vincular('ana@mass.pe');
    await conversacion.enviar('leche');
    expect(conversacion.tieneMensajes, isTrue);

    conversacion.vincular('ana@mass.pe');
    expect(conversacion.tieneMensajes, isTrue);

    conversacion.vincular('luis@mass.pe');
    expect(conversacion.entradas, isEmpty);

    await conversacion.enviar('aceite');
    conversacion.vincular('');
    expect(conversacion.entradas, isEmpty);
  });

  test('el asistente flotante solo corresponde a Inicio y Productos', () {
    expect(muestraAsistenteMassBot(0), isTrue);
    expect(muestraAsistenteMassBot(1), isTrue);
    expect(muestraAsistenteMassBot(2), isFalse);
    expect(muestraAsistenteMassBot(3), isFalse);
    expect(muestraAsistenteMassBot(4), isFalse);
  });

  testWidgets('la franja del asistente no cubre el último control', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZonaConAsistente(
            asistente: const SizedBox(
              key: Key('asistente'),
              width: 60,
              height: 60,
            ),
            contenido: ListView(
              children: [
                const SizedBox(height: 1400),
                TextButton(onPressed: () {}, child: const Text('Delivery')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Delivery'), 300);
    await tester.pumpAndSettle();

    final control = tester.getRect(find.text('Delivery'));
    final asistente = tester.getRect(find.byKey(const Key('asistente')));
    expect(control.overlaps(asistente), isFalse);
    expect(control.bottom, lessThanOrEqualTo(asistente.top));
  });

  testWidgets('hay un solo botón, se oculta al abrir y vuelve al minimizar', (
    tester,
  ) async {
    final conversacion = ConversacionMassBot();
    addTearDown(conversacion.dispose);
    await tester.pumpWidget(
      MaterialApp(home: _AnfitrionFlotante(conversacion: conversacion)),
    );
    await tester.pump();

    expect(find.byType(BotonFlotanteMassBot), findsOneWidget);
    expect(find.text('¿Te ayudo a comprar?'), findsNothing);

    await tester.tap(find.text('Ir a sensores'));
    await tester.pump();
    expect(find.byType(BotonFlotanteMassBot), findsNothing);

    await tester.tap(find.text('Ir a productos'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(BotonFlotanteMassBot), findsOneWidget);

    await tester.tap(find.byType(BotonFlotanteMassBot));
    await tester.pumpAndSettle();
    expect(find.byType(BotonFlotanteMassBot), findsNothing);
    expect(find.text('¡Hola! ¿Qué compramos hoy?'), findsOneWidget);
    expect(find.text('Tu asistente de compras'), findsOneWidget);

    await tester.tap(find.byTooltip('Minimizar'));
    await tester.pumpAndSettle();
    expect(find.byType(BotonFlotanteMassBot), findsOneWidget);
    expect(find.text('¿Te ayudo a comprar?'), findsNothing);
  });

  testWidgets('minimizar conserva el historial y nueva conversación lo borra', (
    tester,
  ) async {
    var llamadas = 0;
    final conversacion = ConversacionMassBot(
      servicio: MassBotServicio(
        enviarDirecto: (mensaje, historial) async {
          llamadas += 1;
          return _respuesta();
        },
      ),
    );
    addTearDown(conversacion.dispose);
    await tester.pumpWidget(
      MaterialApp(home: _ConversacionVisible(conversacion: conversacion)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Encuentra el mejor precio'));
    await tester.pumpAndSettle();
    expect(find.text('Leche Light GLORIA Lata 390g'), findsOneWidget);
    expect(llamadas, 1);

    await tester.tap(find.byTooltip('Minimizar'));
    await tester.pumpAndSettle();
    expect(find.text('Leche Light GLORIA Lata 390g'), findsNothing);

    await tester.tap(find.text('Reabrir'));
    await tester.pumpAndSettle();
    expect(find.text('Leche Light GLORIA Lata 390g'), findsOneWidget);
    expect(llamadas, 1);

    await tester.tap(find.byTooltip('Nueva conversación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Leche Light GLORIA Lata 390g'), findsOneWidget);

    await tester.tap(find.byTooltip('Nueva conversación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();
    expect(find.text('Leche Light GLORIA Lata 390g'), findsNothing);
    expect(find.text('¡Hola! ¿Qué compramos hoy?'), findsOneWidget);
    expect(llamadas, 1);
  });

  testWidgets('usa la imagen Base64 del catálogo y un marcador si falta', (
    tester,
  ) async {
    const png =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
    CatalogoVisual.instancia.recordar([
      Producto(
        id: 'con-foto',
        nombre: 'Leche con foto',
        descripcion: '',
        marca: 'GLORIA',
        precio: 4.4,
        stock: 10,
        categoria: 'lácteos',
        disponible: true,
        fechaRegistro: DateTime.utc(2026),
        presentaciones: const ['Lata 390g'],
        valoracion: 0,
        imagenBase64: png,
      ),
    ]);
    await _abrir(
      tester,
      _servicio(
        _respuesta(
          productos: const [
            ProductoMassBot(
              id: 'con-foto',
              nombre: 'Leche con foto',
              marca: 'GLORIA',
              categoria: 'lácteos',
              presentaciones: ['Lata 390g'],
              precio: 4.4,
              stock: 10,
              disponible: true,
            ),
            ProductoMassBot(
              id: 'sin-foto',
              nombre: 'Aceite sin foto',
              marca: 'PRIMOR',
              categoria: 'abarrotes',
              presentaciones: ['1 L'],
              precio: 8.5,
              stock: 4,
              disponible: true,
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Encuentra el mejor precio'));
    await tester.pumpAndSettle();

    final imagenes = tester.widgetList<Image>(find.byType(Image));
    expect(imagenes.any((imagen) => imagen.image is MemoryImage), isTrue);
    expect(find.byIcon(Icons.shopping_bag_outlined), findsWidgets);
    expect(find.text('Aceite sin foto'), findsOneWidget);
  });
}

class _ConversacionVisible extends StatefulWidget {
  final ConversacionMassBot conversacion;

  const _ConversacionVisible({required this.conversacion});

  @override
  State<_ConversacionVisible> createState() => _ConversacionVisibleState();
}

class _ConversacionVisibleState extends State<_ConversacionVisible> {
  var _abierta = true;

  @override
  Widget build(BuildContext context) {
    if (!_abierta) {
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => setState(() => _abierta = true),
            child: const Text('Reabrir'),
          ),
        ),
      );
    }
    return MassBotScreen(
      conversacion: widget.conversacion,
      alMinimizar: () => setState(() => _abierta = false),
      alCerrar: () => setState(() => _abierta = false),
    );
  }
}

class _AnfitrionFlotante extends StatefulWidget {
  final ConversacionMassBot conversacion;

  const _AnfitrionFlotante({required this.conversacion});

  @override
  State<_AnfitrionFlotante> createState() => _AnfitrionFlotanteState();
}

class _AnfitrionFlotanteState extends State<_AnfitrionFlotante> {
  var _indice = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.conversacion,
      builder: (context, _) {
        final visible =
            muestraAsistenteMassBot(_indice) && !widget.conversacion.abierta;
        return Scaffold(
          body: ZonaConAsistente(
            contenido: Column(
              children: [
                TextButton(
                  onPressed: () => setState(() => _indice = 1),
                  child: const Text('Ir a productos'),
                ),
                TextButton(
                  onPressed: () => setState(() => _indice = 4),
                  child: const Text('Ir a sensores'),
                ),
              ],
            ),
            asistente: visible
                ? BotonFlotanteMassBot(
                    conversacion: widget.conversacion,
                    alAbrir: () => abrirVentanaMassBot(
                      context,
                      conversacion: widget.conversacion,
                      alVerCatalogo: () {},
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
