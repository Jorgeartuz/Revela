import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/module.dart';
import '../domain/record_values.dart';
import 'preview_data.dart';

class ManagementException implements Exception {
  const ManagementException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class CustomerAlreadyExistsException extends ManagementException {
  const CustomerAlreadyExistsException(this.customer)
    : super(
        'Ya existe un cliente con este documento. Puedes consultar su ficha en lugar de registrarlo de nuevo.',
        statusCode: 409,
      );
  final Map<String, dynamic> customer;
}

class ManagementRepository {
  ManagementRepository({
    required this.api,
    required this.session,
    this.onUnauthorized,
  }) : preview = false;
  ManagementRepository.preview()
    : api = null,
      session = null,
      onUnauthorized = null,
      preview = true;
  final ApiClient? api;
  final AuthSession? session;
  final void Function()? onUnauthorized;
  final bool preview;
  void Function()? onHome;
  void Function(int)? onProfessionalTab;
  Map<Module, List<Map<String, dynamic>>>? _memory;
  Map<Module, List<Map<String, dynamic>>> get memory =>
      _memory ??= previewData();

  Future<Object?> _request(String method, String path, {Object? body}) async {
    if (session?.isExpired ?? true) {
      scheduleMicrotask(() => onUnauthorized?.call());
      throw const ManagementException(
        'Tu sesión ha vencido. Inicia sesión de nuevo.',
      );
    }
    try {
      final Object? response = await switch (method) {
        'POST' => api!.post(path, body: body, token: session!.accessToken),
        'PUT' => api!.put(path, body: body, token: session!.accessToken),
        'DELETE' => api!.delete(path, body: body, token: session!.accessToken),
        _ => api!.get(path, token: session!.accessToken),
      };
      if (response is Map<String, dynamic> && response.containsKey('success')) {
        if (response['success'] != true) {
          throw const ManagementException(
            'No se pudo completar la operación. Revisa los datos e inténtalo de nuevo.',
          );
        }
        return response['data'];
      }
      return response;
    } on ApiException catch (e) {
      if (e.statusCode == 401) scheduleMicrotask(() => onUnauthorized?.call());
      throw ManagementException(switch (e.statusCode) {
        401 => 'Tu sesión ha vencido. Inicia sesión de nuevo.',
        403 => 'Tu cuenta no tiene permiso para realizar esta operación.',
        409 =>
          e.message ??
              'Ya existe un registro con esos datos o el horario está ocupado.',
        400 || 422 =>
          e.message ?? 'Revisa los datos. El servicio no aceptó la solicitud.',
        _ => 'No se pudo completar la operación. Inténtalo nuevamente.',
      }, statusCode: e.statusCode);
    } on TimeoutException {
      throw const ManagementException(
        'La conexión tardó demasiado. Reintenta cuando vuelva a estar disponible.',
      );
    } on http.ClientException {
      throw const ManagementException(
        'No se pudo conectar. Revisa tu conexión a internet.',
      );
    } on FormatException {
      throw const ManagementException(
        'No se pudo leer la respuesta del servicio.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> list(
    Module module, {
    Map<String, String> filters = const {},
  }) async {
    if (preview) {
      if (filters['previewEmpty'] == '1') return [];
      final rows = (jsonDecode(jsonEncode(memory[module])) as List).map(
        (r) => Map<String, dynamic>.from(r as Map),
      );
      return filterRecords(module, rows, filters);
    }
    final query = {...filters};
    if (module == Module.professionals) {
      query.putIfAbsent('soloActivos', () => 'false');
    }
    final path = Uri(
      path: module.path,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
    final data = await _request('GET', path);
    if (data is! List) {
      throw const ManagementException(
        'El servicio no devolvió un listado válido.',
      );
    }
    final rows = data.map((r) {
      if (r is! Map<String, dynamic>) {
        throw const ManagementException(
          'El servicio devolvió un registro inválido.',
        );
      }
      return r;
    }).toList();
    return filterRecords(module, rows, filters);
  }

  Future<Map<String, dynamic>?> professional(int id) async {
    if (preview) {
      return memory[Module.professionals]!
          .where((r) => r['id'] == id)
          .firstOrNull;
    }
    final data = await _request('GET', 'api/Profesionales/$id');
    if (data is! Map<String, dynamic> || data['id'] != id) {
      throw const ManagementException(
        'No se pudo cargar el perfil del profesional.',
      );
    }
    return data;
  }

  Future<Map<String, dynamic>?> save(
    Module module,
    Map<String, dynamic> body, {
    int? id,
  }) async {
    if (preview) {
      final rows = memory[module]!;
      final created = {
        ...body,
        'id':
            id ??
            (rows.fold<int>(
                  0,
                  (m, r) => (r['id'] as int) > m ? r['id'] as int : m,
                ) +
                1),
      };
      if (module == Module.services || module == Module.professionals) {
        final specialty = body['especialidad'];
        if (specialty is int) {
          created['especialidadId'] = specialty;
          created['especialidad'] = memory[Module.specialties]!
              .where((r) => r['id'] == specialty)
              .firstOrNull;
        }
      }
      if (module == Module.specialties) {
        created.putIfAbsent('activa', () => true);
      }
      if (module == Module.services) created.putIfAbsent('activo', () => true);
      if (module == Module.reservations) {
        final date = DateTime.parse(created['fecha'] as String);
        final customer = memory[Module.customers]!
            .where((r) => r['id'] == created['clienteId'])
            .firstOrNull;
        final service = memory[Module.services]!
            .where((r) => r['id'] == created['servicioId'])
            .firstOrNull;
        final professional =
            memory[Module.professionals]!
                .where((r) => r['id'] == created['profesionalId'])
                .firstOrNull ??
            memory[Module.professionals]!.firstOrNull;
        final finish = date.add(
          Duration(minutes: service?['duracion'] as int? ?? 60),
        );
        created.addAll({
          'cliente': customer,
          'servicio': service,
          'profesional': professional,
          'profesionalId': professional?['id'],
          'horaInicio': date.toIso8601String().split('T').last.substring(0, 8),
          'horaFin': finish.toIso8601String().split('T').last.substring(0, 8),
          'estado': 0,
        });
      }
      if (module == Module.absences && created['periodos'] is List) {
        final periods = created['periodos'] as List;
        if (periods.isNotEmpty) {
          created.addAll(Map<String, dynamic>.from(periods.first as Map));
        }
      }
      if (id == null) {
        rows.add(created);
      } else {
        final i = rows.indexWhere((r) => r['id'] == id);
        if (i >= 0) rows[i] = {...rows[i], ...created};
      }
      return created;
    }
    final path = id == null
        ? (module == Module.absences ? '${module.path}/masivo' : module.path)
        : '${module.path}/$id';
    try {
      final data = await _request(
        id == null ? 'POST' : 'PUT',
        path,
        body: body,
      );
      return data is Map<String, dynamic> ? data : null;
    } on ManagementException catch (error) {
      // A database error alone does not prove a duplicate. Confirm it with a read.
      if (module == Module.customers &&
          id == null &&
          (error.statusCode == 400 ||
              error.statusCode == 409 ||
              error.statusCode == 422)) {
        final document = body['documento']?.toString().trim();
        if (document != null && document.isNotEmpty) {
          final existing = await _existingCustomer(document);
          if (existing != null) throw CustomerAlreadyExistsException(existing);
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _existingCustomer(String document) async {
    try {
      final data = await _request(
        'GET',
        'api/Clientes/${Uri.encodeComponent(document)}',
      );
      final candidates = data is Map<String, dynamic>
          ? [data]
          : data is List
          ? data.whereType<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      return candidates
          .where(
            (r) =>
                r['id'] is int && r['documento']?.toString().trim() == document,
          )
          .firstOrNull;
    } on ManagementException {
      // An unavailable lookup must neither claim a duplicate nor repeat the POST.
      return null;
    }
  }

  Future<void> remove(
    Module module,
    int id, {
    Map<String, dynamic>? body,
  }) async {
    if (preview) {
      if (module == Module.reservations) {
        final row = memory[module]!.where((r) => r['id'] == id).firstOrNull;
        if (row != null) {
          row.addAll({'estado': 3, 'motivoOtro': body?['motivoOtro']});
        }
      } else {
        memory[module]!.removeWhere((r) => r['id'] == id);
      }
      return;
    }
    await _request('DELETE', '${module.path}/$id', body: body);
  }

  Future<List<Map<String, dynamic>>> commissionServices(int id) async {
    if (preview) return memory[Module.reservations]!;
    final data = await _request('GET', 'api/Comisiones/$id/servicios');
    if (data is! List) {
      throw const ManagementException(
        'No se pudo cargar el detalle de comisión.',
      );
    }
    return data.map((r) => Map<String, dynamic>.from(r as Map)).toList();
  }

  Future<Object?> availability({
    required int serviceId,
    required DateTime date,
    int? professionalId,
  }) async {
    if (preview) return [];
    final path = Uri(
      path: 'api/agenda',
      queryParameters: {
        'fecha': date.toIso8601String().split('T').first,
        'servicioId': '$serviceId',
        if (professionalId != null) 'profesionalId': '$professionalId',
      },
    ).toString();
    return _request('GET', path);
  }
}
