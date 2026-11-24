import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/auth_service.dart';
import '../../services/historial_pedidos.dart';
import '../../services/permisos_service.dart';
import '../../tema/tema_mass.dart';
import '../../utils/utilidades.dart';
import '../escaner/escaner_herramientas_screen.dart';
import '../pedidos/historial_compras_screen.dart';

class PerfilScreen extends StatefulWidget {
  final VoidCallback? alExplorarProductos;
  final Stream<ResultadoLecturaPedidos>? lecturaCompras;
  final String uidCompras;

  const PerfilScreen({
    super.key,
    this.alExplorarProductos,
    this.lecturaCompras,
    this.uidCompras = '',
  });

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _picker = ImagePicker();
  bool _procesando = false;
  String? _errorFoto;

  Future<void> _cambiarFoto(ImageSource origen) async {
    if (_procesando) return;
    if (origen == ImageSource.camera) {
      final permitido = await PermisosService.solicitarPermisoCamara(
        context,
        motivo: 'tomar tu foto de perfil',
      );
      if (!permitido || !mounted) return;
    }

    setState(() {
      _procesando = true;
      _errorFoto = null;
    });
    try {
      final archivo = await _picker.pickImage(
        source: origen,
        maxWidth: 480,
        maxHeight: 480,
        imageQuality: 72,
      );
      if (archivo == null) return;
      final bytes = await archivo.readAsBytes();
      await AuthService.instance.actualizarFotoPerfil(base64Encode(bytes));
      if (mounted) {
        mostrarMensaje(context, 'Foto de perfil actualizada.');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorFoto = 'No se pudo procesar la fotografía.';
        });
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _quitarFoto() async {
    setState(() => _errorFoto = null);
    await AuthService.instance.actualizarFotoPerfil(null);
    if (mounted) mostrarMensaje(context, 'Foto de perfil eliminada.');
  }

  Future<void> _cerrarSesion() async {
    final tokens = TokensMass.de(context);
    final confirma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cerrar sesión',
          style: textoMass(tamano: 18, peso: FontWeight.w800),
        ),
        content: Text(
          'Saldrás de tu cuenta en este dispositivo.',
          style: textoMass(color: tokens.tintaSuave),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: tokens.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 48),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirma != true || !mounted) return;
    await AuthService.instance.cerrarSesion();
    if (mounted) Navigator.maybePop(context);
  }

  void _abrirCompras() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => HistorialComprasScreen(
          mostrarAppBar: true,
          lecturaRemota: widget.lecturaCompras,
          uid: widget.uidCompras,
          alExplorar: () {
            final navegador = Navigator.of(context);
            if (navegador.canPop()) navegador.pop();
            if (navegador.canPop()) navegador.pop();
            widget.alExplorarProductos?.call();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Scaffold(
      backgroundColor: tokens.fondo,
      appBar: AppBar(
        backgroundColor: tokens.profundo,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Perfil',
          style: textoMass(
            tamano: 18,
            peso: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: AuthService.instance,
        builder: (context, _) {
          final usuario = AuthService.instance.usuario;
          if (usuario == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Inicia sesión para ver tu perfil.',
                  textAlign: TextAlign.center,
                  style: textoMass(
                    tamano: 16,
                    peso: FontWeight.w700,
                    color: tokens.profundo,
                  ),
                ),
              ),
            );
          }
          final foto = _bytesFoto(usuario.fotoBase64);
          final fotoInvalida =
              usuario.fotoBase64 != null &&
              usuario.fotoBase64!.isNotEmpty &&
              foto == null;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _EncabezadoPerfil(
                nombre: usuario.nombre,
                correo: usuario.correo,
                rol: usuario.esAdmin ? 'Administrador' : 'Cliente',
                foto: foto,
                procesando: _procesando,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorFoto != null || fotoInvalida)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _errorFoto ?? 'No se pudo mostrar la fotografía.',
                          style: textoMass(
                            tamano: 13,
                            peso: FontWeight.w700,
                            color: tokens.error,
                          ),
                        ),
                      ),
                    Text(
                      'Fotografía',
                      style: textoMass(
                        tamano: 13,
                        peso: FontWeight.w800,
                        color: tokens.tintaSuave,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Superficie(
                      tokens: tokens,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _AccionFoto(
                            icono: Icons.photo_camera_outlined,
                            etiqueta: 'Tomar foto',
                            activo: !_procesando,
                            alPulsar: () => _cambiarFoto(ImageSource.camera),
                          ),
                          _AccionFoto(
                            icono: Icons.photo_library_outlined,
                            etiqueta: 'Galería',
                            activo: !_procesando,
                            alPulsar: () => _cambiarFoto(ImageSource.gallery),
                          ),
                          if (foto != null || fotoInvalida)
                            _AccionFoto(
                              icono: Icons.delete_outline,
                              etiqueta: 'Quitar',
                              activo: !_procesando,
                              peligro: true,
                              alPulsar: _quitarFoto,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tu cuenta',
                      style: textoMass(
                        tamano: 13,
                        peso: FontWeight.w800,
                        color: tokens.tintaSuave,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Superficie(
                      tokens: tokens,
                      child: Column(
                        children: [
                          _Dato(
                            etiqueta: 'Nombre',
                            valor: usuario.nombre.isEmpty
                                ? 'Sin nombre registrado'
                                : usuario.nombre,
                          ),
                          Divider(height: 20, color: tokens.linea),
                          _Dato(etiqueta: 'Correo', valor: usuario.correo),
                          if (!usuario.esAdmin) ...[
                            Divider(height: 20, color: tokens.linea),
                            _OpcionCuenta(
                              icono: Icons.receipt_long_outlined,
                              titulo: 'Mis compras',
                              detalle: 'Consulta el estado de tus pedidos',
                              alPulsar: _abrirCompras,
                            ),
                          ],
                          Divider(height: 20, color: tokens.linea),
                          _OpcionCuenta(
                            icono: Icons.qr_code_scanner_rounded,
                            titulo: 'Escáner',
                            detalle: 'Cupones, códigos y archivos',
                            alPulsar: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const EscanerHerramientasScreen(),
                              ),
                            ),
                          ),
                          Divider(height: 20, color: tokens.linea),
                          _OpcionCuenta(
                            icono: Icons.language_rounded,
                            titulo: 'Página web Mass',
                            detalle: 'Panel web de la tienda',
                            alPulsar: () => abrirPaginaWeb(context),
                          ),
                          Divider(height: 20, color: tokens.linea),
                          _Dato(
                            etiqueta: 'Versión',
                            valor: 'v$kAppVersion ($kAppBuild)',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _cerrarSesion,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: tokens.error,
                          minimumSize: const Size(48, 48),
                          side: BorderSide(color: tokens.error),
                          textStyle: textoMass(
                            peso: FontWeight.w700,
                            color: tokens.error,
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Cerrar sesión'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Uint8List? _bytesFoto(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final bytes = base64Decode(raw);
    if (bytes.isEmpty || !_esImagen(bytes)) return null;
    return bytes;
  } catch (_) {
    return null;
  }
}

bool _esImagen(Uint8List bytes) {
  final png =
      bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47;
  final jpeg = bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8;
  return png || jpeg;
}

String inicialesDe(String nombre) {
  final partes = nombre
      .trim()
      .split(RegExp(r'\s+'))
      .where((parte) => parte.isNotEmpty)
      .toList();
  if (partes.isEmpty) return 'M';
  if (partes.length == 1) return partes.first[0].toUpperCase();
  return '${partes.first[0]}${partes[1][0]}'.toUpperCase();
}

class _EncabezadoPerfil extends StatelessWidget {
  final String nombre;
  final String correo;
  final String rol;
  final Uint8List? foto;
  final bool procesando;

  const _EncabezadoPerfil({
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.foto,
    required this.procesando,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Container(
      width: double.infinity,
      color: tokens.profundo,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: [
          _Avatar(foto: foto, nombre: nombre, procesando: procesando),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre.isEmpty ? 'Sin nombre registrado' : nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textoMass(
                    tamano: 20,
                    peso: FontWeight.w800,
                    color: Colors.white,
                    alto: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  correo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textoMass(
                    tamano: 13,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rol,
                    style: textoMass(
                      tamano: 12,
                      peso: FontWeight.w700,
                      color: tokens.sello,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final Uint8List? foto;
  final String nombre;
  final bool procesando;

  const _Avatar({
    required this.foto,
    required this.nombre,
    required this.procesando,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final bytes = foto;
    final imagen = bytes == null ? null : MemoryImage(bytes);
    return Semantics(
      label: foto == null ? 'Iniciales del nombre' : 'Fotografía de perfil',
      child: SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: tokens.accion,
              foregroundColor: Colors.white,
              backgroundImage: imagen,
              child: imagen == null
                  ? Text(
                      inicialesDe(nombre),
                      style: textoMass(
                        tamano: 22,
                        peso: FontWeight.w800,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            if (procesando)
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Superficie extends StatelessWidget {
  final TokensMass tokens;
  final Widget child;

  const _Superficie({required this.tokens, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.superficie,
        borderRadius: BorderRadius.circular(MassRadio.tarjeta),
        border: Border.all(color: tokens.linea),
      ),
      child: child,
    );
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Dato({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            etiqueta,
            style: textoMass(tamano: 13, color: tokens.tintaSuave),
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: textoMass(tamano: 14, peso: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _OpcionCuenta extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback alPulsar;

  const _OpcionCuenta({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.alPulsar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Semantics(
      button: true,
      label: titulo,
      child: InkWell(
        onTap: alPulsar,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Icon(icono, color: tokens.accion),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: textoMass(tamano: 15, peso: FontWeight.w800),
                    ),
                    Text(
                      detalle,
                      style: textoMass(tamano: 12, color: tokens.tintaSuave),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: tokens.tintaSuave),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccionFoto extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final bool activo;
  final bool peligro;
  final VoidCallback alPulsar;

  const _AccionFoto({
    required this.icono,
    required this.etiqueta,
    required this.activo,
    required this.alPulsar,
    this.peligro = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final color = peligro ? tokens.error : tokens.accion;
    return OutlinedButton.icon(
      onPressed: activo ? alPulsar : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(48, 48),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      icon: Icon(icono, size: 18),
      label: Text(etiqueta),
    );
  }
}
