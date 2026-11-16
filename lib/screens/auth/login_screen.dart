import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/auth_service.dart';
import '../../widgets/aparecer.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  bool _ocultar = true;
  String? _error;
  bool _registro = false;
  bool _cargando = false;

  @override
  void dispose() {
    _nombre.dispose();
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
    final auth = AuthService.instance;
    final error = _registro
        ? await auth.registrar(_nombre.text, _correo.text, _clave.text)
        : await auth.iniciarSesion(_correo.text, _clave.text);
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
    return Scaffold(
      backgroundColor: kMassBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('', style: TextStyle(fontSize: 1)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Aparecer(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: kMassYellow,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'Mass',
                                style: TextStyle(
                                  color: kMassBlue,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Lleva Mass pagando Menos',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: kMassBlue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 20),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            child: _registro
                                ? Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: TextFormField(
                                      controller: _nombre,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      decoration: const InputDecoration(
                                        labelText: 'Nombre completo',
                                        prefixIcon: Icon(Icons.person_outline),
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().length < 2)
                                          ? 'Ingresa tu nombre'
                                          : null,
                                    ),
                                  )
                                : const SizedBox(width: double.infinity),
                          ),
                          TextFormField(
                            controller: _correo,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Correo',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Ingresa tu correo'
                                : null,
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
                                tooltip: _ocultar ? 'Mostrar' : 'Ocultar',
                                icon: Icon(
                                  _ocultar
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () =>
                                    setState(() => _ocultar = !_ocultar),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Ingresa tu contraseña'
                                : (_registro && v.length < 6)
                                ? 'Mínimo 6 caracteres'
                                : null,
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _error == null
                                ? const SizedBox(width: double.infinity)
                                : Padding(
                                    key: ValueKey(_error),
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.red.shade800,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _cargando ? null : _ingresar,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _cargando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(_registro ? 'CREAR CUENTA' : 'INGRESAR'),
                          ),
                          TextButton(
                            onPressed: _cargando
                                ? null
                                : () => setState(() {
                                    _registro = !_registro;
                                    _error = null;
                                  }),
                            child: Text(
                              _registro
                                  ? 'Ya tengo cuenta · Ingresar'
                                  : '¿Eres nuevo? Crea tu cuenta',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
