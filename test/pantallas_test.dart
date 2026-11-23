import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/inicio/inicio_screen.dart';
import 'package:flutter_application_1/screens/sensores/sensores_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SensoresScreen muestra los 4 sensores en tiempo real', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SensoresScreen()));
    await tester.pump();

    expect(find.text('Sensores en Tiempo Real'), findsOneWidget);
    expect(find.text('Nivel e Inclinación'), findsOneWidget);
    expect(find.text('Acelerómetro (con gravedad)'), findsOneWidget);
    expect(find.text('Aceleración Lineal (sin gravedad)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('InicioScreen muestra paneles visuales y cuadros Aprende Mass', (
    tester,
  ) async {
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

    expect(find.text('Accesos rápidos'), findsOneWidget);
    expect(find.text('Productos'), findsWidgets);
    expect(find.text('Ubicación'), findsOneWidget);
    expect(find.text('Mis Compras'), findsOneWidget);
    expect(find.text('Aprende Mass'), findsOneWidget);
    expect(find.text('Almuerzos con arroz'), findsOneWidget);

    await tester.tap(find.text('Ingresar a productos'));
    await tester.pumpAndSettle();
    expect(destino, 1);
    expect(tester.takeException(), isNull);
  });
}
