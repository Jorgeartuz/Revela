import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:revela/core/network/api_client.dart';
import 'package:revela/core/theme/app_theme.dart';
import 'package:revela/features/auth/domain/auth_session.dart';
import 'package:revela/features/auth/domain/account_role.dart';
import 'package:revela/features/home/data/dashboard_repository.dart';
import 'package:revela/features/management/data/management_repository.dart';
import 'package:revela/features/home/presentation/home_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

AuthSession session(String? role) => AuthSession(
  accessToken: 'test',
  expiresAt: DateTime.now().add(const Duration(hours: 1)),
  companyName: 'Prueba',
  companyId: 1,
  role: role,
);

void main() {
  test(
    'Solo Gestor abre la administración; el profesional requiere confirmación',
    () {
      expect(RolePolicy.resolve('Gestor'), AccountRole.administrator);
      expect(RolePolicy.resolve('otro'), AccountRole.unsupported);
      expect(RolePolicy.resolve(null), AccountRole.unsupported);
      expect(RolePolicy.resolve('Profesional'), AccountRole.unsupported);
      expect(
        RolePolicy.resolve('Estilista', professional: 'Estilista'),
        AccountRole.professional,
      );
    },
  );

  for (final width in [320.0, 393.0]) {
    testWidgets('Panel administrativo y navegación sin desbordes a $width px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = ApiClient(
        baseUrl: Uri.parse('https://example.com'),
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer test');
          return http.Response('{"success":true,"data":[]}', 200);
        }),
      );
      addTearDown(api.close);
      final account = session('Gestor');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('es'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('es')],
          home: HomeScreen(
            session: account,
            onLogout: () {},
            onSessionExpired: () {},
            repository: DashboardRepository(api, account),
            managementRepository: ManagementRepository.preview(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Accesos rápidos'), findsOneWidget);
      expect(find.text('Reservas hoy'), findsOneWidget);
      expect(find.text('Has iniciado sesión correctamente.'), findsNothing);
      await tester.tap(find.text('Agenda'));
      await tester.pumpAndSettle();
      expect(find.text('Agenda'), findsWidgets);
      await tester.tap(find.text('Clientes'));
      await tester.pumpAndSettle();
      expect(find.text('Buscar por nombre o documento...'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Un rol desconocido no consulta datos administrativos', (
    tester,
  ) async {
    var requests = 0;
    final api = ApiClient(
      baseUrl: Uri.parse('https://example.com'),
      client: MockClient((_) async {
        requests++;
        return http.Response('', 403);
      }),
    );
    addTearDown(api.close);
    final account = session('Desconocido');
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          session: account,
          onLogout: () {},
          onSessionExpired: () {},
          repository: DashboardRepository(api, account),
          managementRepository: ManagementRepository.preview(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Tu cuenta no tiene un perfil habilitado en la aplicación.'),
      findsOneWidget,
    );
    expect(find.text('Accesos rápidos'), findsNothing);
    expect(requests, 0);
  });
}
