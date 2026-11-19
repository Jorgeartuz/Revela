import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:revela/services/remote/cliente_api.dart';
import 'package:revela/models/login/sesion_usuario.dart';
import 'package:revela/services/remote/servicio_gestion.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/models/gestion/campos_formulario.dart';
import 'package:revela/models/gestion/datos_para_api.dart';

var checks = 0;
void check(bool value, String name) {
  if (!value) throw StateError(name);
  checks++;
}

Future<void> rejects(Future<void> Function() action, String name) async {
  var rejected = false;
  try {
    await action();
  } on ErrorGestion {
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

Future<void> ejecutarComprobaciones() async {
  final sesion = SesionUsuario(
    tokenAcceso: 'test',
    fechaVencimiento: DateTime.now().add(const Duration(hours: 1)),
    nombreEmpresa: 'Test',
    idEmpresa: 1,
  );
  final requests = <http.Request>[];
  final api = ClienteApi(
    urlBase: Uri.parse('https://example.com'),
    client: MockClient((r) async {
      requests.add(r);
      return http.Response('{"success":true,"data":{"id":9}}', 200);
    }),
  );
  final repo = ServicioGestion(api: api, sesion: sesion);
  await repo.guardar(ModuloGestion.clientes, {'nombres': 'Prueba'});
  check(
    requests.last.method == 'POST' && requests.last.url.path == '/api/Clientes',
    'Create endpoint',
  );
  check(
    requests.last.headers['Authorization'] == 'Bearer test',
    'Authenticated mutation',
  );
  await repo.guardar(ModuloGestion.servicios, {'activo': false}, id: 9);
  check(
    requests.last.method == 'PUT' &&
        requests.last.url.path == '/api/Servicios/9',
    'Update endpoint',
  );
  check(
    jsonDecode(requests.last.body)['activo'] == false,
    'Preserves false toggle',
  );
  await repo.eliminar(
    ModuloGestion.reservas,
    9,
    body: {'motivoOtro': 'Ejemplo'},
  );
  check(
    requests.last.method == 'DELETE' &&
        jsonDecode(requests.last.body)['motivoOtro'] == 'Ejemplo',
    'Cancel body',
  );
  await repo.guardar(ModuloGestion.inasistencias, {'periodos': []});
  check(
    requests.last.url.path == '/api/eventualidades/masivo',
    'Absence batch endpoint',
  );
  api.close();

  for (final code in [400, 401, 403, 409, 422, 500]) {
    var expired = false;
    final client = ClienteApi(
      urlBase: Uri.parse('https://example.com'),
      client: MockClient(
        (r) async => http.Response('{"message":"Solicitud rechazada"}', code),
      ),
    );
    await rejects(
      () => ServicioGestion(
        api: client,
        sesion: sesion,
        alNoEstarAutorizado: () => expired = true,
      ).guardar(ModuloGestion.clientes, {}).then((_) {}),
      'HTTP $code rejected',
    );
    if (code == 401) {
      await Future<void>.delayed(Duration.zero);
      check(expired, '401 expires session');
    }
    client.close();
  }
  final logical = ClienteApi(
    urlBase: Uri.parse('https://example.com'),
    client: MockClient(
      (r) async => http.Response('{"success":false,"data":null}', 200),
    ),
  );
  await rejects(
    () => ServicioGestion(
      api: logical,
      sesion: sesion,
    ).guardar(ModuloGestion.clientes, {}).then((_) {}),
    'Logical failure rejected',
  );
  logical.close();
  final scoped = ClienteApi(
    urlBase: Uri.parse('https://example.com'),
    client: MockClient(
      (r) async => http.Response(
        '{"success":true,"data":[{"id":1,"profesionalId":10},{"id":2,"profesionalId":11},{"id":3}]}',
        200,
      ),
    ),
  );
  final personal = await ServicioGestion(
    api: scoped,
    sesion: sesion,
  ).listar(ModuloGestion.reservas, filtros: {'profesionalId': '10'});
  check(
    personal.length == 1 && personal.single['id'] == 1,
    'Professional scope retained when server ignores filter',
  );
  scoped.close();
  final noContent = ClienteApi(
    urlBase: Uri.parse('https://example.com'),
    client: MockClient((r) async => http.Response('', 204)),
  );
  check(
    await ServicioGestion(
          api: noContent,
          sesion: sesion,
        ).guardar(ModuloGestion.servicios, {}, id: 1) ==
        null,
    '204 accepted',
  );
  noContent.close();

  final campos = camposFormulario(ModuloGestion.clientes);
  final email = campos.firstWhere((f) => f.key == 'correo');
  check(validarCampo(email, 'correo@ejemplo.com') == null, 'Valid email');
  check(validarCampo(email, 'incorrecto') != null, 'Invalid email');
  check(
    validarCampo(campos.firstWhere((f) => f.key == 'documento'), '') != null,
    'Required document',
  );
  check(
    validarCampo(
          campos.firstWhere((f) => f.key == 'fechaNacimiento'),
          '2100-01-01',
        ) !=
        null,
    'Future birthday',
  );
  final precio = camposFormulario(ModuloGestion.servicios)
      .firstWhere((f) => f.key == 'precio');
  check(validarCampo(precio, '0') == null, 'Zero price');
  check(validarCampo(precio, '-1') != null, 'Negative price');
  check(validarCampo(precio, '1.5') != null, 'Integer price');
  final percentage = camposFormulario(ModuloGestion.profesionales)
      .firstWhere((f) => f.key == 'porcentaje');
  check(validarCampo(percentage, '100') == null, 'Maximum commission');
  check(validarCampo(percentage, '101') != null, 'Commission out of range');
  final tomorrow = DateTime.now()
      .add(const Duration(days: 1))
      .toIso8601String()
      .split('T')
      .first;
  final reservation = prepararDatosEnvio(ModuloGestion.reservas, {
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
    () => prepararDatosEnvio(ModuloGestion.horarios, schedule),
    'Unverified weekday not guessed',
  );
  final previewSchedule = prepararDatosEnvio(
    ModuloGestion.horarios,
    schedule,
    vistaPrevia: true,
  );
  check(
    previewSchedule['diaSemana'] == 1 && !previewSchedule.containsKey('dia'),
    'Preview weekday conversion',
  );
  rejectsBody(
    () => prepararDatosEnvio(ModuloGestion.horarios, {
      ...schedule,
      'horaFin': '07:00:00',
    }, vistaPrevia: true),
    'Invalid working hours',
  );
  rejectsBody(
    () => prepararDatosEnvio(ModuloGestion.horarios, {
      ...schedule,
      'horaInicioAlmuerzo': '07:00:00',
    }, vistaPrevia: true),
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
    () => prepararDatosEnvio(ModuloGestion.inasistencias, absence),
    'Unverified absence reason not guessed',
  );
  final previewAbsence = prepararDatosEnvio(
    ModuloGestion.inasistencias,
    absence,
    vistaPrevia: true,
  );
  check(
    previewAbsence['periodos'] is List && previewAbsence['motivo'] == 0,
    'Absence contract',
  );
  rejectsBody(
    () => prepararDatosEnvio(ModuloGestion.cierres, {
      'fechaInicio': '2026-10-15',
      'fechaFin': '2026-10-01',
    }),
    'Reversed closure range',
  );

  final vistaPrevia = ServicioGestion.vistaPrevia();
  final before = (await vistaPrevia.listar(ModuloGestion.clientes)).length;
  final created = await vistaPrevia.guardar(ModuloGestion.clientes, {
    'nombres': 'Nuevo',
    'apellidos': 'Ejemplo',
  });
  check(
    (await vistaPrevia.listar(ModuloGestion.clientes)).length == before + 1,
    'Preview create',
  );
  await vistaPrevia.guardar(ModuloGestion.clientes, {
    'nombres': 'Editado',
  }, id: created!['id']);
  check(
    (await vistaPrevia.listar(ModuloGestion.clientes)).last['nombres'] ==
        'Editado',
    'Preview edit',
  );
  await vistaPrevia.eliminar(ModuloGestion.clientes, created['id']);
  check(
    (await vistaPrevia.listar(ModuloGestion.clientes)).length == before,
    'Preview delete',
  );
  check(
    (await vistaPrevia.listar(
      ModuloGestion.servicios,
      filtros: {'previewEmpty': '1'},
    )).isEmpty,
    'Preview empty state',
  );
  final newBooking = await vistaPrevia.guardar(ModuloGestion.reservas, {
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
    ejecutarComprobaciones,
  );
}
