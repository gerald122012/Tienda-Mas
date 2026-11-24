class RespuestaSolicitud<T> {
  final T? valor;
  final Object? error;
  final bool ignorada;

  const RespuestaSolicitud._({this.valor, this.error, required this.ignorada});

  const RespuestaSolicitud.ignorada() : this._(ignorada: true);

  const RespuestaSolicitud.valor(T valor) : this._(valor: valor, ignorada: false);

  const RespuestaSolicitud.fallo(Object error)
    : this._(error: error, ignorada: false);
}

class ControlSolicitudesRuta {
  int _generacion = 0;
  int _enCurso = 0;

  bool get ocupada => _enCurso > 0;

  void invalidar() {
    _generacion++;
  }

  Future<RespuestaSolicitud<T>> ejecutar<T>(
    Future<T> Function() tarea, {
    bool reemplazar = false,
  }) async {
    if (_enCurso > 0 && !reemplazar) {
      return RespuestaSolicitud<T>.ignorada();
    }
    final id = ++_generacion;
    _enCurso++;
    try {
      final valor = await tarea();
      if (id != _generacion) return RespuestaSolicitud<T>.ignorada();
      return RespuestaSolicitud<T>.valor(valor);
    } catch (error) {
      if (id != _generacion) return RespuestaSolicitud<T>.ignorada();
      return RespuestaSolicitud<T>.fallo(error);
    } finally {
      _enCurso = (_enCurso - 1).clamp(0, 999);
    }
  }
}
