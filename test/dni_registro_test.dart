import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/auth/login_screen.dart';
import 'package:flutter_application_1/screens/auth/widgets/logo_mass.dart';
import 'package:flutter_application_1/screens/auth/widgets/nombre_consultado.dart';
import 'package:flutter_application_1/services/dni_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'la consulta envía ocho dígitos como texto y no llama a API Perú',
    () async {
      late Uri uri;
      late String cuerpo;
      final servicio = DniService(
        cliente: MockClient((solicitud) async {
          uri = solicitud.url;
          cuerpo = solicitud.body;
          return http.Response(
            jsonEncode({
              'nombres': 'ANA',
              'apellidoPaterno': 'QUISPE',
              'apellidoMaterno': 'GARCIA',
              'codVerifica': '9',
              'simulado': true,
            }),
            200,
          );
        }),
      );

      final resultado = await servicio.consultar('00000001');

      expect(cuerpo, '{"dni":"00000001"}');
      expect(uri.path, '/api/dni/consultar');
      expect(uri.host, isNot('dniruc.apisperu.com'));
      expect(resultado.nombreCompleto, 'ANA QUISPE GARCIA');
      expect(resultado.simulado, isTrue);
    },
  );

  test(
    'traduce DNI no encontrado, respuesta incorrecta y error HTTP',
    () async {
      Future<void> esperar(int estado, String cuerpo, String fragmento) async {
        final servicio = DniService(
          cliente: MockClient((_) async => http.Response(cuerpo, estado)),
        );
        expect(
          () => servicio.consultar('12345678'),
          throwsA(
            isA<DniConsultaException>().having(
              (error) => error.mensaje,
              'mensaje',
              contains(fragmento),
            ),
          ),
        );
      }

      await esperar(
        404,
        jsonEncode({'error': 'No se encontró información para ese DNI.'}),
        'No se encontró',
      );
      await esperar(200, jsonEncode({'nombres': 'ANA'}), 'no está disponible');
      await esperar(
        500,
        jsonEncode({'error': 'fallo interno'}),
        'no está disponible',
      );
    },
  );

  test('rechaza DNI incompleto o inválido sin hacer una solicitud', () async {
    var llamadas = 0;
    final servicio = DniService(
      cliente: MockClient((_) async {
        llamadas += 1;
        return http.Response('{}', 200);
      }),
    );

    expect(
      () => servicio.consultar('1234'),
      throwsA(isA<DniConsultaException>()),
    );
    expect(
      () => servicio.consultar('1234567A'),
      throwsA(isA<DniConsultaException>()),
    );
    expect(llamadas, 0);
  });

  test('informa cuando se agota el tiempo de espera', () async {
    final servicio = DniService(
      tiempoLimite: const Duration(milliseconds: 20),
      cliente: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        return http.Response('{}', 200);
      }),
    );

    expect(
      () => servicio.consultar('12345678'),
      throwsA(
        isA<DniConsultaException>().having(
          (error) => error.mensaje,
          'mensaje',
          contains('no está disponible'),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });

  testWidgets(
    'el inicio de sesión muestra el logotipo y el admin conserva su acceso',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(LogoMass), findsOneWidget);
      expect(find.text('Inicia sesión'), findsOneWidget);
      expect(find.text('CONSULTAR DNI'), findsNothing);
      expect(find.text('INGRESAR'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen(soloAdmin: true)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LogoMass), findsOneWidget);
      expect(find.text('CONSULTAR DNI'), findsNothing);
      expect(find.text('INGRESAR AL PANEL ADMIN'), findsOneWidget);
      expect(find.text('Crear cuenta'), findsNothing);
    },
  );

  testWidgets('no consulta sola y el nombre aparece al presionar el botón', (
    tester,
  ) async {
    var llamadas = 0;
    String? enviado;
    await _abrirRegistro(
      tester,
      _servicio(
        espera: const Duration(milliseconds: 200),
        alLlamar: (dni) {
          llamadas += 1;
          enviado = dni;
        },
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), '1234567');
    await tester.pump(const Duration(milliseconds: 700));
    expect(llamadas, 0);
    expect(_botonConsultar(tester).onPressed, isNull);
    expect(find.text('Nombre completo'), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(0), '12345678');
    await tester.pump(const Duration(seconds: 1));
    expect(llamadas, 0);
    expect(find.text('Consultando'), findsNothing);
    expect(find.text('Nombre completo'), findsNothing);

    await tester.tap(find.text('CONSULTAR DNI'));
    await tester.pump();
    expect(find.text('Consultando'), findsOneWidget);
    await tester.tap(find.text('Consultando'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(llamadas, 1);
    expect(enviado, '12345678');
    expect(find.text('MARIA PRUEBA DEMO'), findsOneWidget);
    expect(find.text('Nombre completo'), findsOneWidget);
    expect(find.byType(NombreConsultado), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NombreConsultado),
        matching: find.byType(TextField),
      ),
      findsNothing,
    );
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(
      find.text('Dato de prueba. No permite crear una cuenta real.'),
      findsOneWidget,
    );
    expect(_botonCrear(tester).onPressed, isNull);
    expect(find.textContaining('Registrar manualmente'), findsNothing);
  });

  testWidgets(
    'cambiar el DNI borra el nombre y descarta la respuesta anterior',
    (tester) async {
      var llamadas = 0;
      await _abrirRegistro(
        tester,
        _servicio(
          espera: const Duration(milliseconds: 300),
          alLlamar: (_) => llamadas += 1,
        ),
      );
      await tester.enterText(find.byType(TextFormField).at(0), '12345678');
      await tester.pump();
      await tester.tap(find.text('CONSULTAR DNI'));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(0), '1234567');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('MARIA PRUEBA DEMO'), findsNothing);
      expect(find.text('Nombre completo'), findsNothing);
      expect(llamadas, 1);
      expect(_botonCrear(tester).onPressed, isNull);
    },
  );

  testWidgets(
    'un fallo bloquea la cuenta y el reintento no habilita el dato simulado',
    (tester) async {
      var llamadas = 0;
      final servicio = DniService(
        cliente: MockClient((_) async {
          llamadas += 1;
          if (llamadas == 1) throw http.ClientException('sin red');
          return http.Response(
            jsonEncode({
              'nombres': 'MARIA',
              'apellidoPaterno': 'PRUEBA',
              'apellidoMaterno': 'DEMO',
              'simulado': true,
            }),
            200,
          );
        }),
      );
      await _abrirRegistro(tester, servicio);
      await tester.enterText(find.byType(TextFormField).at(0), '12345678');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'ana@ejemplo.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'clave123');
      await tester.pump();
      await tester.tap(find.text('CONSULTAR DNI'));
      await tester.pumpAndSettle();

      expect(find.textContaining('no está disponible'), findsOneWidget);
      expect(find.text('Nombre completo'), findsNothing);
      expect(find.textContaining('Registrar manualmente'), findsNothing);
      expect(_botonCrear(tester).onPressed, isNull);

      await tester.ensureVisible(find.text('Reintentar'));
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('MARIA PRUEBA DEMO'), findsOneWidget);
      expect(_botonCrear(tester).onPressed, isNull);
      expect(llamadas, 2);
    },
  );

  testWidgets('una consulta real habilita la cuenta y conserva los ceros', (
    tester,
  ) async {
    String? enviado;
    await _abrirRegistro(
      tester,
      _servicio(simulado: false, alLlamar: (dni) => enviado = dni),
    );
    await tester.enterText(find.byType(TextFormField).at(0), '00000001');
    await tester.pump();
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(0))
          .controller!
          .text,
      '00000001',
    );
    expect(_botonCrear(tester).onPressed, isNull);

    await tester.tap(find.text('CONSULTAR DNI'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), 'ana@ejemplo.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'clave123');
    await tester.pump();

    expect(enviado, '00000001');
    expect(find.text('MARIA PRUEBA DEMO'), findsOneWidget);
    expect(find.text('Datos obtenidos mediante consulta de DNI.'), findsOneWidget);
    expect(_botonCrear(tester).onPressed, isNotNull);
  });

  testWidgets(
    'valida correo y contraseña sin desbordar en pantallas pequeñas',
    (tester) async {
      var llamadas = 0;
      final servicio = _servicio(
        simulado: false,
        alLlamar: (_) => llamadas += 1,
        nombre: 'MARIA DE LOS ANGELES PRUEBA DEMO DE UN NOMBRE EXTENSO',
      );
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _abrirRegistro(tester, servicio);
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextFormField).at(0), '1234');
      await tester.pump(const Duration(milliseconds: 700));
      expect(llamadas, 0);
      expect(_botonConsultar(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextFormField).at(0), '12345678');
    await tester.pump();
    expect(_botonConsultar(tester).onPressed, isNotNull);
    await tester.ensureVisible(find.text('CONSULTAR DNI'));
    await tester.tap(find.text('CONSULTAR DNI'));
    await tester.pumpAndSettle();
    expect(llamadas, 1);
    expect(
      find.text('MARIA DE LOS ANGELES PRUEBA DEMO DE UN NOMBRE EXTENSO'),
      findsOneWidget,
    );

      await tester.enterText(find.byType(TextFormField).at(1), 'correo-malo');
      await tester.enterText(find.byType(TextFormField).at(2), '123');
      await tester.pump();

      expect(find.text('Ingresa un correo válido'), findsOneWidget);
      expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
      expect(_botonCrear(tester).onPressed, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('el teclado abierto no desborda el registro', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(viewInsets: const EdgeInsets.only(bottom: 280)),
            child: child!,
          );
        },
        home: LoginScreen(servicioDni: _servicio()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('CONSULTAR DNI'), findsOneWidget);
  });

  testWidgets('sin servicio de DNI se puede crear la cuenta con el nombre a mano', (
    tester,
  ) async {
    final servicio = DniService(
      cliente: MockClient((_) async => throw http.ClientException('sin red')),
    );
    await _abrirRegistro(tester, servicio);
    await tester.enterText(find.byType(TextFormField).at(0), '12345678');
    await tester.pump();
    await tester.tap(find.text('CONSULTAR DNI'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no está disponible'), findsOneWidget);

    await tester.ensureVisible(find.text('Escribir mi nombre a mano'));
    await tester.tap(find.text('Escribir mi nombre a mano'));
    await tester.pumpAndSettle();
    final nombre = find.byKey(const Key('nombre-manual'));
    expect(nombre, findsOneWidget);

    await tester.enterText(
      find.descendant(of: nombre, matching: find.byType(TextFormField)),
      'Ana',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'ana@ejemplo.com');
    await tester.enterText(find.byType(TextFormField).at(3), 'clave123');
    await tester.pump();
    expect(_botonCrear(tester).onPressed, isNull);

    await tester.enterText(
      find.descendant(of: nombre, matching: find.byType(TextFormField)),
      'Ana Torres Ruiz',
    );
    await tester.pump();
    expect(_botonCrear(tester).onPressed, isNotNull);
  });
}

OutlinedButton _botonConsultar(WidgetTester tester) {
  return tester.widget<OutlinedButton>(
    find.widgetWithText(OutlinedButton, 'CONSULTAR DNI'),
  );
}

FilledButton _botonCrear(WidgetTester tester) {
  return tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'CREAR CUENTA'),
  );
}

