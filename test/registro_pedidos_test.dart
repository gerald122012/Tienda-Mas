import 'package:flutter_application_1/models/pedido.dart';
import 'package:flutter_application_1/services/carrito_service.dart';
import 'package:flutter_application_1/services/pedidos_local_service.dart';
import 'package:flutter_application_1/services/registro_pedidos.dart';
import 'package:flutter_application_1/models/cupon.dart';
import 'package:flutter_application_1/models/producto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Pedido _pedido(String id) {
  return Pedido(
    id: id,
    clienteUid: 'cliente-prueba',
    clienteNombre: 'Cliente de prueba',
    clienteCorreo: 'cliente@tiendamass.pe',
    fecha: DateTime(2026, 11, 24, 10),
    estado: 'pendiente',
    subtotal: 20,
    descuento: 2,
    total: 18,
    cuponCodigo: 'MASS10',
    tipoEntrega: 'recojo',
    items: const [
      ItemPedido(
        productoId: 'arroz',
        nombre: 'Arroz',
        marca: 'Mass',
        precio: 20,
        cantidad: 1,
      ),
    ],
  );
}

class _Escritor implements EscritorPedidos {
  AcuseEscritura consulta;
  Future<AcuseEscritura> Function()? alEscribir;
  int escrituras = 0;
  Map<String, dynamic>? ultimoDatos;

  _Escritor({
    this.consulta = AcuseEscritura.ausente,
    this.alEscribir,
  });

  @override
  Future<AcuseEscritura> consultar(String id) async => consulta;

