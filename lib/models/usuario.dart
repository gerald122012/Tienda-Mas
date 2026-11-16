enum Rol { administrador, cliente }

class Usuario {
  final String nombre;
  final String correo;
  final Rol rol;

  const Usuario({
    required this.nombre,
    required this.correo,
    required this.rol,
  });

  bool get esAdmin => rol == Rol.administrador;
}
