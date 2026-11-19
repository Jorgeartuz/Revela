import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:revela/services/remote/cliente_api.dart';
import 'package:revela/models/login/sesion_usuario.dart';
import 'package:revela/services/remote/servicio_inicio.dart';
import 'package:revela/models/inicio/reserva.dart';

void main() {
  final account = SesionUsuario(
    tokenAcceso: 'test-token',
    fechaVencimiento: DateTime.now().add(const Duration(hours: 1)),
    nombreEmpresa: 'Prueba',
    idEmpresa: 1,
  );
  test(
    'Consulta el día con token, desenvuelve data y descarta otros días',
    () async {
      final api = ClienteApi(
        urlBase: Uri.parse('https://example.com'),
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer test-token');
          expect(request.url.path, '/api/Reservas');
          expect(
            request.url.queryParameters['FechaInicio'],
            '2026-11-10T00:00:00.000',
          );
          expect(
            request.url.queryParameters['FechaFin'],
            '2026-11-10T23:59:59.999999',
          );
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                for (final day in ['2026-11-10', '2026-11-11'])
                  {
                    'id': 1,
                    'fecha': day,
                    'horaInicio': '10:00:00',
                    'horaFin': '11:00:00',
                    'estado': 42,
                    'cliente': {'nombres': 'Cliente', 'apellidos': 'Prueba'},
                    'profesional': {
                      'nombres': 'Persona',
                      'apellidos': 'Prueba',
                    },
                    'servicio': {'nombre': 'Servicio', 'precio': 45000},
                  },
              ],
            }),
            200,
          );
        }),
      );
      addTearDown(api.close);
      final data = await ServicioInicio(
        api,
        account,
      ).cargarDia(DateTime(2026, 11, 10));
      expect(data.reservas.length, 1);
      expect(data.reservas.single.duracionMinutos, 60);
      expect(data.pendientes(const EstadosReserva()), isNull);
      expect(data.next(const EstadosReserva(), DateTime(2026, 11, 10)), isNull);
      expect(data.pendientes(const EstadosReserva(programada: 42)), 1);
    },
  );

  test(
    '401 notifica vencimiento y no se interpreta como un listado vacío',
    () async {
      var expired = false;
      final api = ClienteApi(
        urlBase: Uri.parse('https://example.com'),
        client: MockClient((_) async => http.Response('', 401)),
      );
      addTearDown(api.close);
      await expectLater(
        ServicioInicio(
          api,
          account,
          alNoEstarAutorizado: () => expired = true,
        ).catalogo(CatalogoInicio.clientes),
        throwsA(isA<ErrorInicio>()),
      );
      expect(expired, isTrue);
    },
  );

  test('Rechaza un resultado fallido aunque HTTP sea 200', () async {
    final api = ClienteApi(
      urlBase: Uri.parse('https://example.com'),
      client: MockClient(
        (_) async => http.Response('{"success":false,"data":null}', 200),
      ),
    );
    addTearDown(api.close);
    await expectLater(
      ServicioInicio(api, account).catalogo(CatalogoInicio.clientes),
      throwsA(isA<ErrorInicio>()),
    );
  });
}
