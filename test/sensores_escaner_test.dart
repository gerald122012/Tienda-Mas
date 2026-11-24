import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/cupon.dart';
import 'package:flutter_application_1/models/producto.dart';
import 'package:flutter_application_1/screens/escaner/escaner_herramientas_screen.dart';
import 'package:flutter_application_1/screens/massbot/widgets/boton_flotante_massbot.dart';
import 'package:flutter_application_1/screens/sensores/sensores_screen.dart';
import 'package:flutter_application_1/services/carrito_service.dart';
import 'package:flutter_application_1/services/lectura_escaner.dart';
import 'package:flutter_application_1/services/permisos_service.dart';
import 'package:flutter_application_1/services/telemetria_sensores.dart';
import 'package:flutter_application_1/widgets/navegacion_inferior_mass.dart';
import 'package:flutter_test/flutter_test.dart';

Producto _producto({
  String id = 'aceite',
  String nombre = 'Aceite de prueba',
  String codigo = '7751234567890',
  double precio = 12.5,
  int stock = 4,
  bool disponible = true,
}) {
  return Producto(
    id: id,
    nombre: nombre,
    descripcion: nombre,
    marca: 'Mass',
    precio: precio,
    stock: stock,
    categoria: 'abarrotes',
    disponible: disponible,
    fechaRegistro: DateTime(2026, 1, 1),
    presentaciones: const ['Botella 1 L'],
    valoracion: 0,
    codigoBarras: codigo,
  );
}

class _Flujos {
  final acc = StreamController<LecturaEjes>.broadcast();
  final lineal = StreamController<LecturaEjes>.broadcast();
  final gyro = StreamController<LecturaEjes>.broadcast();
  final mag = StreamController<LecturaEjes>.broadcast();

  late final FuenteSensores fuente = FuenteSensores(
    acelerometro: () => acc.stream,
    lineal: () => lineal.stream,
    giroscopio: () => gyro.stream,
    magnetometro: () => mag.stream,
  );

  Future<void> cerrar() async {
    await acc.close();
    await lineal.close();
    await gyro.close();
    await mag.close();
  }
}

