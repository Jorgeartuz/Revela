import 'dart:convert';

import 'package:revela/models/gestion/modulo_gestion.dart';

Map<String, int> codigosDiasSemana({String? origen}) {
  const dias = {
    'domingo',
    'lunes',
    'martes',
    'miercoles',
    'jueves',
    'viernes',
    'sabado',
  };
  try {
    final configuracion = jsonDecode(
      origen ?? const String.fromEnvironment('WEEKDAY_MAP', defaultValue: '{}'),
    );
    if (configuracion is! Map ||
        configuracion.length != 7 ||
        dias.any(
          (k) =>
              configuracion[k] is! int ||
              configuracion[k] < 0 ||
              configuracion[k] > 6,
        ) ||
        configuracion.values.toSet().length != 7) {
      return {};
    }
    return {for (final k in dias) k: configuracion[k] as int};
  } on FormatException {
    return {};
  }
}

Map<String, int> codigosMotivosInasistencia() {
  final valoresConfigurados = {
    'salud': const String.fromEnvironment('ABSENCE_HEALTH'),
    'familiar': const String.fromEnvironment('ABSENCE_FAMILY'),
    'otro': const String.fromEnvironment('ABSENCE_OTHER'),
  };
  final codigos = <String, int>{};
  for (final entrada in valoresConfigurados.entries) {
    final codigo = int.tryParse(entrada.value);
    if (codigo != null && codigo >= 0 && codigo <= 4) {
      codigos[entrada.key] = codigo;
    }
  }
  return codigos.values.toSet().length == codigos.length ? codigos : {};
}

int? minutosDeHora(Object? valor) {
  final coincidencia = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?$')
      .firstMatch(valor?.toString() ?? '');
  if (coincidencia == null) return null;
  final hora = int.parse(coincidencia[1]!),
      minuto = int.parse(coincidencia[2]!),
      segundo = int.tryParse(coincidencia[3] ?? '0') ?? 0;
  return hora < 24 && minuto < 60 && segundo < 60 ? hora * 60 + minuto : null;
}

DateTime? inicioReserva(Map<String, dynamic> registro) {
  final fecha = DateTime.tryParse('${registro['fecha']}');
  if (fecha == null) return null;
  final minutos = minutosDeHora(registro['horaInicio']);
  return minutos == null
      ? fecha
      : DateTime(
          fecha.year,
          fecha.month,
          fecha.day,
          minutos ~/ 60,
          minutos % 60,
        );
}

List<Map<String, dynamic>> filtrarRegistros(
  ModuloGestion modulo,
  Iterable<Map<String, dynamic>> registros,
  Map<String, String> filtros,
) {
  final desde = DateTime.tryParse(filtros['fechaInicio'] ?? ''),
      hasta = DateTime.tryParse(filtros['fechaFin'] ?? '');
  return registros.where((r) {
    final profesional =
        r['profesionalId'] ??
        (r['profesional'] is Map ? (r['profesional'] as Map)['id'] : null);
    if (filtros['profesionalId'] != null &&
        '$profesional' != filtros['profesionalId']) {
      return false;
    }
    final cierre = r['liquidacionComisionId'] ?? r['liquidacionId'];
    if (modulo == ModuloGestion.comisiones &&
        filtros['liquidacionComisionId'] != null &&
        '$cierre' != filtros['liquidacionComisionId']) {
      return false;
    }
    if (desde != null || hasta != null) {
      DateTime? inicio, fin;
      if (modulo == ModuloGestion.reservas) {
        inicio = inicioReserva(r);
        fin = inicio;
      }
      if (modulo == ModuloGestion.cierres ||
          modulo == ModuloGestion.inasistencias) {
        inicio = DateTime.tryParse('${r['fechaInicio']}');
        fin = DateTime.tryParse('${r['fechaFin']}');
      }
      if ([
        ModuloGestion.reservas,
        ModuloGestion.cierres,
        ModuloGestion.inasistencias,
      ].contains(modulo)) {
        if (inicio == null || fin == null) return false;
        final limite = hasta == null
            ? null
            : (filtros['fechaFin']!.contains('T')
                  ? hasta
                  : hasta
                        .add(const Duration(days: 1))
                        .subtract(const Duration(microseconds: 1)));
        if (desde != null && fin.isBefore(desde) ||
            limite != null && inicio.isAfter(limite)) {
          return false;
        }
      }
    }
    return true;
  }).toList();
}
