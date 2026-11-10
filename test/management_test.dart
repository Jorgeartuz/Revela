import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:revela/core/network/api_client.dart';
import 'package:revela/features/auth/domain/auth_session.dart';
import 'package:revela/features/management/data/management_repository.dart';
import 'package:revela/features/management/domain/module.dart';
import 'package:revela/features/management/domain/form_spec.dart';
import 'package:revela/features/management/domain/payload.dart';

var checks = 0;
void check(bool value, String name) {
  if (!value) throw StateError(name);
  checks++;
}

Future<void> rejects(Future<void> Function() action, String name) async {
  var rejected = false;
  try {
    await action();
  } on ManagementException {
    rejected = true;
  }
  check(rejected, name);
}

void rejectsBody(void Function() action, String name) {
  var rejected = false;
  try {
    action();
  } catch (_) {
    rejected = true;
  }
  check(rejected, name);
}

Future<void> runChecks() async {
  final session = AuthSession(
    accessToken: 'test',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
    companyName: 'Test',
    companyId: 1,
  );
  final requests = <http.Request>[];
  final api = ApiClient(
    baseUrl: Uri.parse('https://example.com'),
    client: MockClient((r) async {
      requests.add(r);
      return http.Response('{"success":true,"data":{"id":9}}', 200);
    }),
  );
  final repo = ManagementRepository(api: api, session: session);
  await repo.save(Module.customers, {'nombres': 'Prueba'});
  check(
    requests.last.method == 'POST' && requests.last.url.path == '/api/Clientes',
    'Create endpoint',
  );
  check(
    requests.last.headers['Authorization'] == 'Bearer test',
    'Authenticated mutation',
  );
  await repo.save(Module.services, {'activo': false}, id: 9);
  check(
    requests.last.method == 'PUT' &&
        requests.last.url.path == '/api/Servicios/9',
    'Update endpoint',
  );
  check(
    jsonDecode(requests.last.body)['activo'] == false,
    'Preserves false toggle',
  );
  await repo.remove(Module.reservations, 9, body: {'motivoOtro': 'Ejemplo'});
  check(
    requests.last.method == 'DELETE' &&
        jsonDecode(requests.last.body)['motivoOtro'] == 'Ejemplo',
    'Cancel body',
  );
  await repo.save(Module.absences, {'periodos': []});
  check(
    requests.last.url.path == '/api/eventualidades/masivo',
    'Absence batch endpoint',
  );
  api.close();

  for (final code in [400, 401, 403, 409, 422, 500]) {
    var expired = false;
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com'),
      client: MockClient(
        (r) async => http.Response('{"message":"Solicitud rechazada"}', code),
      ),
    );
    await rejects(
      () => ManagementRepository(
        api: client,
        session: session,
        onUnauthorized: () => expired = true,
      ).save(Module.customers, {}).then((_) {}),
      'HTTP $code rejected',
    );
    if (code == 401) {
      await Future<void>.delayed(Duration.zero);
      check(expired, '401 expires session');
    }
    client.close();
  }
  final logical = ApiClient(
    baseUrl: Uri.parse('https://example.com'),
    client: MockClient(
      (r) async => http.Response('{"success":false,"data":null}', 200),
    ),
  );
  await rejects(
    () => ManagementRepository(
      api: logical,
      session: session,
    ).save(Module.customers, {}).then((_) {}),
    'Logical failure rejected',
  );
  logical.close();
  final scoped = ApiClient(
    baseUrl: Uri.parse('https://example.com'),
    client: MockClient(
      (r) async => http.Response(
        '{"success":true,"data":[{"id":1,"profesionalId":10},{"id":2,"profesionalId":11},{"id":3}]}',
        200,
      ),
    ),
  );
  final personal = await ManagementRepository(
    api: scoped,
    session: session,
  ).list(Module.reservations, filters: {'profesionalId': '10'});
  check(
    personal.length == 1 && personal.single['id'] == 1,
    'Professional scope retained when server ignores filter',
  );
  scoped.close();
  final noContent = ApiClient(
    baseUrl: Uri.parse('https://example.com'),
    client: MockClient((r) async => http.Response('', 204)),
  );
  check(
    await ManagementRepository(
          api: noContent,
          session: session,
        ).save(Module.services, {}, id: 1) ==
        null,
    '204 accepted',
  );
  noContent.close();

  final fields = formFields(Module.customers);
  final email = fields.firstWhere((f) => f.key == 'correo');
  check(validateField(email, 'correo@ejemplo.com') == null, 'Valid email');
  check(validateField(email, 'incorrecto') != null, 'Invalid email');
  check(
    validateField(fields.firstWhere((f) => f.key == 'documento'), '') != null,
    'Required document',
  );
  check(
    validateField(
          fields.firstWhere((f) => f.key == 'fechaNacimiento'),
          '2100-01-01',
        ) !=
        null,
    'Future birthday',
  );
  final price = formFields(Module.services)
      .firstWhere((f) => f.key == 'precio');
  check(validateField(price, '0') == null, 'Zero price');
  check(validateField(price, '-1') != null, 'Negative price');
  check(validateField(price, '1.5') != null, 'Integer price');
  final percentage = formFields(Module.professionals)
      .firstWhere((f) => f.key == 'porcentaje');
  check(validateField(percentage, '100') == null, 'Maximum commission');
  check(validateField(percentage, '101') != null, 'Commission out of range');
  final tomorrow = DateTime.now()
      .add(const Duration(days: 1))
      .toIso8601String()
      .split('T')
      .first;
  final reservation = buildPayload(Module.reservations, {
    'clienteId': 1,
    'servicioId': 2,
    'fechaDia': tomorrow,
    'hora': '10:00:00',
  });
  check(
    reservation['fecha'].toString().startsWith(tomorrow),
    'Reservation date-time combined',
  );
  check(
    !reservation.containsKey('fechaDia') && !reservation.containsKey('hora'),
    'No local fields sent',
  );
  final schedule = {
    'profesionalId': 1,
    'dia': 'lunes',
    'horaInicio': '08:00:00',
    'horaFin': '17:00:00',
    'tieneAlmuerzo': true,
    'horaInicioAlmuerzo': '12:00:00',
    'horaFinAlmuerzo': '13:00:00',
  };
  rejectsBody(
    () => buildPayload(Module.schedules, schedule),
    'Unverified weekday not guessed',
  );
  final previewSchedule = buildPayload(
    Module.schedules,
    schedule,
    preview: true,
  );
  check(
    previewSchedule['diaSemana'] == 1 && !previewSchedule.containsKey('dia'),
    'Preview weekday conversion',
  );
  rejectsBody(
    () => buildPayload(Module.schedules, {
      ...schedule,
      'horaFin': '07:00:00',
    }, preview: true),
    'Invalid working hours',
  );
  rejectsBody(
    () => buildPayload(Module.schedules, {
      ...schedule,
      'horaInicioAlmuerzo': '07:00:00',
    }, preview: true),
    'Lunch outside workday',
  );
  final absence = {
    'profesionalId': 1,
    'tipoFecha': 'dia',
    'fechaInicio': tomorrow,
    'motivoLabel': 'salud',
    'observacion': 'Ejemplo',
  };
  rejectsBody(
    () => buildPayload(Module.absences, absence),
    'Unverified absence reason not guessed',
  );
  final previewAbsence = buildPayload(Module.absences, absence, preview: true);
  check(
    previewAbsence['periodos'] is List && previewAbsence['motivo'] == 0,
    'Absence contract',
  );
  rejectsBody(
    () => buildPayload(Module.closures, {
      'fechaInicio': '2026-10-15',
      'fechaFin': '2026-10-01',
    }),
    'Reversed closure range',
  );

  final preview = ManagementRepository.preview();
  final before = (await preview.list(Module.customers)).length;
  final created = await preview.save(Module.customers, {
    'nombres': 'Nuevo',
    'apellidos': 'Ejemplo',
  });
  check(
    (await preview.list(Module.customers)).length == before + 1,
    'Preview create',
  );
  await preview.save(Module.customers, {
    'nombres': 'Editado',
  }, id: created!['id']);
  check(
    (await preview.list(Module.customers)).last['nombres'] == 'Editado',
    'Preview edit',
  );
  await preview.remove(Module.customers, created['id']);
  check(
    (await preview.list(Module.customers)).length == before,
    'Preview delete',
  );
  check(
    (await preview.list(
      Module.services,
      filters: {'previewEmpty': '1'},
    )).isEmpty,
    'Preview empty state',
  );
  final newBooking = await preview.save(Module.reservations, {
    ...reservation,
    'servicioId': 1,
  });
  check(
    newBooking!['cliente'] is Map &&
        newBooking['servicio'] is Map &&
        newBooking['horaInicio'] == '10:00:00',
    'Preview reservation can be opened after create',
  );
  expect(checks, 39);
}

void main() {
  test(
    'Contratos, validaciones y flujos de gestión sin modificar datos reales',
    runChecks,
  );
}
