import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/pedido.dart';
import 'package:flutter_application_1/models/producto.dart';
import 'package:flutter_application_1/screens/massbot/widgets/boton_flotante_massbot.dart';
import 'package:flutter_application_1/screens/pedidos/detalle_pedido_screen.dart';
import 'package:flutter_application_1/screens/pedidos/historial_compras_screen.dart';
import 'package:flutter_application_1/screens/perfil/perfil_screen.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/catalogo_sesion.dart';
import 'package:flutter_application_1/services/historial_pedidos.dart';
import 'package:flutter_application_1/services/pedidos_local_service.dart';
import 'package:flutter_application_1/tema/tema_mass.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

Pedido _pedido({
  required String id,
  String uid = 'uid-ana',
  String correo = 'ana@ejemplo.test',
  String estado = 'pendiente',
  DateTime? fecha,
  bool fechaRegistrada = true,
  String nombre = 'Arroz extra',
  String productoId = 'arroz',
  double precio = 12.5,
  int cantidad = 2,
  String tipoEntrega = 'recojo',
  String persona = '',
  String foto = '',
  String ruta = '',
  String cupon = '',
  double descuento = 0,
  String marca = 'Mass',
}) {
  return Pedido(
    id: id,
    clienteUid: uid,
    clienteNombre: 'Ana',
    clienteCorreo: correo,
    fecha: fecha ?? DateTime(2026, 11, 20, 9),
    fechaRegistrada: fechaRegistrada,
    estado: estado,
    subtotal: precio * cantidad,
    descuento: descuento,
    total: precio * cantidad - descuento,
    cuponCodigo: cupon,
    tipoEntrega: tipoEntrega,
    personaRecojo: persona,
    fotoRecojoBase64: foto,
    rutaResumen: ruta,
    items: [
      ItemPedido(
        productoId: productoId,
        nombre: nombre,
        marca: marca,
        precio: precio,
        cantidad: cantidad,
      ),
    ],
  );
}

Stream<ResultadoLecturaPedidos> _lectura(ResultadoLecturaPedidos resultado) {
  return Stream<ResultadoLecturaPedidos>.multi((control) {
    control.add(resultado);
  });
}

Future<void> _sesion() async {
  final error = await AuthService.instance.iniciarSesion(
    'cliente@tiendamass.pe',
    'Cliente123',
  );
  expect(error, isNull);
}