  @override
  Future<AcuseEscritura> escribir(String id, Map<String, dynamic> datos) {
    escrituras++;
    ultimoDatos = datos;
    return alEscribir?.call() ?? Future.value(AcuseEscritura.confirmada);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await IntentoRegistroPedido.limpiar();
    for (final pedido in List<Pedido>.of(PedidosLocalService.instance.pedidos)) {
      if (pedido.id.startsWith('p_') || pedido.id.startsWith('hist_')) {
        await PedidosLocalService.instance.eliminarPedido(pedido.id);
      }
    }
    CarritoService.instance.vaciar();
  });

  test('un permiso denegado es un rechazo y la falta de red no lo es', () {
    expect(acuseDeErrorFirebase('permission-denied'), AcuseEscritura.rechazada);
    expect(acuseDeErrorFirebase('unauthenticated'), AcuseEscritura.rechazada);
    expect(acuseDeErrorFirebase('unavailable'), AcuseEscritura.sinConfirmar);
    expect(
      acuseDeErrorFirebase('deadline-exceeded'),
      AcuseEscritura.sinConfirmar,
    );
  });

  test('la escritura confirmada usa el identificador real y la copia local', () async {
    final escritor = _Escritor();
    final registro = RegistroPedidos(
      escritor: escritor,
      guardarLocal: PedidosLocalService.instance.guardarPedido,
    );
    final pedido = _pedido(crearIdIntento('cliente-prueba'));

    final resultado = await registro.registrar(
      pedido,
      escrituraEnviada: false,
    );

    expect(resultado.tipo, TipoResultadoRegistro.confirmado);
    expect(resultado.id, pedido.id);
    expect(resultado.id.startsWith('local_'), isFalse);
    expect(resultado.copiaLocalGuardada, isTrue);
    expect(escritor.escrituras, 1);
    expect(escritor.ultimoDatos?['total'], 18);
    expect(
      PedidosLocalService.instance.pedidos.any((p) => p.id == pedido.id),
      isTrue,
    );
  });

  test('un rechazo no confirma, no guarda historial y conserva el carrito', () async {
    final carrito = CarritoService.instance;
    final producto = Producto(
      id: 'arroz',
      nombre: 'Arroz',
      descripcion: 'Bolsa',
      marca: 'Mass',
      precio: 20,
      stock: 4,
      categoria: 'abarrotes',
      disponible: true,
      fechaRegistro: DateTime(2026, 1, 1),
      presentaciones: const ['Bolsa'],
      valoracion: 0,
    );
    carrito.agregar(producto);
    carrito.aplicarCupon(CuponDescuento.predeterminados.first);
    final subtotal = carrito.subtotal;
    final descuento = carrito.descuento;
    final total = carrito.total;
    final registro = RegistroPedidos(
      escritor: _Escritor(alEscribir: () async => AcuseEscritura.rechazada),
      guardarLocal: (_) async => fail('no debe guardar un rechazo'),
    );

    final resultado = await registro.registrar(
      _pedido('p_rechazo'),
      escrituraEnviada: false,
    );

    expect(resultado.tipo, TipoResultadoRegistro.rechazado);
    expect(resultado.copiaLocalGuardada, isFalse);
    expect(carrito.cantidadDe(producto), 1);
    expect(carrito.cuponAplicado?.codigo, 'MASS10');
    expect(carrito.subtotal, subtotal);
    expect(carrito.descuento, descuento);
    expect(carrito.total, total);
  });

  test('sin confirmación del servidor no crea otro pedido ni entra al historial', () async {
    final escritor = _Escritor(
      consulta: AcuseEscritura.sinConfirmar,
      alEscribir: () async => AcuseEscritura.sinConfirmar,
    );
    final registro = RegistroPedidos(
      escritor: escritor,
      guardarLocal: (_) async => fail('no debe guardar un pedido sin confirmar'),
    );
    final pedido = _pedido('p_pendiente');

    final primero = await registro.registrar(pedido, escrituraEnviada: false);
    final reintento = await registro.registrar(
      pedido,
      escrituraEnviada: primero.escrituraEnviada,
    );

    expect(primero.tipo, TipoResultadoRegistro.sinConfirmar);
    expect(reintento.tipo, TipoResultadoRegistro.sinConfirmar);
    expect(escritor.escrituras, 1);
    expect(PedidosLocalService.instance.pedidos.any((p) => p.id == pedido.id), isFalse);
  });

  test('una respuesta tardía confirma el mismo pedido sin escribir de nuevo', () async {
    final escritor = _Escritor(
      alEscribir: () async => AcuseEscritura.sinConfirmar,
    );
    final registro = RegistroPedidos(
      escritor: escritor,
      guardarLocal: PedidosLocalService.instance.guardarPedido,
    );
    final pedido = _pedido('p_tardio');

    final pendiente = await registro.registrar(pedido, escrituraEnviada: false);
    escritor.consulta = AcuseEscritura.confirmada;
    final tardio = await registro.registrar(
      pedido,
      escrituraEnviada: pendiente.escrituraEnviada,
    );

    expect(pendiente.tipo, TipoResultadoRegistro.sinConfirmar);
    expect(tardio.tipo, TipoResultadoRegistro.confirmado);
    expect(tardio.id, pedido.id);
    expect(escritor.escrituras, 1);
    expect(
      PedidosLocalService.instance.pedidos.any((p) => p.id == pedido.id),
      isTrue,
    );
  });

  test('no sobrescribe un pedido que el servidor ya confirmó', () async {
    final escritor = _Escritor(consulta: AcuseEscritura.confirmada);
    final registro = RegistroPedidos(
      escritor: escritor,
      guardarLocal: PedidosLocalService.instance.guardarPedido,
    );

    final resultado = await registro.registrar(
      _pedido('p_existente'),
      escrituraEnviada: true,
    );

    expect(resultado.confirmado, isTrue);
    expect(escritor.escrituras, 0);
  });

  test('si la copia local falla después del acuse, el pedido sigue confirmado', () async {
    final registro = RegistroPedidos(
      escritor: _Escritor(),
      guardarLocal: (_) async => false,
    );

    final resultado = await registro.registrar(
      _pedido('p_copia'),
      escrituraEnviada: false,
    );

    expect(resultado.tipo, TipoResultadoRegistro.confirmado);
    expect(resultado.copiaLocalGuardada, isFalse);
  });

  test('un fallo de red al escribir queda sin confirmar', () async {
    final registro = RegistroPedidos(
      escritor: _Escritor(alEscribir: () async => throw Exception('socket')),
      guardarLocal: (_) async => fail('no debe guardar'),
    );

    final resultado = await registro.registrar(
      _pedido('p_red'),
      escrituraEnviada: false,
    );

    expect(resultado.tipo, TipoResultadoRegistro.sinConfirmar);
    expect(resultado.escrituraEnviada, isTrue);
  });

  test('un pedido histórico confirmado permanece y el rechazado no se agrega', () async {
    final historico = _pedido('hist_antiguo');
    await PedidosLocalService.instance.guardarPedido(historico);
    final registro = RegistroPedidos(
      escritor: _Escritor(alEscribir: () async => AcuseEscritura.rechazada),
      guardarLocal: PedidosLocalService.instance.guardarPedido,
    );

    await registro.registrar(_pedido('p_nuevo'), escrituraEnviada: false);

    final ids = PedidosLocalService.instance.pedidos.map((p) => p.id);
    expect(ids, contains('hist_antiguo'));
    expect(ids, isNot(contains('p_nuevo')));
  });

  test('una instantánea de caché o pendiente no confirma la escritura', () {
    expect(
      acuseDeInstantanea(
        existe: true,
        escrituraPendiente: false,
        desdeCache: false,
      ),
      AcuseEscritura.confirmada,
    );
    expect(
      acuseDeInstantanea(
        existe: true,
        escrituraPendiente: false,
        desdeCache: true,
      ),
      AcuseEscritura.sinConfirmar,
    );
    expect(
      acuseDeInstantanea(
        existe: true,
        escrituraPendiente: true,
        desdeCache: false,
      ),
      AcuseEscritura.sinConfirmar,
    );
    expect(
      acuseDeInstantanea(
        existe: false,
        escrituraPendiente: false,
        desdeCache: false,
      ),
      AcuseEscritura.sinConfirmar,
    );
  });

  test('el intento de una cuenta no se reutiliza en otra ni se borra al salir', () async {
    const ana = IntentoRegistro(id: 'p_ana', escrituraEnviada: true);
    const beto = IntentoRegistro(id: 'p_beto', escrituraEnviada: false);
    await IntentoRegistroPedido.guardar(
      ana,
      uid: 'uid-ana',
      correo: 'ana@tiendamass.pe',
    );
    await IntentoRegistroPedido.guardar(
      beto,
      uid: 'uid-beto',
      correo: 'beto@tiendamass.pe',
    );

    final deAna = await IntentoRegistroPedido.leer(
      uid: 'uid-ana',
      correo: 'ana@tiendamass.pe',
    );
    final deBeto = await IntentoRegistroPedido.leer(
      uid: 'uid-beto',
      correo: 'beto@tiendamass.pe',
    );
    expect(deAna?.id, 'p_ana');
    expect(deBeto?.id, 'p_beto');

    await IntentoRegistroPedido.limpiar(uid: 'uid-ana', correo: 'ana@tiendamass.pe');
    expect(
      await IntentoRegistroPedido.leer(uid: 'uid-ana', correo: 'ana@tiendamass.pe'),
      isNull,
    );
    expect(
      (await IntentoRegistroPedido.leer(
        uid: 'uid-beto',
        correo: 'beto@tiendamass.pe',
      ))?.id,
      'p_beto',
    );
  });

  test('un intento legado no se asigna a una cuenta nueva', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      IntentoRegistroPedido.clave,
      '{"id":"p_legado","escrituraEnviada":true}',
    );

    expect(
      await IntentoRegistroPedido.leer(
        uid: 'uid-nueva',
        correo: 'nueva@tiendamass.pe',
      ),
      isNull,
    );
    await IntentoRegistroPedido.guardar(
      const IntentoRegistro(id: 'p_nueva', escrituraEnviada: false),
      uid: 'uid-nueva',
      correo: 'nueva@tiendamass.pe',
    );
    expect(prefs.getString(IntentoRegistroPedido.clave), contains('p_legado'));
    expect(prefs.getString(IntentoRegistroPedido.clave), contains('p_nueva'));
  });
}
