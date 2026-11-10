import 'dart:async';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/reservation.dart';

enum Catalog {
  professionals('Profesionales', 'api/Profesionales'),
  customers('Clientes', 'api/Clientes'),
  services('Servicios', 'api/Servicios'),
  specialties('Especialidades', 'api/Especialidades'),
  closures('Cierres', 'api/liquidaciones-comisiones');

  const Catalog(this.title, this.path);
  final String title, path;
}

class DashboardException implements Exception {
  const DashboardException(this.message);
  final String message;
  @override
  String toString() => message;
}

class DashboardRepository {
  DashboardRepository(this.api, this.session, {this.onUnauthorized});
  final ApiClient api;
  final AuthSession session;
  final void Function()? onUnauthorized;

  Future<List<Map<String, dynamic>>> _list(String path) async {
    if (session.isExpired) {
      scheduleMicrotask(() => onUnauthorized?.call());
      throw const DashboardException('Tu sesión ha vencido.');
    }
    try {
      final result = await api.get(path, token: session.accessToken);
      if (result is! Map<String, dynamic> ||
          result['success'] != true ||
          result['data'] is! List) {
        throw const FormatException('Respuesta de listado inválida.');
      }
      return (result['data'] as List).map((row) {
        if (row is! Map<String, dynamic>) {
          throw const FormatException('Registro inválido.');
        }
        return row;
      }).toList();
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        onUnauthorized?.call();
      }
      throw DashboardException(
        error.statusCode == 403
            ? 'Tu cuenta no tiene acceso a esta información.'
            : error.statusCode == 401
            ? 'Tu sesión ha vencido.'
            : 'No se pudo cargar la información. Vuelve a intentar.',
      );
    } on TimeoutException {
      throw const DashboardException(
        'La conexión tardó demasiado. Vuelve a intentar.',
      );
    } on http.ClientException {
      throw const DashboardException(
        'Revisa tu conexión a internet e inténtalo de nuevo.',
      );
    } on FormatException {
      throw const DashboardException(
        'No se pudo leer la información del servicio.',
      );
    }
  }

  Future<DashboardSnapshot> loadDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start
        .add(const Duration(days: 1))
        .subtract(const Duration(microseconds: 1));
    final path = Uri(
      path: 'api/Reservas',
      queryParameters: {
        'FechaInicio': start.toIso8601String(),
        'FechaFin': end.toIso8601String(),
      },
    ).toString();
    final rows = await _list(path);
    try {
      return DashboardSnapshot(rows.map(Reservation.fromJson), start);
    } on FormatException {
      throw const DashboardException('No se pudieron leer las reservas.');
    } on TypeError {
      throw const DashboardException('No se pudieron leer las reservas.');
    }
  }

  Future<List<Map<String, dynamic>>> catalog(Catalog catalog) =>
      _list(catalog.path);
}
