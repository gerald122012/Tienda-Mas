enum Rol { administrador, cliente }

class Usuario {
  final String nombre;
  final String correo;
  final Rol rol;
  final String? fotoBase64;

  const Usuario({
    required this.nombre,
    required this.correo,
    required this.rol,
    this.fotoBase64,
  });

  bool get esAdmin => rol == Rol.administrador;

  Usuario copyWith({
    String? nombre,
    String? correo,
    Rol? rol,
    String? fotoBase64,
    bool limpiarFoto = false,
  }) {
    return Usuario(
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      rol: rol ?? this.rol,
      fotoBase64: limpiarFoto ? null : (fotoBase64 ?? this.fotoBase64),
    );
  }
}
