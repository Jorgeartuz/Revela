import 'dart:convert';

import 'module.dart';
import '../data/management_repository.dart';

Map<String, dynamic> buildPayload(
  Module module,
  Map<String, dynamic> values, {
  bool editing = false,
  bool preview = false,
}) {
  final result = Map<String, dynamic>.from(values);
  if (module == Module.professionals && !editing) result['estado'] = true;
  if (module == Module.reservations) {
    final date = result.remove('fechaDia') as String;
    final time = result.remove('hora') as String;
    final selected = DateTime.parse('${date}T$time');
    if (selected.isBefore(DateTime.now())) {
      throw const ManagementException(
        'La reserva debe ser para una fecha y hora futuras.',
      );
    }
    result['fecha'] = selected.toIso8601String();
  }
  if (module == Module.schedules) {
    final start = result['horaInicio'] as String;
    final end = result['horaFin'] as String;
    if (start.compareTo(end) >= 0) {
      throw const ManagementException(
        'La hora de inicio debe ser anterior a la hora de fin.',
      );
    }
    if (result['tieneAlmuerzo'] == true) {
      final lunchStart = result['horaInicioAlmuerzo'] as String?;
      final lunchEnd = result['horaFinAlmuerzo'] as String?;
      if (lunchStart == null ||
          lunchEnd == null ||
          lunchStart.compareTo(start) < 0 ||
          lunchEnd.compareTo(end) > 0 ||
          lunchStart.compareTo(lunchEnd) >= 0) {
        throw const ManagementException(
          'El almuerzo debe estar dentro de la jornada, con inicio anterior al fin.',
        );
      }
    } else {
      result['horaInicioAlmuerzo'] = null;
      result['horaFinAlmuerzo'] = null;
    }
    if (!editing) {
      const configured = String.fromEnvironment(
        'WEEKDAY_MAP',
        defaultValue: '{}',
      );
      final map = preview
          ? {
              'domingo': 0,
              'lunes': 1,
              'martes': 2,
              'miercoles': 3,
              'jueves': 4,
              'viernes': 5,
              'sabado': 6,
            }
          : jsonDecode(configured) as Map;
      final code = map[result.remove('dia')];
      if (code is! int || code < 0 || code > 6) {
        throw const ManagementException(
          'La configuración de días laborales aún no está habilitada para este centro.',
        );
      }
      result['diaSemana'] = code;
    }
  }
  if (module == Module.absences) {
    final single = result.remove('tipoFecha') == 'dia';
    final start = DateTime.parse(result['fechaInicio'] as String);
    final end = single
        ? start
        : DateTime.tryParse(result['fechaFin']?.toString() ?? '');
    if (end == null || end.isBefore(start)) {
      throw const ManagementException(
        'La fecha final debe ser igual o posterior a la inicial.',
      );
    }
    final label = result.remove('motivoLabel');
    final codes = preview
        ? {'salud': 0, 'familiar': 1, 'otro': 2}
        : {
            'salud': int.tryParse(
              const String.fromEnvironment('ABSENCE_HEALTH'),
            ),
            'familiar': int.tryParse(
              const String.fromEnvironment('ABSENCE_FAMILY'),
            ),
            'otro': int.tryParse(const String.fromEnvironment('ABSENCE_OTHER')),
          };
    final code = codes[label];
    if (code == null || code < 0 || code > 4) {
      throw const ManagementException(
        'El registro de motivos aún no está habilitado para este centro.',
      );
    }
    result['motivo'] = code;
    final period = {
      'fechaInicio': start.toIso8601String(),
      'fechaFin': end
          .add(const Duration(days: 1))
          .subtract(const Duration(seconds: 1))
          .toIso8601String(),
    };
    result.remove('fechaInicio');
    result.remove('fechaFin');
    if (editing) {
      result.addAll(period);
    } else {
      result['periodos'] = [period];
    }
  }
  if (module == Module.closures) {
    final start = DateTime.parse(result['fechaInicio'] as String);
    final end = DateTime.parse(result['fechaFin'] as String);
    if (end.isBefore(start)) {
      throw const ManagementException(
        'El fin del período no puede ser anterior al inicio.',
      );
    }
    if (end.isAfter(DateTime.now())) {
      throw const ManagementException('No se puede cerrar un período futuro.');
    }
  }
  return result;
}
