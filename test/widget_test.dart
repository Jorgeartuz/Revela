import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:revela/app.dart';
import 'package:revela/core/network/api_client.dart';
import 'package:revela/features/auth/data/auth_repository.dart';
import 'package:revela/features/home/data/dashboard_repository.dart';

Future<void> enterCredentials(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('username')), 'usuario');
  await tester.enterText(find.byKey(const Key('password')), 'clave');
  await tester.ensureVisible(find.text('Iniciar Sesion'));
  await tester.tap(find.text('Iniciar Sesion'));
}

void main() {
  testWidgets(
    'Valida campos sin llamar a la API y permite mostrar contraseña',
    (tester) async {
      var requests = 0;
      final api = ApiClient(
        baseUrl: Uri.parse('https://example.com'),
        client: MockClient((_) async {
          requests++;
          return http.Response('', 401);
        }),
      );
      addTearDown(api.close);
      await tester.pumpWidget(
        RevelaApp(
          authRepository: AuthRepository(api),
          dashboardRepositoryFactory: (session) =>
              DashboardRepository(api, session),
        ),
      );
      expect(find.text('Iniciar Sesion'), findsOneWidget);
      await tester.tap(find.text('Iniciar Sesion'));
      await tester.pumpAndSettle();
      expect(find.text('Ingresa tu correo o usuario'), findsOneWidget);
      expect(find.text('Ingresa tu contraseña'), findsOneWidget);
      expect(requests, 0);
      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pump();
      expect(
        tester
            .widgetList<EditableText>(find.byType(EditableText))
            .last
            .obscureText,
        isFalse,
      );
    },
  );

  testWidgets('Muestra carga, impide doble envío y entra y sale de la sesión', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    var requests = 0;
    final api = ApiClient(
      baseUrl: Uri.parse('https://example.com'),
      client: MockClient((request) {
        if (request.method == 'GET') {
          return Future.value(http.Response('{"success":true,"data":[]}', 200));
        }
        requests++;
        return response.future;
      }),
    );
    addTearDown(api.close);
    await tester.pumpWidget(
      RevelaApp(
        authRepository: AuthRepository(api),
        dashboardRepositoryFactory: (session) =>
            DashboardRepository(api, session),
      ),
    );
    await enterCredentials(tester);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(requests, 1);
    response.complete(
      http.Response(
        jsonEncode({
          'accessToken':
              'header.${base64Url.encode(utf8.encode(jsonEncode({'http://schemas.microsoft.com/ws/2008/06/identity/claims/role': 'Gestor'}))).replaceAll('=', '')}.signature',
          'tokenType': 'bearer',
          'expiresIn': 3600,
          'empresaId': 1,
          'empresaNombre': 'Centro de prueba',
        }),
        200,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Accesos rápidos'), findsOneWidget);
    expect(find.text('Reservas hoy'), findsOneWidget);
    expect(find.text('Has iniciado sesión correctamente.'), findsNothing);
    expect(find.byKey(const Key('password')), findsNothing);
    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar Sesion'), findsOneWidget);
    expect(
      tester
          .widgetList<EditableText>(find.byType(EditableText))
          .last
          .controller
          .text,
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Muestra rechazo de credenciales y permite reintentar', (
    tester,
  ) async {
    final api = ApiClient(
      baseUrl: Uri.parse('https://example.com'),
      client: MockClient((_) async => http.Response('', 401)),
    );
    addTearDown(api.close);
    await tester.pumpWidget(
      RevelaApp(
        authRepository: AuthRepository(api),
        dashboardRepositoryFactory: (session) =>
            DashboardRepository(api, session),
      ),
    );
    await enterCredentials(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('El usuario o la contraseña no son correctos.'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });
}
