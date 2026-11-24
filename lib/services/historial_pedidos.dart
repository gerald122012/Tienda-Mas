import '../models/pedido.dart';
import '../models/producto.dart';
import '../utils/utilidades.dart';

enum FiltroPedidos { todos, pendiente, preparando, entregado, cancelado }

class LecturaRemota {
  final Pedido pedido;
  final bool escrituraPendiente;

  const LecturaRemota(this.pedido, {this.escrituraPendiente = false});
}

class ResultadoLecturaPedidos {
  final List<LecturaRemota> pedidos;
  final bool desdeCache;

  const ResultadoLecturaPedidos({
    this.pedidos = const [],
    this.desdeCache = false,
  });
}

class HistorialClasificado {
  final List<Pedido> confirmados;
  final int totalConfirmados;
  final List<Pedido> localesSinConfirmar;

  const HistorialClasificado({
    required this.confirmados,
    required this.totalConfirmados,
    required this.localesSinConfirmar,
  });
}

bool esRegistroLocalAntiguo(Pedido pedido) => pedido.id.startsWith('local_');

bool perteneceAlCliente(
  Pedido pedido, {
  required String uid,
  required String correo,
}) {
  final uidPedido = pedido.clienteUid.trim();
  final uidActual = uid.trim();
  if (uidPedido.isNotEmpty) {
    return uidActual.isNotEmpty && uidPedido == uidActual;
  }
  final correoPedido = pedido.clienteCorreo.trim().toLowerCase();
  final correoActual = correo.trim().toLowerCase();
  if (correoPedido.isEmpty || correoActual.isEmpty) return false;
  return correoPedido == correoActual;
}

int compararPedidos(Pedido a, Pedido b) {
  if (a.fechaRegistrada != b.fechaRegistrada) {
    return a.fechaRegistrada ? -1 : 1;
  }
  return b.fecha.compareTo(a.fecha);
}

HistorialClasificado clasificarHistorial({
  required List<LecturaRemota> remotos,
  required List<Pedido> locales,
  required String uid,
  required String correo,
  required FiltroPedidos filtro,
}) {
  final confirmados = <String, Pedido>{};
  final sinConfirmar = <String, Pedido>{};

  for (final local in locales) {
    if (!perteneceAlCliente(local, uid: uid, correo: correo)) continue;
    if (esRegistroLocalAntiguo(local)) {
      sinConfirmar[local.id] = local;
    } else if (local.id.isNotEmpty) {
      confirmados[local.id] = local;
    }
  }

  for (final remoto in remotos) {
    final pedido = remoto.pedido;
    if (!perteneceAlCliente(pedido, uid: uid, correo: correo)) continue;
    if (pedido.id.isEmpty) continue;
    if (remoto.escrituraPendiente) continue;
    confirmados[pedido.id] = pedido;
    sinConfirmar.remove(pedido.id);
  }

  final todos = confirmados.values.toList()..sort(compararPedidos);
  final visibles = filtro == FiltroPedidos.todos
      ? todos
      : todos.where((pedido) => pedido.estado == filtro.name).toList();
  final localesVisibles = sinConfirmar.values.toList()..sort(compararPedidos);
  return HistorialClasificado(
    confirmados: visibles,
    totalConfirmados: todos.length,
    localesSinConfirmar: localesVisibles,
  );
}

Producto? productoCoincidente(String productoId, List<Producto> catalogo) {
  final id = productoId.trim();
  if (id.isEmpty) return null;
  Producto? unico;
  var encontrados = 0;
  for (final producto in catalogo) {
    if (producto.id != id) continue;
    encontrados++;
    unico = producto;
    if (encontrados > 1) return null;
  }
  return encontrados == 1 ? unico : null;
}

String textoFechaPedido(Pedido pedido) {
  if (!pedido.fechaRegistrada) return 'Fecha no disponible';
  return formatoFechaHora(pedido.fecha);
}
