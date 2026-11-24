import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../main.dart';
import '../../models/usuario.dart';
import '../../services/auth_service.dart';
import '../../services/dni_service.dart';
import '../../utils/utilidades.dart';
import '../../utils/validaciones.dart';
import 'widgets/boton_acceso.dart';
import 'widgets/campo_acceso.dart';
import 'widgets/escenario_acceso.dart';
import 'widgets/nombre_consultado.dart';
import 'widgets/tema_acceso.dart';

class AccesoCliente extends StatefulWidget {
  final DniService? servicioDni;

  const AccesoCliente({super.key, this.servicioDni});

  @override
  State<AccesoCliente> createState() => _AccesoClienteState();
}

class _AccesoClienteState extends State<AccesoCliente> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final _dni = TextEditingController();
  final _nombreManual = TextEditingController();
  late final DniService _servicioDni;
  bool _ocultar = true;
  bool _registro = false;
  bool _cargando = false;
  bool _consultando = false;
  int _consultaId = 0;
  String? _dniResuelto;
  String? _nombre;
  bool _simulado = false;
  bool _manual = false;
  String? _error;
  String? _errorDni;

  @override
  void initState() {
    super.initState();
    _servicioDni = widget.servicioDni ?? DniService();
    _correo.addListener(_refrescar);
    _clave.addListener(_refrescar);
    _nombreManual.addListener(_refrescar);
  }

  @override
  void dispose() {
    _correo.removeListener(_refrescar);
    _clave.removeListener(_refrescar);
    _correo.dispose();
    _clave.dispose();
    _dni.dispose();
    _nombreManual.removeListener(_refrescar);
    _nombreManual.dispose();
    if (widget.servicioDni == null) _servicioDni.close();
    super.dispose();
  }

  void _refrescar() {
    if (mounted) setState(() {});
  }

  bool get _dniActualValido => RegExp(r'^\d{8}$').hasMatch(_dni.text.trim());

  bool get _consultaVigente {
    final nombre = _nombre?.trim() ?? '';
    return nombre.length >= 2 && !_simulado && _dniResuelto == _dni.text.trim();
  }

  // Sin servicio de DNI el cliente escribe su nombre como figura en su DNI.
  bool get _manualListo =>
      _manual && _dniActualValido && nombreCompleto(_nombreManual.text) == null;

  bool get _puedeConsultar {
    return _dniActualValido &&
        !_consultando &&
        !_cargando &&
        _dniResuelto != _dni.text.trim();
  }

  bool get _puedeCrear {
    return (_consultaVigente || _manualListo) &&
        correoCliente(_correo.text) == null &&
        claveCliente(_clave.text, registro: true) == null &&
        !_consultando &&
        !_cargando;
  }

  void _cambiarModo() {
    _consultaId++;
    setState(() {
      _registro = !_registro;
      _manual = false;
      _consultando = false;
      _error = null;
      _errorDni = null;
    });
  }

  void _alCambiarDni(String _) {
    _consultaId++;
    setState(() {
      _consultando = false;
      _nombre = null;
      _simulado = false;
      _dniResuelto = null;
      _errorDni = null;
    });
  }

  Future<void> _consultar() async {
    final dni = _dni.text.trim();
    if (!_dniActualValido || _consultando || _cargando) return;
    if (_dniResuelto == dni && _nombre != null) return;
    final id = ++_consultaId;
    setState(() {
      _consultando = true;
      _error = null;
      _errorDni = null;
      _nombre = null;
      _simulado = false;
      _dniResuelto = null;
    });
    try {
      final resultado = await _servicioDni.consultar(dni);
      if (!mounted || id != _consultaId || _dni.text.trim() != dni) return;
      setState(() {
        _nombre = resultado.nombreCompleto;
        _simulado = resultado.simulado;
        _dniResuelto = dni;
        _consultando = false;
      });
    } on DniConsultaException catch (error) {
      _falloConsulta(id, dni, error.mensaje);
    } catch (_) {
      _falloConsulta(id, dni, 'El servicio de consulta no está disponible.');
    }
  }

  void _falloConsulta(int id, String dni, String mensaje) {
    if (!mounted || id != _consultaId || _dni.text.trim() != dni) return;
    setState(() {
      _consultando = false;
      _nombre = null;
      _simulado = false;
      _dniResuelto = null;
      _errorDni = mensaje;
    });
  }

  Future<void> _ingresar() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_cargando) return;
    if (_registro) {
      if (!_puedeCrear) return;
    } else if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    final auth = AuthService.instance;
    final error = _registro
        ? await auth.registrar(
            (_manualListo && !_consultaVigente ? _nombreManual.text : _nombre!)
                .trim(),
            _correo.text,
            _clave.text,
          )
        : await auth.iniciarSesion(
            _correo.text,
            _clave.text,
            rolRequerido: Rol.cliente,
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
    final reducir = MediaQuery.disableAnimationsOf(context);
    final teclado = MediaQuery.viewInsetsOf(context).bottom > 0;
    final corto = MediaQuery.sizeOf(context).height < 700;
    final duracion = reducir
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Manrope'),
        ),
        child: Scaffold(
          backgroundColor: kAzulProfundo,
          resizeToAvoidBottomInset: true,
          body: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: EscenarioAcceso(
              compacto: teclado || corto,
              titulo: _registro ? 'Crea tu cuenta' : 'Bienvenido',
              mensaje: _registro
                  ? 'Consulta tu DNI y compra más rápido.'
                  : 'Entra para comprar en tu tienda Mass.',
              formulario: Form(key: _formKey, child: _contenido(duracion)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenido(Duration duracion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSize(
          duration: duracion,
          alignment: Alignment.topCenter,
          child: _registro ? _bloquePersonal(duracion) : _bloqueBienvenida(),
        ),
        _campoCorreo(),
        const SizedBox(height: 12),
        _campoClave(),
        _avisoError(duracion),
        const SizedBox(height: 16),
        BotonAcceso(
          texto: _registro ? 'CREAR CUENTA' : 'INGRESAR',
          icono: _registro
              ? Icons.person_add_alt_1_outlined
              : Icons.login_rounded,
          cargando: _cargando,
          alPresionar: _registro ? (_puedeCrear ? _ingresar : null) : _ingresar,
        ),
        const SizedBox(height: 20),
        AnimatedSize(
          duration: duracion,
          alignment: Alignment.topCenter,
          child: _registro ? _pieRegistro() : _pieIngreso(),
        ),
      ],
    );
  }

  Widget _bloqueBienvenida() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Inicia sesión',
          textAlign: TextAlign.center,
          style: textoAcceso(
            tamano: 22,
            peso: FontWeight.w700,
            color: kMassBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Usa el correo de tu cuenta.',
          textAlign: TextAlign.center,
          style: textoAcceso(color: kTintaSuave),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _bloquePersonal(Duration duracion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _seccion('Datos personales'),
        Text(
          'Consultamos tu nombre para crear la cuenta. No verifica tu identidad y el DNI no se guarda.',
          style: textoAcceso(tamano: 13, color: kTintaSuave),
        ),
        const SizedBox(height: 12),
        CampoAcceso(
          controller: _dni,
          etiqueta: 'DNI',
          icono: Icons.badge_outlined,
          teclado: TextInputType.number,
          longitudMaxima: 8,
          formatos: [FilteringTextInputFormatter.digitsOnly],
          alCambiar: _alCambiarDni,
          validador: documentoValido,
          validacion: AutovalidateMode.onUnfocus,
          ayuda: 'Ocho dígitos numéricos.',
        ),
        const SizedBox(height: 8),
        BotonAcceso(
          texto: 'CONSULTAR DNI',
          icono: Icons.search_rounded,
          contorno: true,
          cargando: _consultando,
          alPresionar: _puedeConsultar ? _consultar : null,
        ),
        _resultadoDni(duracion),
        if (_manual && !_consultaVigente) ...[
          const SizedBox(height: 12),
          CampoAcceso(
            key: const Key('nombre-manual'),
            controller: _nombreManual,
            etiqueta: 'Nombre completo',
            icono: Icons.person_outline_rounded,
            validador: nombreCompleto,
            validacion: AutovalidateMode.onUserInteraction,
            ayuda: 'Escríbelo como figura en tu DNI.',
          ),
        ],
        const SizedBox(height: 20),
        _seccion('Datos de acceso'),
      ],
    );
  }

  Widget _pieIngreso() {
    return Column(
      children: [
        Text(
          '¿Eres cliente nuevo?',
          textAlign: TextAlign.center,
          style: textoAcceso(color: kTintaSuave),
        ),
        TextButton(
          onPressed: _cargando ? null : _cambiarModo,
          child: Text(
            'Crear cuenta',
            style: textoAcceso(
              tamano: 15,
              peso: FontWeight.w700,
              color: kMassBlue,
            ),
          ),
        ),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          key: const Key('ir-pagina-web'),
          onPressed: () => abrirPaginaWeb(context),
          icon: const Icon(Icons.language_rounded, size: 18),
          label: const Text('Ir a la página web Mass'),
        ),
      ],
    );
  }

  Widget _pieRegistro() {
    return TextButton(
      onPressed: _cargando ? null : _cambiarModo,
      child: Text(
        'Ya tengo una cuenta',
        textAlign: TextAlign.center,
        style: textoAcceso(tamano: 14, peso: FontWeight.w700, color: kMassBlue),
      ),
    );
  }

  Widget _campoCorreo() {
    return CampoAcceso(
      controller: _correo,
      etiqueta: 'Correo electrónico',
      icono: Icons.mail_outline_rounded,
      teclado: TextInputType.emailAddress,
      autofill: const [AutofillHints.email],
      validador: correoCliente,
    );
  }

  Widget _campoClave() {
    return CampoAcceso(
      controller: _clave,
      etiqueta: 'Contraseña',
      icono: Icons.lock_outline_rounded,
      oculto: _ocultar,
      accion: TextInputAction.done,
      autofill: [
        _registro ? AutofillHints.newPassword : AutofillHints.password,
      ],
      ayuda: _registro ? 'Usa al menos 6 caracteres.' : null,
      alEnviar: (_) => _ingresar(),
      validador: (valor) => claveCliente(valor, registro: _registro),
      sufijo: IconButton(
        tooltip: _ocultar ? 'Mostrar contraseña' : 'Ocultar contraseña',
        onPressed: () => setState(() => _ocultar = !_ocultar),
        icon: Icon(
          _ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: kMassBlue,
          size: 22,
        ),
      ),
    );
  }

  Widget _seccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: kMassBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            titulo,
            style: textoAcceso(
              tamano: 13,
              peso: FontWeight.w800,
              color: kMassBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avisoError(Duration duracion) {
    return AnimatedSwitcher(
      duration: duracion,
      child: _error == null
          ? const SizedBox(key: ValueKey('sin-error'), width: double.infinity)
          : Container(
              key: ValueKey(_error),
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEC),
                borderRadius: BorderRadius.circular(kRadioAcceso),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: kErrorAcceso,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: textoAcceso(
                        tamano: 13,
                        peso: FontWeight.w700,
                        color: kErrorAcceso,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _resultadoDni(Duration duracion) {
    final Widget contenido;
    if (_nombre != null && _dniResuelto == _dni.text.trim()) {
      contenido = Padding(
        key: const Key('nombre-consultado'),
        padding: const EdgeInsets.only(top: 12),
        child: NombreConsultado(nombre: _nombre!, simulado: _simulado),
      );
    } else if (_errorDni != null) {
      contenido = Padding(
        key: ValueKey(_errorDni),
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: kErrorAcceso, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorDni!,
                    style: textoAcceso(
                      tamano: 13,
                      peso: FontWeight.w700,
                      color: kErrorAcceso,
                    ),
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: _consultando ? null : _consultar,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reintentar'),
                ),
                if (!_manual)
                  TextButton.icon(
                    onPressed: () => setState(() => _manual = true),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Escribir mi nombre a mano'),
                  ),
              ],
            ),
          ],
        ),
      );
    } else {
      contenido = const SizedBox(
        key: ValueKey('dni-vacio'),
        width: double.infinity,
      );
    }

    return AnimatedSize(
      duration: duracion,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(duration: duracion, child: contenido),
    );
  }
}
