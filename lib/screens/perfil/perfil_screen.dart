import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../main.dart';
import '../../services/auth_service.dart';
import '../../services/permisos_service.dart';
import '../../utils/utilidades.dart';
import '../escaner/escaner_herramientas_screen.dart';
import '../pedidos/historial_compras_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _picker = ImagePicker();
  bool _procesando = false;

  Future<void> _cambiarFoto(ImageSource origen) async {
    if (_procesando) return;
    if (origen == ImageSource.camera) {
      final permitido = await PermisosService.solicitarPermisoCamara(
        context,
        motivo: 'tomar tu foto de perfil',
      );
      if (!permitido || !mounted) return;
    }

    setState(() => _procesando = true);
    try {
      final archivo = await _picker.pickImage(
        source: origen,
        maxWidth: 480,
        maxHeight: 480,
        imageQuality: 72,
      );
      if (archivo == null) return;
      final bytes = await archivo.readAsBytes();
      final b64 = base64Encode(bytes);
      await AuthService.instance.actualizarFotoPerfil(b64);
      if (mounted) {
        mostrarMensaje(context, 'Foto de perfil actualizada correctamente.');
      }
    } catch (_) {
      if (mounted) {
        mostrarMensaje(
          context,
          'No se pudo acceder a la cámara o galería en este dispositivo.',
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _quitarFoto() async {
    await AuthService.instance.actualizarFotoPerfil(null);
    if (mounted) mostrarMensaje(context, 'Foto de perfil eliminada.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ListenableBuilder(
        listenable: AuthService.instance,
        builder: (context, _) {
          final usuario = AuthService.instance.usuario;
          if (usuario == null) {
            return const Center(
              child: Text('Inicia sesión para gestionar tu perfil.'),
            );
          }
          final tieneFoto =
              usuario.fotoBase64 != null && usuario.fotoBase64!.isNotEmpty;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 56,
                            backgroundColor: kMassYellow,
                            foregroundColor: kMassBlue,
                            backgroundImage: tieneFoto
                                ? MemoryImage(base64Decode(usuario.fotoBase64!))
                                : null,
                            child: !tieneFoto
                                ? Text(
                                    usuario.nombre.isNotEmpty
                                        ? usuario.nombre[0].toUpperCase()
                                        : 'M',
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  )
                                : null,
                          ),
                          Material(
                            color: kMassBlue,
                            shape: const CircleBorder(),
                            child: IconButton(
                              tooltip: 'Tomar foto con cámara',
                              onPressed: _procesando
                                  ? null
                                  : () => _cambiarFoto(ImageSource.camera),
                              icon: _procesando
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: kMassYellow,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      color: kMassYellow,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        usuario.nombre,
                        style: const TextStyle(
                          color: kMassBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        usuario.correo,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        avatar: Icon(
                          usuario.esAdmin
                              ? Icons.admin_panel_settings
                              : Icons.person,
                          size: 18,
                          color: kMassBlue,
                        ),
                        label: Text(
                          usuario.esAdmin ? 'Administrador' : 'Cliente Mass',
                          style: const TextStyle(
                            color: kMassBlue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        backgroundColor: kMassMint,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: _procesando
                                ? null
                                : () => _cambiarFoto(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Tomar foto'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _procesando
                                ? null
                                : () => _cambiarFoto(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Galería'),
                          ),
                          if (tieneFoto)
                            TextButton.icon(
                              onPressed: _procesando ? null : _quitarFoto,
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              label: const Text(
                                'Quitar',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    if (!usuario.esAdmin)
                      ListTile(
                        leading: const Icon(
                          Icons.receipt_long,
                          color: kMassBlue,
                        ),
                        title: const Text(
                          'Historial de compras',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          'Consulta tus pedidos y fotos de recojo',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Scaffold(
                              body: HistorialComprasScreen(mostrarAppBar: true),
                            ),
                          ),
                        ),
                      ),
                    ListTile(
                      leading: const Icon(
                        Icons.qr_code_scanner,
                        color: kMassBlue,
                      ),
                      title: const Text(
                        'Escáner QR, Barras y Archivos',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: const Text(
                        'Escanea cupones, productos o sube comprobantes',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EscanerHerramientasScreen(),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    const ListTile(
                      leading: Icon(Icons.info_outline, color: kMassBlue),
                      title: Text(
                        'Versión de la aplicación',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      trailing: Text(
                        'v$kAppVersion ($kAppBuild)',
                        style: TextStyle(
                          color: kMassBlue,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  await AuthService.instance.cerrarSesion();
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.logout),
                label: const Text('CERRAR SESIÓN'),
              ),
            ],
          );
        },
      ),
    );
  }
}