DniService _servicio({
  Duration espera = Duration.zero,
  void Function(String dni)? alLlamar,
  bool simulado = true,
  String nombre = 'MARIA PRUEBA DEMO',
}) {
  final partes = nombre.split(' ');
  return DniService(
    tiempoLimite: const Duration(seconds: 2),
    cliente: MockClient((solicitud) async {
      final cuerpo = jsonDecode(solicitud.body) as Map<String, dynamic>;
      alLlamar?.call(cuerpo['dni'].toString());
      if (espera > Duration.zero) await Future<void>.delayed(espera);
      return http.Response(
        jsonEncode({
          'nombres': partes.first,
          'apellidoPaterno': partes.length > 1 ? partes[1] : 'PRUEBA',
          'apellidoMaterno': partes.length > 2
              ? partes.skip(2).join(' ')
              : 'DEMO',
          'simulado': simulado,
        }),
        200,
      );
    }),
  );
}

Future<void> _abrirRegistro(WidgetTester tester, DniService servicio) async {
  await tester.pumpWidget(
    MaterialApp(home: LoginScreen(servicioDni: servicio)),
  );
  await tester.pumpAndSettle();
  expect(find.byType(LogoMass), findsOneWidget);
  await tester.ensureVisible(find.text('Crear cuenta'));
  await tester.tap(find.text('Crear cuenta'));
  await tester.pumpAndSettle();
  expect(find.text('CONSULTAR DNI'), findsOneWidget);
  expect(find.text('Nombre completo'), findsNothing);
  expect(find.textContaining('manualmente'), findsNothing);
}
