import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:revela/core/network/api_client.dart';
import 'package:revela/features/auth/domain/auth_session.dart';
import 'package:revela/features/home/data/dashboard_repository.dart';
import 'package:revela/features/home/domain/reservation.dart';

void main() {
  final account = AuthSession(
    accessToken: 'test-token',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
    companyName: 'Prueba',
    companyId: 1,
  );
  test(
    'Consulta el día con token, desenvuelve data y descarta otros días',
    () async {
      final api = ApiClient(
        baseUrl: Uri.parse('https://example.com'),
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
      final data = await DashboardRepository(
        api,
        account,
      ).loadDay(DateTime(2026, 11, 10));
      expect(data.reservations.length, 1);
      expect(data.reservations.single.durationMinutes, 60);
      expect(data.pending(const ReservationStates()), isNull);
      expect(
        data.next(const ReservationStates(), DateTime(2026, 11, 10)),
        isNull,
      );
      expect(data.pending(const ReservationStates(scheduled: 42)), 1);
    },
  );

  test(
    '401 notifica vencimiento y no se interpreta como un listado vacío',
    () async {
      var expired = false;
      final api = ApiClient(
        baseUrl: Uri.parse('https://example.com'),
        client: MockClient((_) async => http.Response('', 401)),
      );
      addTearDown(api.close);
      await expectLater(
        DashboardRepository(
          api,
          account,
          onUnauthorized: () => expired = true,
        ).catalog(Catalog.customers),
        throwsA(isA<DashboardException>()),
      );
      expect(expired, isTrue);
    },
  );

  test('Rechaza un resultado fallido aunque HTTP sea 200', () async {
    final api = ApiClient(
      baseUrl: Uri.parse('https://example.com'),
      client: MockClient(
        (_) async => http.Response('{"success":false,"data":null}', 200),
      ),
    );
    addTearDown(api.close);
    await expectLater(
      DashboardRepository(api, account).catalog(Catalog.customers),
      throwsA(isA<DashboardException>()),
    );
  });
}
