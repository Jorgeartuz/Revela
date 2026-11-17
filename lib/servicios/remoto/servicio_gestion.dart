import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:revela/servicios/remoto/cliente_api.dart';
import 'package:revela/modelos/login/sesion_usuario.dart';
import 'package:revela/modelos/gestion/modulo_gestion.dart';
import 'package:revela/modelos/gestion/valores_registro.dart';
import 'package:revela/servicios/local/datos_ejemplo.dart';

class ErrorGestion implements Exception {
  const ErrorGestion(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ErrorClienteExistente extends ErrorGestion {
  const ErrorClienteExistente(this.cliente)
    : super(
        'Ya existe un cliente con este documento. Puedes consultar su ficha en lugar de registrarlo de nuevo.',
        statusCode: 409,
      );
  final Map<String, dynamic> cliente;
}

/// Acceso a los datos de clientes, servicios, profesionales y demás módulos.
/// En vistaPrevia usa ejemplos en memoria; en la aplicación normal llama a ClienteApi.
class ServicioGestion {
  ServicioGestion({
    required this.api,
    required this.sesion,
    this.alNoEstarAutorizado,
  }) : vistaPrevia = false;
  ServicioGestion.vistaPrevia()
    : api = null,
      sesion = null,
      alNoEstarAutorizado = null,
      vistaPrevia = true;
  final ClienteApi? api;
  final SesionUsuario? sesion;
  final void Function()? alNoEstarAutorizado;
  final bool vistaPrevia;
  void Function()? alIrAlInicio;
  void Function(int)? alCambiarPestanaProfesional;
  Map<ModuloGestion, List<Map<String, dynamic>>>? _memoria;
  Map<ModuloGestion, List<Map<String, dynamic>>> get memoria =>
      _memoria ??= datosEjemplo();

  /// Adjunta el token, lee success/data y convierte los errores en mensajes comprensibles.
  Future<Object?> _solicitar(String method, String path, {Object? body}) async {
    if (sesion?.estaVencida ?? true) {
      scheduleMicrotask(() => alNoEstarAutorizado?.call());
      throw const ErrorGestion('Tu sesión ha vencido. Inicia sesión de nuevo.');
    }
    try {
      final Object? response = await switch (method) {
        'POST' => api!.post(path, body: body, token: sesion!.tokenAcceso),
        'PUT' => api!.put(path, body: body, token: sesion!.tokenAcceso),
        'DELETE' => api!.delete(path, body: body, token: sesion!.tokenAcceso),
        _ => api!.get(path, token: sesion!.tokenAcceso),
      };
      if (response is Map<String, dynamic> && response.containsKey('success')) {
        if (response['success'] != true) {
          final mensaje = response['message'];
          throw ErrorGestion(
            (mensaje is String ? mensajeApiParaUsuario(mensaje) : null) ?? 'No se pudo completar la operación. Revisa los datos e inténtalo de nuevo.',
          );
        }
        return response['data'];
      }
      return response;
    } on ErrorApi catch (e) {
      if (e.statusCode == 401) {
        scheduleMicrotask(() => alNoEstarAutorizado?.call());
      }
      throw ErrorGestion(switch (e.statusCode) {
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
      throw const ErrorGestion(
        'La conexión tardó demasiado. Reintenta cuando vuelva a estar disponible.',
      );
    } on http.ClientException {
      throw const ErrorGestion(
        'No se pudo conectar. Revisa tu conexión a internet.',
      );
    } on FormatException {
      throw const ErrorGestion('No se pudo leer la respuesta del servicio.');
    }
  }

  /// Consulta los registros y aplica los filtros que también puede comprobar el dispositivo.
  Future<List<Map<String, dynamic>>> listar(
    ModuloGestion modulo, {
    Map<String, String> filtros = const {},
  }) async {
    if (vistaPrevia) {
      if (filtros['previewEmpty'] == '1') return [];
      final registros = (jsonDecode(jsonEncode(memoria[modulo])) as List).map(
        (r) => Map<String, dynamic>.from(r as Map),
      );
      return filtrarRegistros(modulo, registros, filtros);
    }
    final query = {...filtros};
    if (modulo == ModuloGestion.profesionales) {
      query.putIfAbsent('soloActivos', () => 'false');
    }
    final path = Uri(
      path: modulo.path,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
    final data = await _solicitar('GET', path);
    if (data is! List) {
      throw const ErrorGestion('El servicio no devolvió un listado válido.');
    }
    final registros = data.map((r) {
      if (r is! Map<String, dynamic>) {
        throw const ErrorGestion('El servicio devolvió un registro inválido.');
      }
      return r;
    }).toList();
    return filtrarRegistros(modulo, registros, filtros);
  }

  Future<Map<String, dynamic>?> obtenerProfesional(int id) async {
    if (vistaPrevia) {
      return memoria[ModuloGestion.profesionales]!
          .where((r) => r['id'] == id)
          .firstOrNull;
    }
    final data = await _solicitar('GET', 'api/Profesionales/$id');
    if (data is! Map<String, dynamic> || data['id'] != id) {
      throw const ErrorGestion('No se pudo cargar el perfil del profesional.');
    }
    return data;
  }

  /// Sin id crea un registro (POST); con id actualiza el existente (PUT).
  Future<Map<String, dynamic>?> guardar(
    ModuloGestion modulo,
    Map<String, dynamic> body, {
    int? id,
  }) async {
    if (vistaPrevia) {
      final registros = memoria[modulo]!;
      final created = {
        ...body,
        'id':
            id ??
            (registros.fold<int>(
                  0,
                  (m, r) => (r['id'] as int) > m ? r['id'] as int : m,
                ) +
                1),
      };
      if (modulo == ModuloGestion.servicios ||
          modulo == ModuloGestion.profesionales) {
        final specialty = body['especialidad'];
        if (specialty is int) {
          created['especialidadId'] = specialty;
          created['especialidad'] = memoria[ModuloGestion.especialidades]!
              .where((r) => r['id'] == specialty)
              .firstOrNull;
        }
      }
      if (modulo == ModuloGestion.especialidades) {
        created.putIfAbsent('activa', () => true);
      }
      if (modulo == ModuloGestion.servicios) {
        created.putIfAbsent('activo', () => true);
      }
      if (modulo == ModuloGestion.reservas) {
        final date = DateTime.parse(created['fecha'] as String);
        final cliente = memoria[ModuloGestion.clientes]!
            .where((r) => r['id'] == created['clienteId'])
            .firstOrNull;
        final servicio = memoria[ModuloGestion.servicios]!
            .where((r) => r['id'] == created['servicioId'])
            .firstOrNull;
        final profesional =
            memoria[ModuloGestion.profesionales]!
                .where((r) => r['id'] == created['profesionalId'])
                .firstOrNull ??
            memoria[ModuloGestion.profesionales]!.firstOrNull;
        final finish = date.add(
          Duration(minutes: servicio?['duracion'] as int? ?? 60),
        );
        created.addAll({
          'cliente': cliente,
          'servicio': servicio,
          'profesional': profesional,
          'profesionalId': profesional?['id'],
          'horaInicio': date.toIso8601String().split('T').last.substring(0, 8),
          'horaFin': finish.toIso8601String().split('T').last.substring(0, 8),
          'estado': 0,
        });
      }
      if (modulo == ModuloGestion.inasistencias &&
          created['periodos'] is List) {
        final periods = created['periodos'] as List;
        if (periods.isNotEmpty) {
          created.addAll(Map<String, dynamic>.from(periods.first as Map));
        }
      }
      if (id == null) {
        registros.add(created);
      } else {
        final i = registros.indexWhere((r) => r['id'] == id);
        if (i >= 0) registros[i] = {...registros[i], ...created};
      }
      return created;
    }
    final path = id == null
        ? (modulo == ModuloGestion.inasistencias
              ? '${modulo.path}/masivo'
              : modulo.path)
        : '${modulo.path}/$id';
    try {
      final data = await _solicitar(
        id == null ? 'POST' : 'PUT',
        path,
        body: body,
      );
      return data is Map<String, dynamic> ? data : null;
    } on ErrorGestion catch (error) {
      // Un fallo de guardado no demuestra que el cliente exista; primero se consulta su documento.
      if (modulo == ModuloGestion.clientes &&
          id == null &&
          (error.statusCode == 400 ||
              error.statusCode == 409 ||
              error.statusCode == 422)) {
        final document = body['documento']?.toString().trim();
        if (document != null && document.isNotEmpty) {
          final existing = await _clienteExistente(document);
          if (existing != null) throw ErrorClienteExistente(existing);
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _clienteExistente(String document) async {
    try {
      final data = await _solicitar(
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
    } on ErrorGestion {
      // Si la consulta falla, no afirmamos que esté duplicado ni repetimos el registro.
      return null;
    }
  }

  /// Solicita eliminar un registro o cancelar una reserva según las reglas de la API.
  Future<void> eliminar(
    ModuloGestion modulo,
    int id, {
    Map<String, dynamic>? body,
  }) async {
    if (vistaPrevia) {
      if (modulo == ModuloGestion.reservas) {
        final registro = memoria[modulo]!
            .where((r) => r['id'] == id)
            .firstOrNull;
        if (registro != null) {
          registro.addAll({'estado': 3, 'motivoOtro': body?['motivoOtro']});
        }
      } else {
        memoria[modulo]!.removeWhere((r) => r['id'] == id);
      }
      return;
    }
    await _solicitar('DELETE', '${modulo.path}/$id', body: body);
  }

  Future<List<Map<String, dynamic>>> serviciosDeComision(int id) async {
    if (vistaPrevia) return memoria[ModuloGestion.reservas]!;
    final data = await _solicitar('GET', 'api/Comisiones/$id/servicios');
    if (data is! List) {
      throw const ErrorGestion('No se pudo cargar el detalle de comisión.');
    }
    return data.map((r) => Map<String, dynamic>.from(r as Map)).toList();
  }

  Future<Object?> consultarDisponibilidad({
    required int serviceId,
    required DateTime date,
    int? idProfesional,
  }) async {
    if (vistaPrevia) return [];
    final path = Uri(
      path: 'api/agenda',
      queryParameters: {
        'fecha': date.toIso8601String().split('T').first,
        'servicioId': '$serviceId',
        if (idProfesional != null) 'profesionalId': '$idProfesional',
      },
    ).toString();
    return _solicitar('GET', path);
  }
}
