import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:revela/core/network/api_client.dart';
import 'package:revela/features/auth/domain/auth_session.dart';
import 'package:revela/features/management/data/management_repository.dart';
import 'package:revela/features/management/domain/module.dart';

Future<int> runClientRegistrationChecks() async {
  var checks = 0;
  void check(bool condition, String description) {
    if (!condition) throw StateError(description);
    checks++;
  }

  const technical =
      'Could not save changes. Please configure your entity type accordingly.';
  final session = AuthSession(
    accessToken: 'test-only',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
    companyName: 'Test',
    companyId: 1,
  );
  final body = {
    'documento': '100000001',
    'nombres': 'Cliente',
    'apellidos': 'Prueba',
    'fechaNacimiento': '1999-04-12',
    'celular': '3000000000',
    'correo': 'ejemplo@revela.test',
  };
  Future<(ManagementException?, List<http.Request>)> scenario({
    required int postStatus,
    Object? lookup,
    int lookupStatus = 200,
    int? editingId,
  }) async {
    final requests = <http.Request>[];
    final api = ApiClient(
      baseUrl: Uri.parse('https://example.com'),
      client: MockClient((r) async {
        requests.add(r);
        if (r.method == 'GET') {
          return http.Response(
            jsonEncode({'success': true, 'data': lookup}),
            lookupStatus,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode(
            postStatus == 201
                ? {
                    'success': true,
                    'data': {'id': 7, ...body},
                  }
                : {'message': technical},
          ),
          postStatus,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    ManagementException? error;
    try {
      await ManagementRepository(
        api: api,
        session: session,
      ).save(Module.customers, body, id: editingId);
    } on ManagementException catch (e) {
      error = e;
    } finally {
      api.close();
    }
    return (error, requests);
  }

  final (success, successRequests) = await scenario(postStatus: 201);
  check(success == null, 'A 201 response remains a successful registration');
  check(
    successRequests.length == 1 && successRequests.single.method == 'POST',
    'A successful registration is sent exactly once with no lookup',
  );
  check(
    jsonDecode(successRequests.single.body)['fechaNacimiento'] == '1999-04-12',
    'Birth date retains API date format',
  );
  final (duplicate, duplicateRequests) = await scenario(
    postStatus: 400,
    lookup: {'id': 7, ...body},
  );
  check(
    duplicate is CustomerAlreadyExistsException,
    'A duplicate is confirmed by an exact document match',
  );
  check(
    (duplicate as CustomerAlreadyExistsException).customer['id'] == 7,
    'Duplicate keeps the existing customer for viewing',
  );
  check(
    duplicateRequests.length == 2 &&
        duplicateRequests.last.url.path == '/api/Clientes/100000001',
    'Failed create is followed by a read-only document lookup',
  );
  check(
    duplicateRequests.where((r) => r.method == 'POST').length == 1,
    'Duplicate lookup never retries a mutation',
  );
  check(
    duplicateRequests.last.headers['Authorization'] == 'Bearer test-only',
    'Document lookup uses the same authenticated session',
  );
  final (missing, _) = await scenario(postStatus: 400, lookupStatus: 404);
  check(
    missing is! CustomerAlreadyExistsException,
    'A missing document is not labeled a duplicate',
  );
  check(
    missing!.message.contains('El servidor no pudo guardar'),
    'Persistence failure has a Spanish user message',
  );
  check(
    !missing.message.contains('entity type'),
    'Framework diagnostic is not shown to users',
  );
  final (different, _) = await scenario(
    postStatus: 400,
    lookup: {'id': 8, 'documento': '999999999'},
  );
  check(
    different is! CustomerAlreadyExistsException,
    'A different document cannot establish a duplicate',
  );
  final (unavailable, unavailableRequests) = await scenario(
    postStatus: 400,
    lookupStatus: 503,
  );
  check(
    unavailable is! CustomerAlreadyExistsException &&
        unavailable!.statusCode == 400,
    'Unavailable lookup preserves the original failure',
  );
  check(
    unavailableRequests.length == 2,
    'Lookup failure does not retry create',
  );
  final (editFailure, editRequests) = await scenario(
    postStatus: 400,
    editingId: 7,
  );
  check(
    editFailure != null &&
        editRequests.length == 1 &&
        editRequests.single.method == 'PUT',
    'Edit errors do not trigger new-client duplicate recovery',
  );
  check(
    userFacingApiMessage('El correo ya está registrado.') ==
        'El correo ya está registrado.',
    'Useful business errors are preserved',
  );
  check(
    userFacingApiMessage('DbUpdateException: sensitive SQL stack') == null,
    'Internal diagnostics are suppressed',
  );
  return checks;
}
