import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/models/cupon.dart';
import 'package:flutter_application_1/models/producto.dart';
import 'package:flutter_application_1/models/tienda.dart';
import 'package:flutter_application_1/screens/carrito/carrito_screen.dart';
import 'package:flutter_application_1/screens/delivery/delivery_mapa_screen.dart';
import 'package:flutter_application_1/screens/massbot/widgets/boton_flotante_massbot.dart';
import 'package:flutter_application_1/screens/ubicame/tarjeta_tienda_cliente.dart';
import 'package:flutter_application_1/screens/ubicame/tiendas_screen.dart';
import 'package:flutter_application_1/services/carrito_service.dart';
import 'package:flutter_application_1/services/consulta_tiendas.dart';
import 'package:flutter_application_1/services/control_solicitudes_ruta.dart';
import 'package:flutter_application_1/services/formato_recorrido.dart';
import 'package:flutter_application_1/services/lectura_ubicacion.dart';
import 'package:flutter_application_1/services/routing_service.dart';
import 'package:flutter_application_1/tema/tema_mass.dart';
import 'package:flutter_application_1/widgets/navegacion_inferior_mass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(CarritoService.instance.vaciar);

  final png = Uint8List.fromList(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    ),
  );

  group('Consulta de establecimientos', () {
    test('busca por nombre, distrito y dirección sin distinguir acentos', () {
      final tiendas = [
        _sede(id: '1', nombre: 'Mass José', direccion: 'Avenida Larco 123'),
        _sede(
          id: '2',
          nombre: 'Mass Arequipa',
          ciudad: 'Arequipa',
          distrito: 'Cayma',
          direccion: 'Calle Mercaderes',
        ),
      ];
      expect(
        filtrarTiendas(tiendas: tiendas, consulta: 'jose', ciudad: 'Todas'),
        hasLength(1),
      );
      expect(
        filtrarTiendas(tiendas: tiendas, consulta: 'larco', ciudad: 'Todas').single.nombre,
        'Mass José',
      );
      expect(
        filtrarTiendas(tiendas: tiendas, consulta: 'cayma', ciudad: 'Todas').single.ciudad,
        'Arequipa',
      );
    });

    test('el filtro y el conteo usan solo las ciudades registradas', () {
      final tiendas = [
        _sede(ciudad: 'Lima'),
        _sede(id: '2', ciudad: 'Arequipa', nombre: 'Mass Arequipa'),
      ];
      expect(ciudadesDe(tiendas), ['Arequipa', 'Lima']);
      expect(ciudadesDe(tiendas), isNot(contains('Cusco')));
      final lima = filtrarTiendas(tiendas: tiendas, consulta: '', ciudad: 'Lima');
      expect(lima, hasLength(1));
      expect(filtrarTiendas(tiendas: tiendas, consulta: 'zzz', ciudad: 'Todas'), isEmpty);
    });

    test('ordena por línea recta y deja al final las tiendas sin coordenadas', () {
      const origen = LatLng(-12.0, -77.0);
      final lejos = _sede(id: 'lejos', nombre: 'Lejos', lat: -13.5, lng: -76.0);
      final cerca = _sede(id: 'cerca', nombre: 'Cerca', lat: -12.01, lng: -77.01);
      final sinPunto = _sede(id: 'sin', nombre: 'Sin punto', lat: null, lng: null);
      final orden = ordenarTiendas([lejos, sinPunto, cerca], origen);
      expect(orden.map((tienda) => tienda.nombre), ['Cerca', 'Lejos', 'Sin punto']);
      final texto = textoDistanciaAproximada(
        distanciaLineaRectaMetros(origen, const LatLng(-12.01, -77.01)),
      );
      expect(texto, contains('en línea recta'));
      expect(texto, isNot(contains('carretera')));
    });

    test('rechaza coordenadas ausentes o fuera de rango', () {
      expect(coordenadasValidas(-12.12, -77.03), isTrue);
      expect(coordenadasValidas(null, -77), isFalse);
      expect(coordenadasValidas(120, 10), isFalse);
      expect(coordenadasValidas(double.nan, 0), isFalse);
    });

    test('no inventa un horario cuando el documento no lo trae', () {
      final tienda = Tienda.fromMap('abc', {
        'nombre': 'Mass Centro',
        'ciudad': 'Lima',
        'distrito': 'Cercado',
        'direccion': 'Jr. Unión',
      });
      expect(tienda.horario, isEmpty);
      expect(tienda.nombre, 'Mass Centro');
    });

    test('una ciudad registrada se conserva y una vacía no se muestra como Lima', () {
      final registrada = Tienda.fromMap('abc', {
        'nombre': 'Otra',
        'ciudad': 'Madrid',
      });
      expect(registrada.ciudad, 'Madrid');
      final conocida = Tienda.fromMap('abc', {
        'nombre': 'Mass',
        'ciudad': 'Lima',
      });
      expect(conocida.ciudad, 'Lima');
      final vacia = Tienda.fromMap('abc', {'nombre': 'Sin dato', 'ciudad': '  '});
      expect(vacia.ciudad, 'Ciudad no disponible');
      expect(vacia.ciudad, isNot('Lima'));
    });
  });

  group('Rutas', () {
    test('ignora una solicitud duplicada y una respuesta obsoleta', () async {
      final control = ControlSolicitudesRuta();
      final espera = Completer<int>();
      final primera = control.ejecutar(() => espera.future);
      final duplicada = await control.ejecutar(() => Future.value(2));
      expect(duplicada.ignorada, isTrue);
      control.invalidar();
      espera.complete(1);
      expect((await primera).ignorada, isTrue);

      final reemplazo = Completer<int>();
      final antigua = control.ejecutar(() => reemplazo.future);
      final nueva = control.ejecutar(() => Future.value(7), reemplazar: true);
      reemplazo.complete(9);
      expect((await antigua).ignorada, isTrue);
      expect((await nueva).valor, 7);
    });

    test('formatea metros, kilómetros y horas sin presentarlos como entrega', () {
      expect(textoDistanciaRecorrido(850), '850 m');
      expect(textoDistanciaRecorrido(1500), '1.5 km');
      expect(textoDistanciaRecorrido(12000), '12 km');
      expect(textoDuracionEstimada(5400), '1 h 30 min');
      final resumen = resumenRutaParaCarrito(
        nombreDestino: 'Mass Larco',
        modo: ModoRuta.carro,
        ruta: const ResultadoRuta(
          distanciaMetros: 1800,
          duracionSegundos: 600,
          puntos: [LatLng(0, 0), LatLng(1, 1)],
        ),
      );
      expect(resumen, contains('Mass Larco'));
      expect(resumen, contains('1.8 km'));
      expect(resumen, isNot(contains('S/')));
      expect(resumen, isNot(contains('Tarifa')));
    });

    test('el mensaje para compartir no incluye una tarifa', () {
      const origen = LatLng(-12.065, -75.210);
      const destino = LatLng(-12.068, -75.205);
      final mensaje = RoutingService.construirMensajeRuta(
        nombreDestino: 'Tienda Mass Centro',
        origen: origen,
        destino: destino,
        modo: ModoRuta.carro,
        ruta: const ResultadoRuta(
          distanciaMetros: 1500,
          duracionSegundos: 300,
          puntos: [origen, destino],
        ),
        aclaracion: 'Destino de ejemplo. No es un establecimiento registrado.',
      );
      expect(mensaje, contains('1.50 km'));
      expect(mensaje, contains('https://www.google.com/maps/dir/'));
      expect(mensaje, contains('No es un establecimiento registrado.'));
      expect(mensaje, isNot(contains('Tarifa')));
    });
  });

  group('Ubícame', () {
    testWidgets('lista establecimientos, busca y conserva el filtro al volver', (tester) async {
      _vista(tester, const Size(390, 844));
      final tiendas = [
        _sede(nombre: 'Mass Larco', direccion: 'Avenida Larco 123'),
        _sede(
          id: 'aqp',
          nombre: 'Mass Arequipa',
          ciudad: 'Arequipa',
          distrito: 'Cayma',
          direccion: 'Calle Mercaderes',
          horario: '',
        ),
      ];
      var lecturas = 0;
      var ubicaciones = 0;
      await tester.pumpWidget(
        _app(
          TiendasScreen(
            lectura: () {
              lecturas++;
              return Stream.value(tiendas);
            },
            leerUbicacion: () async {
              ubicaciones++;
              return const LecturaUbicacion(
                SituacionUbicacion.concedida,
                punto: LatLng(-12.12, -77.03),
              );
            },
            pantallaRuta: (tienda) => DeliveryMapaScreen(
              mostrarMapa: false,
              nombreDestinoInicial: tienda.nombre,
              detalleDestinoInicial: '${tienda.distrito} · ${tienda.ciudad}',
              destinoInicial: LatLng(tienda.latitud!, tienda.longitud!),
              destinoDeTienda: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(ubicaciones, 0);
      expect(find.text('Encuentra tu Mass'), findsOneWidget);
      expect(find.text('2 tiendas'), findsOneWidget);
      expect(find.text('Mass Larco'), findsOneWidget);
      expect(find.text('9:00 a 21:00'), findsOneWidget);
      expect(find.text('Abierto ahora'), findsNothing);
      expect(find.text('7:00 AM - 10:00 PM'), findsNothing);
      expect(find.byType(BotonFlotanteMassBot), findsNothing);
      expect(lecturas, 1);

      await tester.enterText(find.byKey(const Key('busqueda-tiendas')), 'Larco');
      await tester.pumpAndSettle();
      expect(find.text('Mass Larco'), findsOneWidget);
      expect(find.text('Mass Arequipa'), findsNothing);
      expect(find.text('1 tienda'), findsOneWidget);
      expect(lecturas, 1);

      await tester.tap(find.byTooltip('Limpiar búsqueda'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ciudad-Arequipa')));
      await tester.pumpAndSettle();
      expect(find.text('Mass Arequipa'), findsOneWidget);
      expect(find.text('Mass Larco'), findsNothing);

      await tester.tap(find.byKey(const Key('ruta-aqp')));
      await tester.pumpAndSettle();
      expect(find.text('Delivery y rutas'), findsOneWidget);
      expect(find.text('Mass Arequipa'), findsWidgets);
      expect(find.text('Establecimiento'), findsOneWidget);
      expect(find.byType(BotonFlotanteMassBot), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Mass Larco'), findsNothing);
      expect(find.text('Mass Arequipa'), findsOneWidget);
    });

    testWidgets('abre el selector cuando hay muchas ciudades', (tester) async {
      _vista(tester, const Size(390, 844));
      const ciudades = ['Lima', 'Arequipa', 'Cusco', 'Piura', 'Ica'];
      await tester.pumpWidget(
        _app(
          TiendasScreen(
            lectura: () => Stream.value([
              for (final ciudad in ciudades)
                _sede(id: ciudad, nombre: 'Mass $ciudad', ciudad: ciudad),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('5 tiendas'), findsOneWidget);
      await tester.tap(find.byKey(const Key('selector-ciudad')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ciudad-Cusco')));
      await tester.pumpAndSettle();
      expect(find.text('Mass Cusco'), findsOneWidget);
      expect(find.text('Mass Lima'), findsNothing);
      expect(find.text('1 tienda'), findsOneWidget);
    });

    testWidgets('distingue vacío, búsqueda sin resultados y error', (tester) async {
      _vista(tester, const Size(390, 844));
      await tester.pumpWidget(
        _app(
          TiendasScreen(
            key: UniqueKey(),
            lectura: () => Stream.value(const []),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aún no hay tiendas registradas'), findsOneWidget);
      expect(find.text('No pudimos consultar las tiendas'), findsNothing);

      await tester.pumpWidget(
        _app(
          TiendasScreen(
            key: UniqueKey(),
            lectura: () => Stream.value([_sede(nombre: 'Mass Larco')]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('busqueda-tiendas')), 'no existe');
      await tester.pumpAndSettle();
      expect(find.text('Ninguna tienda coincide con tu búsqueda'), findsOneWidget);
      expect(find.text('Aún no hay tiendas registradas'), findsNothing);

      var veces = 0;
      await tester.pumpWidget(
        _app(
          TiendasScreen(
            key: UniqueKey(),
            lectura: () {
              veces++;
              if (veces == 1) return Stream<List<Tienda>>.error(StateError('fallo'));
              return Stream.value([_sede()]);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No pudimos consultar las tiendas'), findsOneWidget);
      expect(find.text('Aún no hay tiendas registradas'), findsNothing);
      expect(find.textContaining('StateError'), findsNothing);
      expect(find.textContaining('fallo'), findsNothing);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Mass Larco'), findsOneWidget);
    });

    testWidgets('informa coordenadas ausentes y no cambia el destino', (tester) async {
      _vista(tester, const Size(390, 844));
      await tester.pumpWidget(
        _app(
          TiendasScreen(
            lectura: () => Stream.value([
              _sede(id: 'sin', nombre: 'Mass Sin GPS', lat: null, lng: null),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sin-coordenadas-sin')));
      await tester.pumpAndSettle();
      expect(find.textContaining('no tiene coordenadas'), findsOneWidget);
      expect(find.text('Delivery y rutas'), findsNothing);
    });

    testWidgets('permiso denegado, GPS apagado y ubicación concedida', (tester) async {
      _vista(tester, const Size(390, 844));
      final tiendas = [
        _sede(id: 'cerca', nombre: 'Cerca', lat: -12.01, lng: -77.01),
        _sede(id: 'lejos', nombre: 'Lejos', lat: -13.5, lng: -76),
      ];
      Future<void> montar(LecturaUbicacion lectura) async {
        await tester.pumpWidget(
          _app(
            TiendasScreen(
              lectura: () => Stream.value(tiendas),
              leerUbicacion: () async => lectura,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('usar-ubicacion-tiendas')));
        await tester.pumpAndSettle();
      }

      await montar(const LecturaUbicacion(SituacionUbicacion.denegada));
      expect(find.textContaining('No diste permiso'), findsOneWidget);
      expect(find.text('Cerca'), findsOneWidget);
      expect(find.textContaining('en línea recta'), findsNothing);

      await montar(const LecturaUbicacion(SituacionUbicacion.gpsDesactivado));
      expect(find.textContaining('GPS del dispositivo'), findsOneWidget);
      expect(find.text('Lejos'), findsOneWidget);

      var ajustes = 0;
      await tester.pumpWidget(
        _app(
          TiendasScreen(
            lectura: () => Stream.value(tiendas),
            leerUbicacion: () async =>
                const LecturaUbicacion(SituacionUbicacion.denegadaPermanentemente),
            abrirAjustes: () async => ajustes++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('usar-ubicacion-tiendas')));
      await tester.pumpAndSettle();
      expect(find.text('Abrir ajustes'), findsOneWidget);
      await tester.tap(find.text('Abrir ajustes'));
      expect(ajustes, 1);

      await montar(
        const LecturaUbicacion(
          SituacionUbicacion.concedida,
          punto: LatLng(-12.0, -77.0),
        ),
      );
      expect(find.text('Ordenadas por cercanía en línea recta.'), findsOneWidget);
      final tarjetas = tester
          .widgetList<TarjetaTiendaCliente>(find.byType(TarjetaTiendaCliente))
          .toList();
      expect(tarjetas.first.tienda.nombre, 'Cerca');
      expect(find.textContaining('en línea recta'), findsWidgets);
      expect(find.textContaining('por carretera'), findsNothing);
    });

    testWidgets('la carga no se presenta como una lista vacía', (tester) async {
      _vista(tester, const Size(390, 844));
      final controlador = StreamController<List<Tienda>>();
      addTearDown(controlador.close);
      await tester.pumpWidget(
        _app(TiendasScreen(lectura: () => controlador.stream)),
      );
      await tester.pump();
      expect(find.text('Consultando tiendas'), findsOneWidget);
      expect(find.text('Aún no hay tiendas registradas'), findsNothing);
    });
  });

  group('Delivery', () {
    testWidgets('no pide la ubicación al abrir y conserva el establecimiento', (tester) async {
      _vista(tester, const Size(390, 844));
      var lecturas = 0;
      await tester.pumpWidget(
        _app(
          DeliveryMapaScreen(
            mostrarMapa: false,
            nombreDestinoInicial: 'Mass Larco',
            detalleDestinoInicial: 'Miraflores · Lima',
            destinoInicial: const LatLng(-12.12, -77.03),
            destinoDeTienda: true,
            leerUbicacion: () async {
              lecturas++;
              return const LecturaUbicacion(SituacionUbicacion.noDisponible);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(lecturas, 0);
      expect(find.text('Mass Larco'), findsOneWidget);
      expect(find.text('Establecimiento'), findsOneWidget);
      expect(find.byType(BotonFlotanteMassBot), findsNothing);
      await tester.tap(find.byKey(const Key('usar-ubicacion-delivery')));
      await tester.pumpAndSettle();
      expect(lecturas, 1);
      expect(find.text('No se pudo obtener tu ubicación.'), findsOneWidget);
    });

    testWidgets('muestra permiso denegado y GPS desactivado sin inventar una ruta', (tester) async {
      _vista(tester, const Size(390, 844));
      Future<void> estado(LecturaUbicacion lectura, String texto) async {
        await tester.pumpWidget(
          _app(
            DeliveryMapaScreen(
              mostrarMapa: false,
              nombreDestinoInicial: 'Mass Larco',
              destinoInicial: const LatLng(-12.12, -77.03),
              destinoDeTienda: true,
              leerUbicacion: () async => lectura,
              calcular: (_, _, _) async => fail('No debía calcular una ruta'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('usar-ubicacion-delivery')));
        await tester.pumpAndSettle();
        expect(find.textContaining(texto), findsOneWidget);
        expect(find.textContaining('Tarifa'), findsNothing);
        expect(find.text('Recorrido'), findsNothing);
      }

      await estado(
        const LecturaUbicacion(SituacionUbicacion.denegada),
        'No diste permiso',
      );
      await estado(
        const LecturaUbicacion(SituacionUbicacion.gpsDesactivado),
        'GPS del dispositivo',
      );
    });

    testWidgets('calcula, distingue la estimación y descarta una respuesta vieja', (tester) async {
      _vista(tester, const Size(390, 844));
      final primero = Completer<ResultadoRuta>();
      final segundo = Completer<ResultadoRuta>();
      var llamadas = 0;
      await tester.pumpWidget(
        _app(
          DeliveryMapaScreen(
            mostrarMapa: false,
            nombreDestinoInicial: 'Mass Larco',
            destinoInicial: const LatLng(-12.12, -77.03),
            destinoDeTienda: true,
            leerUbicacion: () async => const LecturaUbicacion(
              SituacionUbicacion.concedida,
              punto: LatLng(-12.1, -77.02),
              precisionMetros: 12,
            ),
            calcular: (_, _, _) {
              llamadas++;
              return llamadas == 1 ? primero.future : segundo.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('usar-ubicacion-delivery')));
      await tester.pump();
      expect(llamadas, 1);
      await tester.tap(find.byKey(const Key('calcular-ruta')));
      await tester.pump();
      expect(llamadas, 1);

      await tester.tap(find.byKey(const Key('ampliar-panel')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Caminando'), 120);
      await tester.tap(find.text('Caminando'));
      await tester.pump();
      expect(llamadas, 2);
      primero.complete(_ruta(distancia: 50000, segundos: 3600));
      await tester.pump();
      expect(find.text('50 km'), findsNothing);

      segundo.complete(_ruta(distancia: 1800, segundos: 600));
      await tester.pumpAndSettle();
      expect(find.text('1.8 km'), findsOneWidget);
      expect(find.text('10 min'), findsOneWidget);
      expect(find.textContaining('Sigue por la avenida'), findsOneWidget);
      expect(find.textContaining('No es un tiempo de entrega garantizado'), findsOneWidget);
      expect(find.textContaining('Tarifa'), findsNothing);
      expect(find.textContaining('Envío'), findsNothing);
      expect(find.text('Tu ubicación'), findsOneWidget);
      expect(find.textContaining('Precisión ± 12 m'), findsOneWidget);
    });

    testWidgets('un fallo y una estimación no se dibujan como carretera', (tester) async {
      _vista(tester, const Size(390, 844));
      final tesela = MemoryImage(png);
      await tester.pumpWidget(
        _app(
          DeliveryMapaScreen(
            mostrarMapa: true,
            proveedorTeselas: _Teselas(tesela),
            nombreDestinoInicial: 'Mass Larco',
            destinoInicial: const LatLng(-12.12, -77.03),
            destinoDeTienda: true,
            leerUbicacion: () async => const LecturaUbicacion(
              SituacionUbicacion.concedida,
              punto: LatLng(-12.1, -77.02),
            ),
            calcular: (_, _, _) async => const ResultadoRuta(
              distanciaMetros: 4000,
              duracionSegundos: 900,
              puntos: [LatLng(-12.1, -77.02), LatLng(-12.12, -77.03)],
              esEstimacionDirecta: true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('OpenStreetMap contributors'), findsOneWidget);
      await tester.tap(find.byKey(const Key('usar-ubicacion-delivery')));
      await tester.pumpAndSettle();
      expect(find.text('La ruta por carretera no está disponible.'), findsOneWidget);
      expect(find.text('15 min'), findsNothing);
      expect(find.byType(PolylineLayer), findsNothing);
      expect(find.text('Tienda'), findsOneWidget);
      expect(find.text('Tú'), findsOneWidget);

      await tester.pumpWidget(
        _app(
          DeliveryMapaScreen(
            mostrarMapa: true,
            proveedorTeselas: _Teselas(tesela),
            nombreDestinoInicial: 'Mass Larco',
            destinoInicial: const LatLng(-12.12, -77.03),
            destinoDeTienda: true,
            leerUbicacion: () async => const LecturaUbicacion(
              SituacionUbicacion.concedida,
              punto: LatLng(-12.1, -77.02),
            ),
            calcular: (_, _, _) async => throw StateError('osrm'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byKey(const Key('usar-ubicacion-delivery')));
      await tester.pumpAndSettle();
      expect(find.text('No se pudo calcular la ruta. Inténtalo nuevamente.'), findsOneWidget);
      expect(find.textContaining('osrm'), findsNothing);
      expect(find.byType(PolylineLayer), findsNothing);
    });

    testWidgets('dibuja la ruta cuando la respuesta es válida', (tester) async {
      _vista(tester, const Size(390, 844));
      await tester.pumpWidget(
        _app(
          DeliveryMapaScreen(
            mostrarMapa: true,
            proveedorTeselas: _Teselas(MemoryImage(png)),
            nombreDestinoInicial: 'Mass Larco',
            destinoInicial: const LatLng(-12.12, -77.03),
            destinoDeTienda: true,
            leerUbicacion: () async => const LecturaUbicacion(
              SituacionUbicacion.concedida,
              punto: LatLng(-12.1, -77.02),
            ),
            calcular: (origen, destino, _) async => ResultadoRuta(
              distanciaMetros: 1800,
              duracionSegundos: 600,
              puntos: [origen, const LatLng(-12.11, -77.025), destino],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byKey(const Key('usar-ubicacion-delivery')));
      await tester.pumpAndSettle();
      expect(find.byType(PolylineLayer), findsOneWidget);
      expect(find.textContaining('OpenStreetMap contributors'), findsOneWidget);
    });

    testWidgets('el destino inválido y los ejemplos se identifican', (tester) async {
      _vista(tester, const Size(390, 844));
      await tester.pumpWidget(
        _app(
          const DeliveryMapaScreen(
            mostrarMapa: false,
            nombreDestinoInicial: 'Mass Sin GPS',
            destinoInicial: LatLng(120, 10),
            destinoDeTienda: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('El destino no tiene coordenadas válidas.'), findsOneWidget);
      expect(find.text('Mass Sin GPS'), findsOneWidget);
      expect(find.text('Establecimiento'), findsNothing);

      await tester.tap(find.byKey(const Key('ampliar-panel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ver-ejemplos')));
      await tester.pumpAndSettle();
      expect(find.text('Estos puntos no son establecimientos registrados.'), findsOneWidget);
      await tester.tap(find.text('Tienda Mass Centro — Huancayo'));
      await tester.pumpAndSettle();
      expect(find.text('Ejemplo de recorrido'), findsOneWidget);
      expect(find.text('No es un establecimiento registrado.'), findsOneWidget);
    });

    testWidgets('compartir revisa el mensaje y adjuntar vuelve al carrito', (tester) async {
      _vista(tester, const Size(390, 1400));
      String? portapapeles;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) {
          if (call.method == 'Clipboard.setData') {
            final datos = call.arguments;
            portapapeles = datos is Map ? datos['text'] as String? : null;
          }
          if (call.method == 'Clipboard.getData') {
            return Future<Map<String, dynamic>>.value(<String, dynamic>{
              'text': portapapeles,
            });
          }
          return Future<Object?>.value();
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final producto = _producto();
      CarritoService.instance.agregar(producto);
      CarritoService.instance.agregar(producto);
      expect(
        CarritoService.instance.aplicarCupon(CuponDescuento.predeterminados.first),
        isNull,
      );
      Uri? abierto;
      await tester.pumpWidget(
        _app(
          CarritoScreen(
            buscarCupon: (_) async => null,
            pantallaRuta: (_) => DeliveryMapaScreen(
              mostrarMapa: false,
              volverAlCarrito: true,
              nombreDestinoInicial: 'Mass Larco',
              destinoInicial: const LatLng(-12.12, -77.03),
              destinoDeTienda: true,
              leerUbicacion: () async => const LecturaUbicacion(
                SituacionUbicacion.concedida,
                punto: LatLng(-12.1, -77.02),
              ),
              calcular: (origen, destino, _) async => ResultadoRuta(
                distanciaMetros: 1800,
                duracionSegundos: 600,
                puntos: [origen, destino, const LatLng(-12.11, -77.025)],
              ),
              abrirEnlace: (uri) async {
                abierto = uri;
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delivery'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ver ruta'));
      await tester.tap(find.text('Ver ruta'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('usar-ubicacion-delivery')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('compartir-appbar')));
      await tester.pumpAndSettle();
      expect(find.text('Revisar antes de compartir'), findsOneWidget);
      expect(find.textContaining('Mass Larco'), findsWidgets);
      expect(find.textContaining('Tarifa'), findsNothing);
      await tester.tap(find.text('Copiar ruta'));
      await tester.pumpAndSettle();
      expect(portapapeles, contains('Mass Larco'));
      expect(portapapeles, isNot(contains('Tarifa')));

      await tester.tap(find.byKey(const Key('compartir-appbar')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar por WhatsApp'));
      await tester.pumpAndSettle();
      expect(abierto.toString(), contains('wa.me'));
      expect(Uri.decodeComponent(abierto.toString()), contains('Mass Larco'));

      await tester.tap(find.byKey(const Key('ampliar-panel')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('adjuntar-ruta')));
      await tester.tap(find.byKey(const Key('adjuntar-ruta')));
      await tester.pumpAndSettle();
      expect(find.text('Aceite de prueba'), findsOneWidget);
      expect(find.textContaining('Mass Larco'), findsWidgets);
      expect(find.textContaining('MASS10'), findsWidgets);
      expect(CarritoService.instance.unidades, 2);
      expect(CarritoService.instance.cuponAplicado?.codigo, 'MASS10');
      expect(CarritoService.instance.rutaSeleccionada, contains('Mass Larco'));
      expect(CarritoService.instance.rutaSeleccionada, isNot(contains('S/')));
    });

    testWidgets('cabe en pantallas estrechas con texto ampliado', (tester) async {
      _vista(tester, const Size(320, 640));
      await tester.pumpWidget(
        _app(
          TiendasScreen(
            lectura: () => Stream.value([
              _sede(
                nombre: 'Mass de nombre extenso para una pantalla estrecha',
                direccion: 'Avenida prolongada de prueba número mil doscientos',
              ),
            ]),
          ),
          escala: 1.4,
          sinAnimacion: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      _vista(tester, const Size(360, 640));
      await tester.pumpWidget(
        _app(
          DeliveryMapaScreen(
            mostrarMapa: false,
            nombreDestinoInicial: 'Mass de nombre extenso para el panel',
            detalleDestinoInicial: 'Distrito largo · Ciudad larga · Dirección larga',
            destinoInicial: const LatLng(-12.12, -77.03),
            destinoDeTienda: true,
          ),
          escala: 1.4,
          sinAnimacion: true,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ampliar-panel')));
      await tester.pumpAndSettle();
      expect(find.text('Detalle del recorrido'), findsNothing);
      expect(find.byKey(const Key('detalle-recorrido')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('se conservan las cinco pestañas y MassBot sigue fuera de Ubícame', (tester) async {
    _vista(tester, const Size(390, 844));
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: const SizedBox.shrink(),
          bottomNavigationBar: NavegacionInferiorMass(
            indice: 2,
            alElegir: (_) {},
            destinos: const [
              DestinoNavegacion('Inicio', Icons.storefront_rounded),
              DestinoNavegacion('Productos', Icons.local_offer_rounded),
              DestinoNavegacion('Ubícame', Icons.location_on_rounded),
              DestinoNavegacion('Compras', Icons.history_rounded),
              DestinoNavegacion('Sensores', Icons.sensors_rounded),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Productos'), findsOneWidget);
    expect(find.text('Ubícame'), findsOneWidget);
    expect(find.text('Compras'), findsOneWidget);
    expect(find.text('Sensores'), findsOneWidget);
    expect(muestraAsistenteMassBot(0), isTrue);
    expect(muestraAsistenteMassBot(1), isTrue);
    expect(muestraAsistenteMassBot(2), isFalse);
    expect(muestraAsistenteMassBot(3), isFalse);
    expect(muestraAsistenteMassBot(4), isFalse);
  });
}

Tienda _sede({
  String id = 'lima',
  String nombre = 'Mass Larco',
  String ciudad = 'Lima',
  String distrito = 'Miraflores',
  String direccion = 'Avenida Larco 123',
  String horario = '9:00 a 21:00',
  double? lat = -12.12,
  double? lng = -77.03,
}) {
  return Tienda(
    id: id,
    nombre: nombre,
    ciudad: ciudad,
    distrito: distrito,
    direccion: direccion,
    horario: horario,
    cantidadProductos: 10,
    fechaApertura: DateTime(2020, 1, 1),
    abierta: true,
    servicios: const [],
    latitud: lat,
    longitud: lng,
  );
}

Producto _producto() {
  return Producto(
    id: 'aceite',
    nombre: 'Aceite de prueba',
    descripcion: 'Fixture',
    marca: 'Mass',
    precio: 12.5,
    stock: 4,
    categoria: 'abarrotes',
    disponible: true,
    fechaRegistro: DateTime(2024, 1, 1),
    presentaciones: const ['1 L'],
    valoracion: 0,
  );
}

ResultadoRuta _ruta({required double distancia, required double segundos}) {
  return ResultadoRuta(
    distanciaMetros: distancia,
    duracionSegundos: segundos,
    puntos: const [LatLng(-12.1, -77.02), LatLng(-12.11, -77.025), LatLng(-12.12, -77.03)],
    pasos: const [PasoRuta(instruccion: 'Sigue por la avenida', distanciaMetros: 400)],
  );
}

Widget _app(Widget home, {double escala = 1, bool sinAnimacion = false}) {
  return MaterialApp(
    theme: temaClienteMovil(),
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(escala),
          disableAnimations: sinAnimacion,
        ),
        child: child!,
      );
    },
    home: home,
  );
}

void _vista(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _Teselas extends TileProvider {
  _Teselas(this.imagen);

  final ImageProvider imagen;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) => imagen;
}
