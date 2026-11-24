import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/inicio/inicio_screen.dart';
import 'package:flutter_application_1/screens/sensores/sensores_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SensoresScreen muestra los 4 sensores en tiempo real', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: SensoresScreen()));
    await tester.pump();

    expect(find.text('Sensores inteligentes'), findsOneWidget);
    expect(find.text('Nivel'), findsOneWidget);
    expect(find.text('Acelerómetro'), findsOneWidget);
    expect(find.text('Aceleración lineal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('InicioScreen muestra paneles visuales y cuadros Aprende Mass', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    int? destino;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InicioScreen(
            onCambiarPestana: (i) => destino = i,
            mostrarAlquiler: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Compra por categoría'), findsOneWidget);
    expect(find.text('Explora nuestros productos'), findsOneWidget);
    expect(find.text('Aprende Mass'), findsOneWidget);
    expect(find.text('Almuerzos con arroz'), findsOneWidget);
    expect(find.text('+900'), findsNothing);
    expect(find.text('Escáner'), findsOneWidget);
    expect(find.text('Delivery'), findsOneWidget);

    await tester.tap(find.text('Ver productos'));
    await tester.pumpAndSettle();
    expect(destino, 1);
    expect(tester.takeException(), isNull);
  });
}
