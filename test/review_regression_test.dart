import 'package:revela/features/professional/presentation/professional_portal.dart';
import 'package:revela/features/management/presentation/record_detail.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:revela/core/network/api_client.dart';
import 'package:revela/core/theme/app_theme.dart';
import 'package:revela/features/auth/domain/auth_session.dart';
import 'package:revela/features/management/domain/module.dart';
import 'package:revela/features/management/domain/payload.dart';
import 'package:revela/features/management/domain/record_values.dart';
import 'package:revela/features/management/data/management_repository.dart';
import 'package:revela/features/management/presentation/record_form.dart';

Widget app(Widget home) => MaterialApp(
  theme: AppTheme.dark,
  locale: const Locale('es'),
  supportedLocales: const [Locale('es')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: home,
);
void main() {
  test('Invalid or repeated weekday mappings never crash or mislabel days', () {
    for (final source in [
      '{',
      '[]',
      'null',
      '{"lunes":1}',
      jsonEncode({
        'domingo': 0,
        'lunes': 0,
        'martes': 2,
        'miercoles': 3,
        'jueves': 4,
        'viernes': 5,
        'sabado': 6,
      }),
    ]) {
      expect(weekdayCodes(source: source), isEmpty);
    }
    expect(
      weekdayCodes(source: jsonEncode(weekdayCodes(preview: true))),
      hasLength(7),
    );
  });
  test('Filters remain effective when server ignores closure, professional and date', () async {
    final api = ApiClient(
      baseUrl: Uri.parse('https://example.com'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {'id': 1, 'profesionalId': 7, 'liquidacionComisionId': 10},
              {'id': 2, 'profesionalId': 7, 'liquidacionComisionId': 20},
              {'id': 3, 'profesionalId': 8, 'liquidacionComisionId': 10},
            ],
          }),
          200,
        ),
      ),
    );
    addTearDown(api.close);
    final session = AuthSession(
      accessToken: 'test',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      companyName: 'Test',
      companyId: 1,
    );
    final rows = await ManagementRepository(api: api, session: session).list(
      Module.commissions,
      filters: {'profesionalId': '7', 'liquidacionComisionId': '10'},
    );
    expect(rows.map((r) => r['id']), [1]);
    expect(
      filterRecords(
        Module.reservations,
        [
          {'id': 1, 'fecha': '2026-11-10', 'horaInicio': '08:00:00'},
          {'id': 2, 'fecha': '2026-11-10', 'horaInicio': '15:00:00'},
          {'id': 3, 'fecha': '2026-11-11', 'horaInicio': '15:00:00'},
        ],
        {
          'fechaInicio': '2026-11-10T14:00:00',
          'fechaFin': '2026-11-10T23:59:59',
        },
      ).map((r) => r['id']),
      [2],
    );
  });
  test(
    'Preview uses isolated snapshots, nested specialties and cancelled history',
    () async {
      final repo = ManagementRepository.preview();
      final read = await repo.list(Module.reservations);
      (read.first['cliente'] as Map)['nombres'] = 'Changed';
      expect(
        (repo.memory[Module.reservations]!.first['cliente'] as Map)['nombres'],
        isNot('Changed'),
      );
      await repo.save(Module.professionals, {
        'nombres': 'Nuevo',
        'especialidad': 1,
        'estado': true,
      });
      expect(
        (repo.memory[Module.professionals]!.last['especialidad']
            as Map)['nombre'],
        isNotEmpty,
      );
      await repo.remove(Module.reservations, 1, body: {'motivoOtro': 'Prueba'});
      expect(repo.memory[Module.reservations]!.first['estado'], 3);
      expect(repo.memory[Module.reservations]!.first['motivoOtro'], 'Prueba');
    },
  );
  test('Schedule comparisons accept non-padded valid hours and reject invalid times', () {
    expect(
      buildPayload(Module.schedules, {
        'profesionalId': 1,
        'dia': 'lunes',
        'horaInicio': '9:00',
        'horaFin': '17:00',
        'tieneAlmuerzo': false,
      }, preview: true)['diaSemana'],
      1,
    );
    expect(
      () => buildPayload(Module.schedules, {
        'profesionalId': 1,
        'dia': 'lunes',
        'horaInicio': '25:00',
        'horaFin': '17:00',
      }, preview: true),
      throwsA(isA<ManagementException>()),
    );
  });
  testWidgets('Editing can explicitly clear optional customer contact', (
    tester,
  ) async {
    final requests = <http.Request>[];
    final api = ApiClient(
      baseUrl: Uri.parse('https://example.com'),
      client: MockClient((r) async {
        requests.add(r);
        return http.Response('{"success":true,"data":null}', 200);
      }),
    );
    addTearDown(api.close);
    final repo = ManagementRepository(
      api: api,
      session: AuthSession(
        accessToken: 'test',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        companyName: 'Test',
        companyId: 1,
      ),
    );
    await tester.pumpWidget(
      app(
        RecordFormPage(
          module: Module.customers,
          repository: repo,
          editing: true,
          initial: {
            'id': 1,
            'documento': '100000001',
            'nombres': 'Cliente',
            'apellidos': 'Prueba',
            'correo': 'correo@revela.test',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('correo')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byKey(const ValueKey('correo')), '');
    await tester.tap(find.text('Guardar cliente'));
    await tester.pumpAndSettle();
    expect(requests, hasLength(1));
    expect(jsonDecode(requests.single.body), containsPair('correo', null));
  });
  testWidgets('Absence editing restores its saved date range and reason', (
    tester,
  ) async {
    final repo = ManagementRepository.preview();
    await tester.pumpWidget(
      app(
        RecordFormPage(
          module: Module.absences,
          repository: repo,
          editing: true,
          initial: {
            'id': 1,
            'fechaInicio': '2026-11-10',
            'fechaFin': '2026-11-12',
            'motivo': 1,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Familiar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final reason = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Familiar'),
    );
    expect(reason.selected, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Repeated confirmation taps open only one reservation review', (
    tester,
  ) async {
    final repo = ManagementRepository.preview();
    final tomorrow = DateTime.now()
        .add(const Duration(days: 1))
        .toIso8601String();
    await tester.pumpWidget(
      app(
        RecordFormPage(
          module: Module.reservations,
          repository: repo,
          initial: {
            'clienteId': 1,
            'servicioId': 1,
            'fecha': tomorrow,
            'horaInicio': '10:00:00',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Confirmar Reserva'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirmar Reserva'),
    );
    button.onPressed!();
    button.onPressed!();
    await tester.pumpAndSettle();
    expect(find.byType(RecordReviewPage, skipOffstage: false), findsOneWidget);
  });
  testWidgets(
    'Professional home loads its linked profile instead of the first catalog entry',
    (tester) async {
      final repo = ManagementRepository.preview();
      repo.memory[Module.professionals]!.add({
        'id': 2,
        'nombres': 'Sofía',
        'apellidos': 'Prueba',
        'porcentaje': 15,
      });
      await tester.pumpWidget(
        app(
          ProfessionalPortal(
            repository: repo,
            professionalId: 2,
            username: 'Usuario',
            onLogout: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sofía Prueba'), findsOneWidget);
      expect(find.text('Camilo Ruiz'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Preview attendance persists and returns to the updated agenda', (
    tester,
  ) async {
    final repo = ManagementRepository.preview();
    final row = (await repo.list(Module.reservations)).first;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => RecordDetailPage(
                    module: Module.reservations,
                    row: row,
                    repository: repo,
                  ),
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Confirmar asistencia'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Confirmar asistencia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(repo.memory[Module.reservations]!.first['estado'], 2);
    expect(find.text('Abrir'), findsOneWidget);
  });
}
