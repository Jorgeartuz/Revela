import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revela/app.dart';

void main() {
  testWidgets('Impide acceso vacío y no simula autenticación', (tester) async {
    await tester.pumpWidget(const RevelaApp());
    await tester.tap(find.text('Iniciar Sesion'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa tu correo o usuario'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('username')), 'usuario');
    await tester.enterText(find.byKey(const Key('password')), 'clave');
    await tester.ensureVisible(find.text('Iniciar Sesion'));
    await tester.tap(find.text('Iniciar Sesion'));
    await tester.pumpAndSettle();
    expect(find.text('Conexión pendiente'), findsOneWidget);
  });

  testWidgets('Permite alternar la visibilidad de la contraseña', (
    tester,
  ) async {
    await tester.pumpWidget(const RevelaApp());
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
    final input = tester.widget<TextFormField>(
      find.byKey(const Key('password')),
    );
    expect(input, isNotNull);
    expect(
      tester
          .widgetList<EditableText>(find.byType(EditableText))
          .last
          .obscureText,
      isFalse,
    );
  });
}
