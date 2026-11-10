import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:revela/core/network/api_client.dart';

void main() {
  test('Conserva el prefijo de API y decodifica JSON', () async {
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/api'),
      client: MockClient((request) async {
        expect(request.url.toString(), 'https://example.com/api/clientes');
        return http.Response('{"nombre":"Revela"}', 200);
      }),
    );
    addTearDown(client.close);
    expect(await client.get('clientes'), {'nombre': 'Revela'});
  });

  test('Rechaza destinos externos antes de enviar credenciales', () async {
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/api'),
      client: MockClient((_) async => throw StateError('No debe enviar')),
    );
    addTearDown(client.close);
    await expectLater(
      client.get('https://otro.example', token: 'privado'),
      throwsArgumentError,
    );
  });

  test('Reporta HTTP no exitoso y admite respuestas sin cuerpo', () async {
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com'),
      client: MockClient(
        (request) async =>
            http.Response('', request.url.path == '/error' ? 401 : 204),
      ),
    );
    addTearDown(client.close);
    expect(await client.post('guardar'), isNull);
    await expectLater(
      client.get('error'),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
  });
}
