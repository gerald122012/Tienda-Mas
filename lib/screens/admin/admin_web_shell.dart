import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../screens/auth/widgets/logo_mass.dart';
import '../../services/auth_service.dart';
import '../../tema/tema_gestion.dart';
import '../../utils/utilidades.dart';
import '../alquila_local/locales_screen.dart';
import '../pedidos/pedidos_screen.dart';
import '../perfil/perfil_screen.dart';
import 'admin_panel_screen.dart';
import 'gestion_cupones.dart';
import 'gestion_productos.dart';
import 'gestion_tiendas.dart';

class _SeccionAdmin {
  final String titulo;
  final String etiqueta;
  final IconData icono;
  final Widget pantalla;

  const _SeccionAdmin(this.titulo, this.etiqueta, this.icono, this.pantalla);
}

class AdminWebShell extends StatefulWidget {
  final Usuario usuario;

  const AdminWebShell({super.key, required this.usuario});

  @override
  State<AdminWebShell> createState() => _AdminWebShellState();
}

class _AdminWebShellState extends State<AdminWebShell> {
  final _andamio = GlobalKey<ScaffoldState>();
  int _indice = 0;
  bool _expandido = true;

  late final List<_SeccionAdmin> _secciones = [
    _SeccionAdmin(
      'Resumen',
      'Resumen',
      Icons.space_dashboard_outlined,
      AdminPanelScreen(onCambiarPestana: _cambiarSeccion),
    ),
    const _SeccionAdmin(
      'Productos',
      'Productos',
      Icons.inventory_2_outlined,
      GestionProductos(),
    ),
    const _SeccionAdmin(
      'Pedidos',
      'Pedidos',
      Icons.receipt_long_outlined,
      PedidosScreen(),
    ),
    const _SeccionAdmin(
      'Tiendas',
      'Tiendas',
      Icons.storefront_outlined,
      GestionTiendas(),
    ),
    const _SeccionAdmin(
      'Cupones',
      'Cupones',
      Icons.confirmation_number_outlined,
      GestionCupones(),
    ),
    const _SeccionAdmin(
      'Locales',
      'Locales',
      Icons.apartment_outlined,
      LocalesScreen(),
    ),
  ];

  void _cambiarSeccion(int nuevo) {
    if (nuevo < 0 || nuevo >= _secciones.length) return;
    setState(() => _indice = nuevo);
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final reducido = MediaQuery.disableAnimationsOf(context);
    final permanente = ancho >= 980;
    final expandido = permanente && _expandido;
    return Scaffold(
      key: _andamio,
      backgroundColor: GestionColores.fondo,
      drawer: permanente
          ? null
          : Drawer(
              width: 280,
              backgroundColor: GestionColores.profundo,
              child: _menu(expandido: true, cerrarAlElegir: true),
            ),
      body: Row(
        children: [
          if (permanente)
            _menu(expandido: expandido, cerrarAlElegir: false, reducido: reducido),
          Expanded(
            child: Column(
              children: [
                _barra(permanente),
                Expanded(
                  child: IndexedStack(
                    index: _indice,
                    children: [for (final seccion in _secciones) seccion.pantalla],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _barra(bool permanente) {
    final usuario = widget.usuario;
    final foto = usuario.fotoBase64;
    final tieneFoto = foto != null && foto.isNotEmpty;
    return Material(
      color: GestionColores.superficie,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: GestionColores.linea)),
        ),
        child: Row(
          children: [
            if (!permanente)
              IconButton(
                tooltip: 'Abrir menú',
                onPressed: () => _andamio.currentState?.openDrawer(),
                icon: const Icon(Icons.menu_rounded, color: GestionColores.profundo),
              ),
            Expanded(
              child: Text(
                _secciones[_indice].titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textoGestion(
                  tamano: 20,
                  peso: FontWeight.w800,
                  color: GestionColores.profundo,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    usuario.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textoGestion(peso: FontWeight.w800),
                  ),
                  Text(
                    usuario.correo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textoGestion(tamano: 12, color: GestionColores.tintaSuave),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            PopupMenuButton<String>(
              tooltip: 'Cuenta de ${usuario.nombre}',
              onSelected: (accion) {
                if (accion == 'perfil') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PerfilScreen()),
                  );
                } else if (accion == 'salir') {
                  AuthService.instance.cerrarSesion();
                }
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: GestionColores.profundo,
                foregroundColor: GestionColores.sello,
                backgroundImage: tieneFoto ? MemoryImage(base64Decode(foto)) : null,
                child: tieneFoto
                    ? null
                    : Text(
                        _iniciales(usuario.nombre),
                        style: textoGestion(
                          tamano: 12,
                          peso: FontWeight.w800,
                          color: GestionColores.sello,
                        ),
                      ),
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    '${usuario.nombre}\nAdministrador',
                    style: textoGestion(peso: FontWeight.w700),
                  ),
                ),
                const PopupMenuItem(value: 'perfil', child: Text('Mi perfil')),
                const PopupMenuItem(value: 'salir', child: Text('Cerrar sesión')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _menu({
    required bool expandido,
    required bool cerrarAlElegir,
    bool reducido = false,
  }) {
    return AnimatedContainer(
      duration: reducido ? Duration.zero : const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: expandido ? 264 : 84,
      color: GestionColores.profundo,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(expandido ? 16 : 12, 18, expandido ? 16 : 12, 8),
              child: Column(
                crossAxisAlignment: expandido
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: LogoMass(alto: expandido ? 34 : 26),
                  ),
                  if (expandido) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Gestión empresarial',
                      style: textoGestion(
                        tamano: 13,
                        peso: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'v$kAppVersion',
                      style: textoGestion(
                        tamano: 12,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  for (var i = 0; i < _secciones.length; i++)
                    _destino(i, expandido, cerrarAlElegir),
                ],
              ),
            ),
            if (!cerrarAlElegir)
              Align(
                alignment: expandido ? Alignment.centerRight : Alignment.center,
                child: IconButton(
                  tooltip: expandido ? 'Contraer menú' : 'Expandir menú',
                  onPressed: () => setState(() => _expandido = !_expandido),
                  icon: Icon(
                    expandido ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _destino(int indice, bool expandido, bool cerrarAlElegir) {
    final seccion = _secciones[indice];
    final activo = indice == _indice;
    final destino = Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
          color: activo ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _cambiarSeccion(indice);
              if (cerrarAlElegir) _andamio.currentState?.closeDrawer();
            },
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 22,
                    margin: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                      color: activo ? GestionColores.sello : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    seccion.icono,
                    size: 22,
                    color: activo ? GestionColores.sello : Colors.white.withValues(alpha: 0.82),
                  ),
                  if (expandido) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        seccion.etiqueta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textoGestion(
                          peso: activo ? FontWeight.w800 : FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
    );
    if (expandido) return destino;
    return Tooltip(message: seccion.etiqueta, child: destino);
  }

  String _iniciales(String nombre) {
    final partes = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .take(2)
        .map((parte) => parte[0].toUpperCase());
    final texto = partes.join();
    return texto.isEmpty ? 'A' : texto;
  }
}
