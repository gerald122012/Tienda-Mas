import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../services/auth_service.dart';
import '../../tema/tema_gestion.dart';
import '../../utils/utilidades.dart';
import 'widgets/logo_mass.dart';

class AccesoAdmin extends StatefulWidget {
  const AccesoAdmin({super.key});

  @override
  State<AccesoAdmin> createState() => _AccesoAdminState();
}

class _AccesoAdminState extends State<AccesoAdmin> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  bool _ocultar = true;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    if (_cargando || !_formKey.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    final error = await AuthService.instance.iniciarSesion(
      _correo.text,
      _clave.text,
      rolRequerido: Rol.administrador,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _cargando = false;
        _error = error;
      });
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final formulario = _formulario();
    return Scaffold(
      backgroundColor: GestionColores.fondo,
      body: ancho >= 980
          ? Row(
              children: [
                Expanded(child: _marca()),
                Expanded(child: Center(child: formulario)),
              ],
            )
          : SafeArea(
              child: Column(
                children: [
                  _marca(compacta: true),
                  Expanded(child: Center(child: SingleChildScrollView(child: formulario))),
                ],
              ),
            ),
    );
  }

  Widget _marca({bool compacta = false}) {
    return ColoredBox(
      color: GestionColores.profundo,
      child: Padding(
        padding: EdgeInsets.all(compacta ? 24 : 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const LogoMass(alto: 42),
            ),
            const SizedBox(height: 18),
            Text(
              'Mass Gestión Empresarial',
              style: textoGestion(
                tamano: compacta ? 22 : 32,
                peso: FontWeight.w800,
                color: Colors.white,
                alto: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Administración de catálogo, pedidos, tiendas, cupones y locales · v$kAppVersion',
              style: textoGestion(color: Colors.white.withValues(alpha: 0.78)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formulario() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Acceso de administrador',
                style: textoGestion(
                  tamano: 24,
                  peso: FontWeight.w800,
                  color: GestionColores.profundo,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Usa la cuenta autorizada para la gestión. Esta entrada no crea clientes.',
                style: textoGestion(color: GestionColores.tintaSuave),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _correo,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Correo de administrador',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: (valor) =>
                    (valor == null || valor.trim().isEmpty) ? 'Ingresa tu correo' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clave,
                obscureText: _ocultar,
                onFieldSubmitted: (_) => _ingresar(),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _ocultar ? 'Mostrar contraseña' : 'Ocultar contraseña',
                    onPressed: () => setState(() => _ocultar = !_ocultar),
                    icon: Icon(
                      _ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (valor) =>
                    (valor == null || valor.isEmpty) ? 'Ingresa tu contraseña' : null,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: textoGestion(peso: FontWeight.w700, color: GestionColores.error),
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _cargando ? null : _ingresar,
                child: _cargando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('INGRESAR AL PANEL ADMIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