Future<void> _pantalla(
  WidgetTester tester,
  Widget home, {
  Size tamano = const Size(400, 2400),
  double escala = 1,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(escala),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
      home: home,
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => CarritoService.instance.vaciar());
  tearDown(() => CarritoService.instance.vaciar());

  test('la serie del gráfico conserva solo las muestras recientes', () {
    final serie = SerieLecturas();
    for (var i = 0; i < 50; i++) {
      serie.agregar(LecturaEjes(i.toDouble(), 0, 0));
    }
    serie.agregar(const LecturaEjes(double.nan, 0, 0));
    expect(serie.longitud, SerieLecturas.limite);
    expect(serie.muestras.first.x, 14);
    expect(serie.muestras.last.x, 49);
  });

  test('la brújula ignora lecturas nulas y no salta 360 grados', () {
    expect(rumboGrados(0, 0), isNull);
    expect(rumboGrados(double.nan, 1), isNull);
    expect(puntoCardinal(null), isNull);
    expect(puntoCardinal(rumboGrados(42, 0)), 'N');
    expect(puntoCardinal(rumboGrados(0, 42)), 'E');
    expect(deltaRumboCorto(350, 10), closeTo(20, 0.001));
    expect(deltaRumboCorto(10, 350), closeTo(-20, 0.001));
  });

  test('el nivel reutiliza la proporción del acelerómetro sin inventar grados', () {
    expect(burbujaDesdeAcelerometro(const LecturaEjes(double.nan, 0, 9)), isNull);
    final quieto = burbujaDesdeAcelerometro(const LecturaEjes(0, 0, 9.81));
    expect(quieto?.equilibrio, isTrue);
    final inclinado = burbujaDesdeAcelerometro(const LecturaEjes(4, 0, 9.81));
    expect(inclinado?.equilibrio, isFalse);
    expect(inclinado!.x, closeTo(4 / 9.81, 0.001));
  });

  test('la sacudida respeta la espera y alterna los cupones existentes', () {
    final detector = DetectorSacudida();
    final inicio = DateTime(2026, 11, 24, 10);
    final primera = detector.evaluar(
      magnitudLineal: 13,
      magnitudConGravedad: 0,
      ahora: inicio,
    );
    final repetida = detector.evaluar(
      magnitudLineal: 30,
      magnitudConGravedad: 30,
      ahora: inicio.add(const Duration(seconds: 1)),
    );
    final segunda = detector.evaluar(
      magnitudLineal: 0,
      magnitudConGravedad: 23,
      ahora: inicio.add(const Duration(seconds: 2)),
    );
    final invalida = detector.evaluar(
      magnitudLineal: double.nan,
      magnitudConGravedad: double.nan,
      ahora: inicio.add(const Duration(seconds: 5)),
    );
    expect(primera.cupon?.codigo, 'MASS10');
    expect(repetida.ignoradaPorEspera, isTrue);
    expect(repetida.cupon, isNull);
    expect(segunda.cupon?.codigo, 'AHORRO5');
    expect(invalida.detectada, isFalse);
    expect(detector.conteo, 2);
  });

  test('el cupón QR no se aplica solo por tener formato', () {
    const inactivo = CuponDescuento(
      codigo: 'MASS10',
      descripcion: 'Pausado',
      tipo: 'porcentaje',
      valor: 10,
      activo: false,
    );
    expect(
      decidirCupon(
        raw: 'https://ejemplo.test',
        cupon: null,
        carritoVacio: true,
        subtotal: 0,
      ).estado,
      EstadoCuponVisual.inexistente,
    );
    expect(
      decidirCupon(
        raw: 'MASS10',
        cupon: inactivo,
        carritoVacio: false,
        subtotal: 40,
      ).estado,
      EstadoCuponVisual.inactivo,
    );
    expect(
      decidirCupon(
        raw: 'cupon=MASS10',
        cupon: CuponDescuento.predeterminados.first,
        carritoVacio: true,
        subtotal: 0,
      ).aplicar,
      isFalse,
    );
    final listo = decidirCupon(
      raw: 'MASS:MASS10',
      cupon: CuponDescuento.predeterminados.first,
      carritoVacio: false,
      subtotal: 20,
    );
    expect(listo.aplicar, isTrue);
    expect(listo.codigo, 'MASS10');
    final corto = decidirCupon(
      raw: 'MASS10',
      cupon: CuponDescuento.predeterminados.first,
      carritoVacio: false,
      subtotal: 5,
    );
    expect(corto.estado, EstadoCuponVisual.condiciones);
    expect(corto.aplicar, isFalse);
  });

  test('el código de barras no trata un nombre parecido como coincidencia', () {
    final aceite = _producto();
    final otro = _producto(id: 'otro', nombre: 'Aceite de oliva', codigo: '111');
    expect(
      productoPorCodigo([aceite, otro], '7751234567890')?.id,
      'aceite',
    );
    expect(productoPorCodigo([aceite], 'Aceite'), isNull);
    expect(
      productoPorCodigo([aceite], 'Aceite de prueba', permitirNombre: true)?.id,
      'aceite',
    );
    expect(productoPorCodigo([aceite, otro], '000'), isNull);
  });

  test('la compuerta ignora una segunda lectura hasta reanudar', () {
    final compuerta = CompuertaLectura();
    expect(compuerta.aceptar(' ABC '), isTrue);
    expect(compuerta.aceptar('OTRO'), isFalse);
    compuerta.reanudar();
    expect(compuerta.aceptar('OTRO'), isTrue);
    expect(compuerta.aceptar(''), isFalse);
  });

  test('los archivos conservan los formatos y rechazan el exceso de tamaño', () {
    expect(
      validarArchivoElegido(
        const ArchivoElegido(nombre: 'a.exe', extension: 'exe', tamanoBytes: 10),
      ),
      EstadoArchivoLectura.formatoInvalido,
    );
    expect(
      validarArchivoElegido(
        const ArchivoElegido(nombre: 'a.pdf', extension: '.pdf', tamanoBytes: 0),
      ),
      EstadoArchivoLectura.vacio,
    );
    expect(
      validarArchivoElegido(
        const ArchivoElegido(
          nombre: 'a.pdf',
          extension: 'pdf',
          tamanoBytes: maxBytesArchivo + 1,
        ),
      ),
      EstadoArchivoLectura.demasiadoGrande,
    );
    expect(
      validarArchivoElegido(
        const ArchivoElegido(nombre: 'a.docx', extension: 'DOCX', tamanoBytes: 20),
      ),
      EstadoArchivoLectura.valido,
    );
  });

  testWidgets('los instrumentos muestran unidades de lecturas controladas', (
    tester,
  ) async {
    final flujos = _Flujos();
    addTearDown(flujos.cerrar);
    await _pantalla(tester, SensoresScreen(fuente: flujos.fuente));
    flujos.acc.add(const LecturaEjes(1, 2, 3));
    flujos.lineal.add(const LecturaEjes(0.5, 0, 0));
    flujos.gyro.add(const LecturaEjes(1, 0, 0));
    flujos.mag.add(const LecturaEjes(0, 42, 0));
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('Sensores inteligentes'), findsOneWidget);
    expect(find.text('Acelerómetro'), findsOneWidget);
    expect(find.text('Aceleración lineal'), findsOneWidget);
    expect(find.textContaining('1.00 m/s²'), findsWidgets);
    expect(find.text('Giroscopio'), findsOneWidget);
    expect(find.textContaining('1.00 rad/s'), findsWidgets);
    expect(find.textContaining('No es un ángulo'), findsOneWidget);
    expect(find.text('Brújula'), findsOneWidget);
    expect(find.textContaining('90°'), findsOneWidget);
    expect(find.textContaining('No hay una precisión garantizada'), findsOneWidget);
    expect(find.text('Nivel'), findsOneWidget);
    expect(find.textContaining('No es un nivel certificado'), findsOneWidget);
    expect(find.text('En equilibrio'), findsNothing);
    expect(find.byType(BotonFlotanteMassBot), findsNothing);
  });

  testWidgets('el nivel en equilibrio usa una lectura real del acelerómetro', (
    tester,
  ) async {
    final flujos = _Flujos();
    addTearDown(flujos.cerrar);
    await _pantalla(tester, SensoresScreen(fuente: flujos.fuente));
    flujos.acc.add(const LecturaEjes(0, 0, 9.81));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('En equilibrio'), findsOneWidget);
  });

  testWidgets('un sensor ausente y una lectura inválida no se presentan como activos', (
    tester,
  ) async {
    await _pantalla(
      tester,
      SensoresScreen(
        fuente: FuenteSensores(
          acelerometro: () => Stream<LecturaEjes>.error(StateError('ausente')),
          lineal: () => Stream<LecturaEjes>.empty(),
          giroscopio: () => Stream<LecturaEjes>.value(
            const LecturaEjes(double.nan, 0, 0),
          ),
          magnetometro: () => Stream<LecturaEjes>.empty(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('No disponible'), findsWidgets);
    expect(find.text('Error de lectura'), findsWidgets);
    expect(find.text('0°  N'), findsNothing);
  });

  testWidgets('la simulación se identifica y no desbloquea un cupón', (
    tester,
  ) async {
    final flujos = _Flujos();
    addTearDown(flujos.cerrar);
    await _pantalla(tester, SensoresScreen(fuente: flujos.fuente));
    await tester.tap(find.byKey(const Key('simular-senal')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Simulación'), findsWidgets);
    await tester.tap(find.byKey(const Key('simular-sacudida')));
    await tester.pump();
    expect(find.textContaining('Sacudida simulada'), findsOneWidget);
    expect(CarritoService.instance.cuponAplicado, isNull);
    expect(find.text('MASS10'), findsNothing);
    await tester.tap(find.byKey(const Key('simular-senal')));
    await tester.pump();
  });

  testWidgets('dos sacudidas seguidas ofrecen un solo cupón y respetan el carrito', (
    tester,
  ) async {
    final flujos = _Flujos();
    addTearDown(flujos.cerrar);
    await _pantalla(tester, SensoresScreen(fuente: flujos.fuente));
    flujos.lineal.add(const LecturaEjes(13, 0, 0));
    flujos.lineal.add(const LecturaEjes(20, 0, 0));
    await tester.pump();
    await tester.pump();
    expect(find.text('MASS10'), findsOneWidget);
    expect(CarritoService.instance.cuponAplicado, isNull);
    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.byKey(const Key('usar-cupon-movimiento')));
    await tester.pump();
    expect(find.textContaining('Compra mínima'), findsWidgets);
    expect(CarritoService.instance.cuponAplicado, isNull);
  });

  testWidgets('los sensores se pausan fuera de la pestaña y al ir a segundo plano', (
    tester,
  ) async {
    final flujos = _Flujos();
    addTearDown(flujos.cerrar);
    final binding = TestWidgetsFlutterBinding.instance;
    addTearDown(
      () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
    );
    await _pantalla(tester, SensoresScreen(fuente: flujos.fuente));
    expect(flujos.acc.hasListener, isTrue);
    expect(flujos.gyro.hasListener, isTrue);
    expect(flujos.mag.hasListener, isTrue);

    await _pantalla(
      tester,
      SensoresScreen(visible: false, fuente: flujos.fuente),
    );
    expect(flujos.acc.hasListener, isFalse);

    await _pantalla(tester, SensoresScreen(fuente: flujos.fuente));
    expect(flujos.acc.hasListener, isTrue);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(flujos.lineal.hasListener, isFalse);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(flujos.lineal.hasListener, isTrue);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(flujos.acc.hasListener, isFalse);
    flujos.lineal.add(const LecturaEjes(13, 0, 0));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('MASS10'), findsNothing);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(flujos.acc.hasListener, isTrue);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    expect(flujos.acc.hasListener, isFalse);
    expect(flujos.gyro.hasListener, isFalse);
  });

  testWidgets('el escáner cambia de modo y no enciende la cámara en Archivos', (
    tester,
  ) async {
    var inicios = 0;
    await _pantalla(
      tester,
      EscanerHerramientasScreen(
        alIniciarCamara: () async => inicios++,
        solicitarCamara: (_, _) async => SituacionCamara.concedida,
      ),
    );
    expect(find.text('Escáner Mass'), findsOneWidget);
    expect(find.text('Cupón por código QR'), findsOneWidget);
    expect(find.byType(BotonFlotanteMassBot), findsNothing);
    await tester.tap(find.byKey(const Key('modo-barras')));
    await tester.pump();
    expect(find.text('Producto por código de barras'), findsOneWidget);
    await tester.tap(find.byKey(const Key('modo-archivos')));
    await tester.pump();
    expect(find.text('Adjunta un comprobante'), findsOneWidget);
    expect(inicios, 0);
    expect(find.byKey(const Key('activar-camara')), findsNothing);
  });

  testWidgets('la cámara se detiene cuando la aplicación deja de estar activa', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.instance;
    addTearDown(
      () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
    );
    var pausas = 0;
    await _pantalla(
      tester,
      EscanerHerramientasScreen(
        solicitarCamara: (_, _) async => SituacionCamara.concedida,
        vistaCamara: (_) => const ColoredBox(color: Color(0xFF06206A)),
        alIniciarCamara: () async {},
        alPausarCamara: () async => pausas++,
      ),
    );
    await tester.tap(find.byKey(const Key('activar-camara')));
    await tester.pump();
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(pausas, 1);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
  });

  testWidgets('un QR válido se aplica y uno inválido o inactivo no', (
    tester,
  ) async {
    final producto = _producto();
    CarritoService.instance.agregar(producto);
    CarritoService.instance.agregar(producto);
    await _pantalla(
      tester,
      EscanerHerramientasScreen(
        buscarCupon: (codigo) async => codigo == 'MASS10'
            ? CuponDescuento.predeterminados.first
            : codigo == 'PAUSA'
            ? const CuponDescuento(
                codigo: 'PAUSA',
                descripcion: 'Pausado',
                tipo: 'porcentaje',
                valor: 10,
                activo: false,
              )
            : null,
      ),
    );
    await tester.enterText(find.byKey(const Key('codigo-manual')), 'MASS10');
    await tester.tap(find.byKey(const Key('aplicar-codigo')));
    await tester.pump();
    expect(find.text('Aplicado'), findsOneWidget);
    expect(CarritoService.instance.cuponAplicado?.codigo, 'MASS10');
    expect(CarritoService.instance.cantidadDe(producto), 2);

    await tester.tap(find.byKey(const Key('escanear-de-nuevo')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('codigo-manual')), 'NOEXISTE');
    await tester.tap(find.byKey(const Key('aplicar-codigo')));
    await tester.pump();
    expect(find.text('No encontrado'), findsOneWidget);
    expect(CarritoService.instance.cuponAplicado?.codigo, 'MASS10');

    await tester.tap(find.byKey(const Key('escanear-de-nuevo')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('codigo-manual')), 'PAUSA');
    await tester.tap(find.byKey(const Key('aplicar-codigo')));
    await tester.pump();
    expect(find.text('Inactivo'), findsOneWidget);
  });

  testWidgets('el código de barras encuentra un producto y no lo agrega solo', (
    tester,
  ) async {
    final producto = _producto();
    await _pantalla(
      tester,
      EscanerHerramientasScreen(
        tabInicial: 1,
        buscarProducto: (codigo, _) async =>
            productoPorCodigo([producto], codigo),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('codigo-barras')),
      '7751234567890',
    );
    await tester.tap(find.byKey(const Key('buscar-barras')));
    await tester.pump();
    expect(find.text('Aceite de prueba'), findsOneWidget);
    expect(find.text('Mass'), findsWidgets);
    expect(find.text('Botella 1 L'), findsOneWidget);
    expect(find.textContaining('S/ 12.50'), findsOneWidget);
    expect(find.textContaining('Disponible'), findsOneWidget);
    expect(CarritoService.instance.unidades, 0);
    await tester.tap(find.byKey(const Key('agregar-producto')));
    await tester.pump();
    expect(CarritoService.instance.cantidadDe(producto), 1);
    expect(CarritoService.instance.cuponAplicado, isNull);
  });

  testWidgets('un código ausente no inventa un producto', (tester) async {
    await _pantalla(
      tester,
      EscanerHerramientasScreen(
        tabInicial: 1,
        esAdmin: true,
        buscarProducto: (_, _) async => null,
      ),
    );
    await tester.enterText(find.byKey(const Key('codigo-barras')), '000');
    await tester.tap(find.byKey(const Key('buscar-barras')));
    await tester.pump();
    expect(find.text('No encontramos este producto'), findsOneWidget);
    expect(find.byKey(const Key('registrar-producto')), findsOneWidget);
    expect(CarritoService.instance.unidades, 0);
  });

  testWidgets('la misma lectura no consulta ni agrega dos veces', (tester) async {
    var consultas = 0;
    await _pantalla(
      tester,
      EscanerHerramientasScreen(
        solicitarCamara: (_, _) async => SituacionCamara.concedida,
        buscarCupon: (_) async {
          consultas++;
          return null;
        },
        vistaCamara: (alLeer) => TextButton(
          onPressed: () => alLeer('DESCONOCIDO'),
          child: const Text('emitir'),
        ),
        alIniciarCamara: () async {},
        alLiberarCamara: () async {},
      ),
    );
    await tester.tap(find.byKey(const Key('activar-camara')));
    await tester.pump();
    await tester.tap(find.text('emitir'));
    await tester.pump();
    await tester.tap(find.text('emitir'));
    await tester.pump();
    expect(consultas, 1);
    await tester.tap(find.byKey(const Key('escanear-de-nuevo')));
    await tester.pump();
    await tester.tap(find.text('emitir'));
    await tester.pump();
    expect(consultas, 2);
  });

  testWidgets('sin permiso la cámara no inicia y se puede seguir sin ella', (
    tester,
  ) async {
    var inicios = 0;
    await _pantalla(
      tester,
      EscanerHerramientasScreen(
        solicitarCamara: (_, _) async => SituacionCamara.denegada,
        alIniciarCamara: () async => inicios++,
      ),
    );
    await tester.tap(find.byKey(const Key('activar-camara')));
    await tester.pump();
    expect(find.textContaining('No diste permiso de cámara'), findsOneWidget);
    expect(inicios, 0);
    expect(find.byKey(const Key('codigo-manual')), findsOneWidget);
  });

  testWidgets('una cámara no disponible se explica y la sesión se libera', (
    tester,
  ) async {
    var cierres = 0;
    await _pantalla(
      tester,
      EscanerHerramientasScreen(
        solicitarCamara: (_, _) async => SituacionCamara.noDisponible,
        alLiberarCamara: () async => cierres++,
      ),
    );
    await tester.tap(find.byKey(const Key('activar-camara')));
    await tester.pump();
    expect(find.text('Cámara no disponible'), findsOneWidget);
    expect(cierres, 0);

    await _pantalla(
      tester,
      EscanerHerramientasScreen(
        solicitarCamara: (_, _) async => SituacionCamara.concedida,
        vistaCamara: (_) => const ColoredBox(color: Color(0xFF06206A)),
        alIniciarCamara: () async {},
        alLiberarCamara: () async => cierres++,
        alternarLinterna: () async => true,
        cambiarCamara: () async => true,
      ),
    );
    await tester.tap(find.byKey(const Key('activar-camara')));
    await tester.pump();
    expect(find.byTooltip('Linterna'), findsOneWidget);
    expect(find.byTooltip('Cambiar cámara'), findsOneWidget);
    expect(find.byTooltip('Reiniciar lectura'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cerrar-camara')));
    await tester.pump();
    expect(cierres, 1);
    expect(find.byKey(const Key('activar-camara')), findsOneWidget);
  });

  testWidgets('archivos inválidos, válidos y con error no salen de la sesión', (
    tester,
  ) async {
    var registros = 0;
    ArchivoElegido? elegido = const ArchivoElegido(
      nombre: 'virus.exe',
      extension: 'exe',
      tamanoBytes: 40,
    );
    ResultadoRegistroArchivo registro = const ResultadoRegistroArchivo(
      enNube: false,
    );
    await _pantalla(
      tester,
      EscanerHerramientasScreen(
        tabInicial: 2,
        elegirArchivo: () async => elegido,
        registrarArchivo: (_, _) async {
          registros++;
          return registro;
        },
      ),
    );
    await tester.tap(find.byKey(const Key('seleccionar-archivo')));
    await tester.pump();
    expect(find.textContaining('JPG, PNG, PDF'), findsWidgets);
    expect(registros, 0);

    elegido = const ArchivoElegido(
      nombre: 'boleta.pdf',
      extension: 'pdf',
      tamanoBytes: 2048,
    );
    registro = const ResultadoRegistroArchivo(
      enNube: false,
      error: 'No se pudo procesar el archivo.',
    );
    await tester.tap(find.byKey(const Key('seleccionar-archivo')));
    await tester.pump();
    expect(find.text('No se pudo procesar el archivo.'), findsOneWidget);
    expect(find.text('boleta.pdf'), findsNothing);

    registro = const ResultadoRegistroArchivo(enNube: false);
    await tester.tap(find.byKey(const Key('seleccionar-archivo')));
    await tester.pump();
    expect(find.text('boleta.pdf'), findsOneWidget);
    expect(find.textContaining('Solo en esta sesión'), findsOneWidget);
    expect(find.textContaining('2.0 KB'), findsOneWidget);
  });

  testWidgets('volver al carrito conserva cantidades y el cupón', (tester) async {
    final producto = _producto();
    CarritoService.instance.agregar(producto);
    CarritoService.instance.agregar(producto);
    await _pantalla(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => EscanerHerramientasScreen(
                  volverAlCarrito: true,
                  buscarCupon: (_) async => CuponDescuento.predeterminados.first,
                ),
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('codigo-manual')), 'MASS10');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.tap(find.byKey(const Key('aplicar-codigo')));
    await tester.pump();
    expect(CarritoService.instance.cantidadDe(producto), 2);
    expect(CarritoService.instance.cuponAplicado?.codigo, 'MASS10');
    await tester.tap(find.byKey(const Key('volver-carrito')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('abrir'), findsOneWidget);
    expect(CarritoService.instance.cantidadDe(producto), 2);
    expect(CarritoService.instance.cuponAplicado?.codigo, 'MASS10');
  });

  testWidgets('Sensores y Escáner caben en una pantalla estrecha', (tester) async {
    final flujos = _Flujos();
    addTearDown(flujos.cerrar);
    await _pantalla(
      tester,
      SensoresScreen(fuente: flujos.fuente),
      tamano: const Size(320, 640),
      escala: 1.3,
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await _pantalla(
      tester,
      const EscanerHerramientasScreen(),
      tamano: const Size(320, 640),
      escala: 1.3,
    );
    await tester.tap(find.byKey(const Key('modo-archivos')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(BotonFlotanteMassBot), findsNothing);
  });

  testWidgets('la navegación inferior conserva la pestaña Sensores', (tester) async {
    await _pantalla(
      tester,
      Scaffold(
        bottomNavigationBar: NavegacionInferiorMass(
          indice: 4,
          alElegir: (_) {},
          destinos: const [
            DestinoNavegacion('Inicio', Icons.storefront_rounded),
            DestinoNavegacion('Productos', Icons.local_offer_rounded),
            DestinoNavegacion('Ubícame', Icons.location_on_rounded),
            DestinoNavegacion('Compras', Icons.history_rounded),
            DestinoNavegacion('Sensores', Icons.sensors_rounded),
          ],
        ),
        body: const SizedBox.shrink(),
      ),
      tamano: const Size(800, 600),
    );
    expect(find.text('Sensores'), findsOneWidget);
    expect(find.text('Ubícame'), findsOneWidget);
  });
}
