// Test básico para el Sistema de Inventarios Telmex
//
// Este test verifica que la aplicación se inicie correctamente
// y que la pantalla de login se muestre.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_telmex/main.dart';

void main() {
  testWidgets('Sistema Telmex - Pantalla de Login', (WidgetTester tester) async {
    // Construir la aplicación y activar un frame
    await tester.pumpWidget(const MyApp());

    // Verificar que la pantalla de login se muestre
    expect(find.text('Sistema Telmex'), findsOneWidget);
    expect(find.text('Nombre de Usuario'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });

  testWidgets('Sistema Telmex - Campos de entrada', (WidgetTester tester) async {
    // Construir la aplicación
    await tester.pumpWidget(const MyApp());

    // Verificar que los campos de entrada estén presentes
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
