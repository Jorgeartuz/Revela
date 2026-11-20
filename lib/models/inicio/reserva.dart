class Reserva {
  const Reserva({
    required this.id,
    required this.inicio,
    required this.fin,
    required this.cliente,
    required this.profesional,
    required this.servicio,
    required this.precio,
    required this.estado,
    this.origen = const {},
  });
  final int id;
  final DateTime inicio;
  final DateTime fin;
  final String cliente;
  final String profesional;
  final String servicio;
  final num precio;
  final int? estado;
  final Map<String, dynamic> origen;

  factory Reserva.fromJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['fecha'] as String);
    DateTime withTime(Object? value, DateTime fallback) {
      if (value is! String) return fallback;
      final parts = value.split(':');
      if (parts.length < 2) throw const FormatException('Hora inválida');
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
        parts.length > 2 ? double.parse(parts[2]).floor() : 0,
      );
    }

    String fullName(Object? value) {
      if (value is! Map) return 'Sin asignar';
      return [
        value['nombres'],
        value['apellidos'],
      ].whereType<String>().join(' ').trim();
    }

    final start = withTime(json['horaInicio'], date);
    final servicio = json['servicio'];
    return Reserva(
      origen: Map<String, dynamic>.from(json),
      id: json['id'] as int,
      inicio: start,
      fin: withTime(json['horaFin'], start),
      cliente: fullName(json['cliente']),
      profesional: fullName(json['profesional']),
      servicio: servicio is Map
          ? servicio['nombre'] as String? ?? 'Servicio'
          : 'Servicio',
      precio: servicio is Map ? servicio['precio'] as num? ?? 0 : 0,
      estado: json['estado'] as int?,
    );
  }
  int get duracionMinutos => fin.difference(inicio).inMinutes;
}

class EstadosReserva {
  const EstadosReserva({
    this.programada,
    this.confirmada,
    this.atendida,
    this.cancelada,
  });
  final int? programada, confirmada, atendida, cancelada;
  static final configurados = _validarConfiguracion();
  static EstadosReserva _validarConfiguracion() {
    final valores = EstadosReserva(
      programada: int.tryParse(
        const String.fromEnvironment('RESERVA_PROGRAMADA', defaultValue: '0'),
      ),
      confirmada: int.tryParse(
        const String.fromEnvironment('RESERVA_CONFIRMADA'),
      ),
      atendida: int.tryParse(const String.fromEnvironment('RESERVA_ATENDIDA')),
      cancelada: int.tryParse(
        const String.fromEnvironment('RESERVA_CANCELADA', defaultValue: '1'),
      ),
    );
    final codigos = [
      valores.programada,
      valores.confirmada,
      valores.atendida,
      valores.cancelada,
    ].whereType<int>().toList();
    if (codigos.any((codigo) => codigo < 0) ||
        codigos.toSet().length != codigos.length) {
      return const EstadosReserva();
    }
    return valores;
  }

  String? label(int? value) {
    if (value == null) return null;
    if (value == programada) return 'PROGRAMADA';
    if (value == confirmada) return 'CONFIRMADA';
    if (value == atendida) return 'ATENDIDA';
    if (value == cancelada) return 'CANCELADA';
    return null;
  }
}

class ResumenDiario {
  ResumenDiario(Iterable<Reserva> reservas, this.day)
    : reservas =
          reservas
              .where(
                (r) =>
                    r.inicio.year == day.year &&
                    r.inicio.month == day.month &&
                    r.inicio.day == day.day,
              )
              .toList()
            ..sort((a, b) => a.inicio.compareTo(b.inicio));
  final List<Reserva> reservas;
  final DateTime day;
  int? pendientes(EstadosReserva states) => states.programada == null
      ? null
      : reservas.where((r) => r.estado == states.programada).length;
  int? enCurso(EstadosReserva states, DateTime now) => states.confirmada == null
      ? null
      : reservas
            .where(
              (r) =>
                  r.estado == states.confirmada &&
                  !r.inicio.isAfter(now) &&
                  r.fin.isAfter(now),
            )
            .length;
  Reserva? next(EstadosReserva states, DateTime now) {
    if (states.programada == null || states.confirmada == null) return null;
    for (final r in reservas) {
      if (r.inicio.isAfter(now) &&
          (r.estado == states.programada || r.estado == states.confirmada)) {
        return r;
      }
    }
    return null;
  }
}
