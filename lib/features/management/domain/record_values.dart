import 'dart:convert';

import 'module.dart';

/// Validated configuration is shared by forms and labels, including invalid deployments.
Map<String, int> weekdayCodes({bool preview = false, String? source}) {
  const demo = {
    'domingo': 0,
    'lunes': 1,
    'martes': 2,
    'miercoles': 3,
    'jueves': 4,
    'viernes': 5,
    'sabado': 6,
  };
  if (preview) return demo;
  try {
    final decoded = jsonDecode(
      source ?? const String.fromEnvironment('WEEKDAY_MAP', defaultValue: '{}'),
    );
    if (decoded is! Map ||
        decoded.length != 7 ||
        demo.keys.any(
          (k) => decoded[k] is! int || decoded[k] < 0 || decoded[k] > 6,
        ) ||
        decoded.values.toSet().length != 7) {
      return {};
    }
    return {for (final k in demo.keys) k: decoded[k] as int};
  } on FormatException {
    return {};
  }
}

Map<String, int> absenceCodes({bool preview = false}) => preview
    ? const {'salud': 0, 'familiar': 1, 'otro': 2}
    : {
        if (int.tryParse(const String.fromEnvironment('ABSENCE_HEALTH'))
            case final int health)
          'salud': health,
        if (int.tryParse(const String.fromEnvironment('ABSENCE_FAMILY'))
            case final int family)
          'familiar': family,
        if (int.tryParse(const String.fromEnvironment('ABSENCE_OTHER'))
            case final int other)
          'otro': other,
      };
int? timeMinutes(Object? value) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?$')
      .firstMatch(value?.toString() ?? '');
  if (match == null) return null;
  final hour = int.parse(match[1]!),
      minute = int.parse(match[2]!),
      second = int.tryParse(match[3] ?? '0') ?? 0;
  return hour < 24 && minute < 60 && second < 60 ? hour * 60 + minute : null;
}

DateTime? recordStart(Map<String, dynamic> row) {
  final date = DateTime.tryParse('${row['fecha']}');
  if (date == null) return null;
  final minutes = timeMinutes(row['horaInicio']);
  return minutes == null
      ? date
      : DateTime(date.year, date.month, date.day, minutes ~/ 60, minutes % 60);
}

List<Map<String, dynamic>> filterRecords(
  Module module,
  Iterable<Map<String, dynamic>> rows,
  Map<String, String> filters,
) {
  final first = DateTime.tryParse(filters['fechaInicio'] ?? ''),
      last = DateTime.tryParse(filters['fechaFin'] ?? '');
  return rows.where((r) {
    final person =
        r['profesionalId'] ??
        (r['profesional'] is Map ? (r['profesional'] as Map)['id'] : null);
    if (filters['profesionalId'] != null &&
        '$person' != filters['profesionalId']) {
      return false;
    }
    final closure = r['liquidacionComisionId'] ?? r['liquidacionId'];
    if (module == Module.commissions &&
        filters['liquidacionComisionId'] != null &&
        '$closure' != filters['liquidacionComisionId']) {
      return false;
    }
    if (first != null || last != null) {
      DateTime? start, end;
      if (module == Module.reservations) {
        start = recordStart(r);
        end = start;
      }
      if (module == Module.closures || module == Module.absences) {
        start = DateTime.tryParse('${r['fechaInicio']}');
        end = DateTime.tryParse('${r['fechaFin']}');
      }
      if ([
        Module.reservations,
        Module.closures,
        Module.absences,
      ].contains(module)) {
        if (start == null || end == null) return false;
        final limit = last == null
            ? null
            : (filters['fechaFin']!.contains('T')
                  ? last
                  : last
                        .add(const Duration(days: 1))
                        .subtract(const Duration(microseconds: 1)));
        if (first != null && end.isBefore(first) ||
            limit != null && start.isAfter(limit)) {
          return false;
        }
      }
    }
    return true;
  }).toList();
}