Future<void> _montar(
  WidgetTester tester,
  Widget home, {
  Size tamano = const Size(390, 844),
  double escala = 1,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      theme: temaClienteMovil(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(escala),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogoSesion.instancia.reiniciar();
  });

  tearDown(() async {
    for (final pedido in List<Pedido>.of(PedidosLocalService.instance.pedidos)) {
      if (pedido.id.startsWith('etapa124_') ||
          pedido.clienteCorreo.endsWith('@ejemplo.test')) {
        await PedidosLocalService.instance.eliminarPedido(pedido.id);
      }
    }
    await AuthService.instance.cerrarSesion();
    CatalogoSesion.instancia.reiniciar();
  });

  test('los estados del pedido siguen siendo los del administrador', () {
    expect(Pedido.estados, [
      'pendiente',
      'preparando',
      'entregado',
      'cancelado',
    ]);
  });

  test('el historial separa cuentas, duplicados, pendientes y locales antiguos', () {
    final ana = _pedido(id: 'etapa124_ana', nombre: 'Leche Ana');
    final repetido = _pedido(
      id: 'etapa124_ana',
      nombre: 'Leche remota',
      estado: 'entregado',
      fecha: DateTime(2026, 11, 22, 8),
    );
    final beto = _pedido(
      id: 'etapa124_beto',
      uid: 'uid-beto',
      correo: 'beto@ejemplo.test',
      nombre: 'Pan Beto',
    );
    final mismoCorreoOtroUid = _pedido(
      id: 'etapa124_ajeno',
      uid: 'uid-ajena',
      correo: 'ana@ejemplo.test',
      nombre: 'Ajeno',
    );
    final antiguo = _pedido(id: 'local_antiguo', nombre: 'Registro viejo');
    final historicoCorreo = _pedido(
      id: 'etapa124_correo',
      uid: '',
      correo: 'ana@ejemplo.test',
      nombre: 'Histórico por correo',
    );
    final sinFecha = _pedido(
      id: 'etapa124_sin_fecha',
      fechaRegistrada: false,
      nombre: 'Sin fecha',
      fecha: DateTime(2026, 11, 24),
    );
    final pendiente = LecturaRemota(
      _pedido(id: 'etapa124_pendiente', nombre: 'Escritura pendiente'),
      escrituraPendiente: true,
    );

    final historial = clasificarHistorial(
      remotos: [
        LecturaRemota(repetido),
        LecturaRemota(beto),
        LecturaRemota(mismoCorreoOtroUid),
        pendiente,
      ],
      locales: [ana, antiguo, historicoCorreo, sinFecha],
      uid: 'uid-ana',
      correo: 'ana@ejemplo.test',
      filtro: FiltroPedidos.todos,
    );

    final ids = historial.confirmados.map((p) => p.id).toList();
    expect(ids, containsAll(['etapa124_ana', 'etapa124_correo', 'etapa124_sin_fecha']));
    expect(ids, isNot(contains('etapa124_beto')));
    expect(ids, isNot(contains('etapa124_ajeno')));
    expect(ids, isNot(contains('etapa124_pendiente')));
    expect(ids, isNot(contains('local_antiguo')));
    expect(ids.first, 'etapa124_ana');
    expect(ids.last, 'etapa124_sin_fecha');
    expect(historial.confirmados.first.items.first.nombre, 'Leche remota');
    expect(historial.confirmados.first.estado, 'entregado');
    expect(historial.totalConfirmados, 3);
    expect(historial.localesSinConfirmar.single.id, 'local_antiguo');

    final soloEntregados = clasificarHistorial(
      remotos: [LecturaRemota(repetido)],
      locales: [ana, antiguo],
      uid: 'uid-ana',
      correo: 'ana@ejemplo.test',
      filtro: FiltroPedidos.entregado,
    );
    expect(soloEntregados.confirmados.single.estado, 'entregado');
    expect(soloEntregados.localesSinConfirmar.single.id, 'local_antiguo');

    final mapa = Pedido.fromMap('sin-fecha', {'clienteCorreo': 'a@b.pe'});
    expect(mapa.fechaRegistrada, isFalse);
    expect(textoFechaPedido(mapa), 'Fecha no disponible');
  });

  test('la foto del catálogo solo se usa si el identificador coincide una vez', () {
    final catalogo = [
      _producto('arroz'),
      _producto('arroz'),
      _producto('leche'),
    ];
    expect(productoCoincidente('arroz', catalogo), isNull);
    expect(productoCoincidente('leche', catalogo)?.id, 'leche');
    expect(productoCoincidente('', catalogo), isNull);
    expect(productoCoincidente('ausente', catalogo), isNull);
  });

  testWidgets('el invitado entra a la autenticación y no ve pedidos', (tester) async {
    await _montar(
      tester,
      HistorialComprasScreen(
        lecturaRemota: _lectura(
          ResultadoLecturaPedidos(
            pedidos: [LecturaRemota(_pedido(id: 'etapa124_oculto', nombre: 'Secreto'))],
          ),
        ),
      ),
    );
    expect(find.text('Tus pedidos, en un solo lugar'), findsOneWidget);
    expect(find.text('Secreto'), findsNothing);
    expect(find.textContaining('Total pagado'), findsNothing);
    expect(find.byType(BotonFlotanteMassBot), findsNothing);
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Usa el correo de tu cuenta.'), findsOneWidget);
  });

  testWidgets('una cuenta sin pedidos puede ir al catálogo', (tester) async {
    await _sesion();
    var exploraciones = 0;
    await _montar(
      tester,
      HistorialComprasScreen(
        uid: 'uid-vacio',
        lecturaRemota: _lectura(const ResultadoLecturaPedidos()),
        alExplorar: () => exploraciones++,
      ),
    );
    expect(find.text('Aún no tienes pedidos'), findsOneWidget);
    expect(find.text('1 pedido'), findsNothing);
    await tester.tap(find.text('Explorar productos'));
    expect(exploraciones, 1);
  });

  testWidgets('el historial filtra, ordena y abre el detalle histórico', (tester) async {
    await _sesion();
    CatalogoSesion.instancia.publicar([
      _producto('arroz', precio: 99, imagen: _png),
    ]);
    final reciente = _pedido(
      id: 'etapa124_reciente',
      nombre: 'Aceite reciente',
      estado: 'entregado',
      fecha: DateTime(2026, 11, 24, 18),
      precio: 12.5,
      descuento: 2.5,
      cupon: 'MASS10',
      persona: 'Ana Ruiz',
      foto: _png,
    );
    final antiguo = _pedido(
      id: 'etapa124_antiguo',
      nombre: 'Fideos antiguos',
      estado: 'cancelado',
      fecha: DateTime(2026, 11, 1, 8),
      tipoEntrega: 'delivery',
      ruta: 'Ruta de prueba, 1.2 km',
    );
    final local = _pedido(id: 'local_etapa124', nombre: 'Copia antigua');
    await PedidosLocalService.instance.guardarPedido(local);
    await _montar(
      tester,
      HistorialComprasScreen(
        uid: 'uid-ana',
        lecturaRemota: _lectura(
          ResultadoLecturaPedidos(
            pedidos: [
              LecturaRemota(antiguo),
              LecturaRemota(reciente),
              LecturaRemota(
                _pedido(id: 'etapa124_cola', nombre: 'Todavía no confirmado'),
                escrituraPendiente: true,
              ),
            ],
          ),
        ),
      ),
      tamano: const Size(390, 1400),
    );

    expect(find.text('2 pedidos'), findsOneWidget);
    expect(find.text('Aceite reciente'), findsOneWidget);
    expect(find.text('Fideos antiguos'), findsOneWidget);
    expect(find.text('Todavía no confirmado'), findsNothing);
    expect(find.text('Copia antigua'), findsOneWidget);
    expect(
      find.text('Registro local sin confirmación del servidor'),
      findsOneWidget,
    );
    expect(find.textContaining('Total pagado'), findsNothing);
    expect(find.textContaining('Pagar'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Aceite reciente')).dy,
      lessThan(tester.getTopLeft(find.text('Fideos antiguos')).dy),
    );

    await tester.ensureVisible(find.text('Cancelados'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelados'));
    await tester.pumpAndSettle();
    expect(find.text('Fideos antiguos'), findsOneWidget);
    expect(find.text('Aceite reciente'), findsNothing);
    expect(find.text('Copia antigua'), findsOneWidget);
    expect(find.text('2 pedidos'), findsOneWidget);

    await tester.tap(find.text('Ver detalle').first);
    await tester.pumpAndSettle();
    expect(find.text('Ruta de prueba, 1.2 km'), findsOneWidget);
    expect(find.text('Cancelado'), findsWidgets);
    expect(find.text('S/ 25.00'), findsWidgets);
    expect(find.text('S/ 99.00'), findsNothing);
    expect(find.text('La tienda marcó este pedido como cancelado.'), findsOneWidget);
    expect(find.textContaining('fechas de cada cambio'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Fideos antiguos'), findsOneWidget);
    expect(find.text('Aceite reciente'), findsNothing);

    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aceite reciente'));
    await tester.pumpAndSettle();
    expect(find.text('Cupón MASS10'), findsOneWidget);
    expect(find.text('Descuento S/ 2.50'), findsOneWidget);
    expect(find.text('Total de productos'), findsOneWidget);
    expect(find.text('S/ 22.50'), findsOneWidget);
    expect(find.text('S/ 99.00'), findsNothing);
    expect(find.text('Persona autorizada: Ana Ruiz'), findsOneWidget);
    expect(find.text('Solo se muestra el estado guardado. No hay fechas de cada cambio.'), findsOneWidget);
    expect(find.byType(DetallePedidoScreen), findsOneWidget);
  });

  testWidgets('la caché se distingue de un error y el error no parece un historial vacío', (
    tester,
  ) async {
    await _sesion();
    await _montar(
      tester,
      HistorialComprasScreen(
        uid: 'uid-ana',
        lecturaRemota: _lectura(
          ResultadoLecturaPedidos(
            desdeCache: true,
            pedidos: [
              LecturaRemota(_pedido(id: 'etapa124_cache', nombre: 'Desde caché')),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Desde caché'), findsOneWidget);
    expect(find.textContaining('Todavía no pudimos actualizarlo'), findsOneWidget);
    expect(find.text('Aún no tienes pedidos'), findsNothing);

    await _montar(
      tester,
      HistorialComprasScreen(
        uid: 'uid-ana',
        lecturaRemota: Stream<ResultadoLecturaPedidos>.error(StateError('red')),
      ),
    );
    expect(find.text('No pudimos consultar tus pedidos'), findsOneWidget);
    expect(find.text('Aún no tienes pedidos'), findsNothing);
    expect(find.textContaining('StateError'), findsNothing);
  });

  testWidgets('cambiar de cuenta no conserva los pedidos anteriores', (tester) async {
    await _sesion();
    await _montar(
      tester,
      HistorialComprasScreen(
        uid: 'uid-ana',
        lecturaRemota: _lectura(
          ResultadoLecturaPedidos(
            pedidos: [
              LecturaRemota(_pedido(id: 'etapa124_ana_ui', nombre: 'Compra de Ana')),
              LecturaRemota(
                _pedido(
                  id: 'etapa124_beto_ui',
                  uid: 'uid-beto',
                  nombre: 'Compra de Beto',
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Compra de Ana'), findsOneWidget);
    expect(find.text('Compra de Beto'), findsNothing);

    await _montar(
      tester,
      HistorialComprasScreen(
        uid: 'uid-beto',
        lecturaRemota: _lectura(
          ResultadoLecturaPedidos(
            pedidos: [
              LecturaRemota(_pedido(id: 'etapa124_ana_ui', nombre: 'Compra de Ana')),
              LecturaRemota(
                _pedido(
                  id: 'etapa124_beto_ui',
                  uid: 'uid-beto',
                  nombre: 'Compra de Beto',
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Compra de Beto'), findsOneWidget);
    expect(find.text('Compra de Ana'), findsNothing);
  });

  testWidgets('el perfil muestra iniciales, fotografía, accesos y cierra sesión', (
    tester,
  ) async {
    await _sesion();
    await _montar(
      tester,
      PerfilScreen(
        lecturaCompras: _lectura(const ResultadoLecturaPedidos()),
        uidCompras: 'uid-vacio',
      ),
    );
    expect(find.text('CM'), findsOneWidget);
    expect(find.text('Cliente Mass'), findsWidgets);
    expect(find.text('cliente@tiendamass.pe'), findsWidgets);
    expect(find.textContaining('uid'), findsNothing);
    expect(find.textContaining('DNI'), findsNothing);
    expect(find.byType(BotonFlotanteMassBot), findsNothing);
    await tester.tap(find.text('Mis compras'));
    await tester.pumpAndSettle();
    expect(find.text('Aún no tienes pedidos'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Escáner'));
    await tester.pumpAndSettle();
    expect(find.text('Escáner Mass'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await AuthService.instance.actualizarFotoPerfil(_png);
    await tester.pumpAndSettle();
    expect(find.text('CM'), findsNothing);
    expect(find.text('Quitar'), findsOneWidget);

    await tester.tap(find.text('Quitar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('CM'), findsOneWidget);

    await AuthService.instance.actualizarFotoPerfil('no-es-imagen');
    await tester.pumpAndSettle();
    expect(find.text('No se pudo mostrar la fotografía.'), findsOneWidget);
    expect(find.text('CM'), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.text('Perfil'))).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Cerrar sesión'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Saldrás de tu cuenta en este dispositivo.'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(AuthService.instance.usuario, isNotNull);

    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Cerrar sesión'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(AuthService.instance.usuario, isNull);

    await _montar(
      tester,
      const HistorialComprasScreen(),
    );
    expect(find.text('Tus pedidos, en un solo lugar'), findsOneWidget);
    expect(find.text('Cliente Mass'), findsNothing);
  });

  testWidgets('compras y perfil caben en 320 puntos y con texto ampliado', (tester) async {
    await _sesion();
    final pedido = _pedido(
      id: 'etapa124_angosto',
      nombre: 'Nombre muy largo de un producto de la estantería norte',
      persona: 'Persona autorizada con un nombre extenso',
    );
    await _montar(
      tester,
      HistorialComprasScreen(
        uid: 'uid-ana',
        lecturaRemota: _lectura(
          ResultadoLecturaPedidos(pedidos: [LecturaRemota(pedido)]),
        ),
      ),
      tamano: const Size(320, 640),
      escala: 1.4,
    );
    expect(tester.takeException(), isNull);

    await _montar(
      tester,
      const PerfilScreen(uidCompras: 'uid-vacio'),
      tamano: const Size(320, 640),
      escala: 1.4,
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(BotonFlotanteMassBot), findsNothing);
  });

  test('MassBot sigue limitado a Inicio y Productos', () {
    expect(muestraAsistenteMassBot(0), isTrue);
    expect(muestraAsistenteMassBot(1), isTrue);
    expect(muestraAsistenteMassBot(2), isFalse);
    expect(muestraAsistenteMassBot(3), isFalse);
    expect(muestraAsistenteMassBot(4), isFalse);
  });
}

Producto _producto(String id, {double precio = 10, String imagen = ''}) {
  return Producto(
    id: id,
    nombre: id,
    descripcion: id,
    marca: 'Mass',
    precio: precio,
    stock: 4,
    categoria: 'abarrotes',
    disponible: true,
    fechaRegistro: DateTime(2026, 1, 1),
    presentaciones: const ['Bolsa 1 kg'],
    valoracion: 0,
    imagenBase64: imagen,
  );
}
