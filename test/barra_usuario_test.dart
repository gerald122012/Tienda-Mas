import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/usuario.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('el icono sustituye a INGRESAR y abre el acceso', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(actions: [BotonCuentaAppBar(usuario: null)]),
        ),
      ),
    );

    expect(find.text('INGRESAR'), findsNothing);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    expect(find.byTooltip('Ingresar'), findsOneWidget);

    await tester.tap(find.byTooltip('Ingresar'));
    await tester.pumpAndSettle();

    expect(find.text('Inicia sesión'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsNothing);
  });

  testWidgets('la sesión activa abre el perfil desde el mismo icono', (
    tester,
  ) async {
    const usuario = Usuario(
      nombre: 'Ana Prueba',
      correo: 'ana@ejemplo.com',
      rol: Rol.cliente,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(actions: [BotonCuentaAppBar(usuario: usuario)]),
        ),
      ),
    );

    expect(find.text('INGRESAR'), findsNothing);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    await tester.tap(find.byTooltip('Mi perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('los iconos de la barra caben en 320 px', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: Text('Inicio'),
            actions: [
              IconButton(
                onPressed: null,
                icon: Icon(Icons.qr_code_scanner_rounded),
              ),
              IconButton(
                onPressed: null,
                icon: Icon(Icons.delivery_dining_rounded),
              ),
              BotonCuentaAppBar(usuario: null),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('INGRESAR'), findsNothing);
    expect(find.byTooltip('Ingresar'), findsOneWidget);
  });
}
