class Reservation {
  const Reservation({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.customer,
    required this.professional,
    required this.service,
    required this.price,
    required this.state,
    this.source = const {},
  });
  final int id;
  final DateTime startsAt;
  final DateTime endsAt;
  final String customer;
  final String professional;
  final String service;
  final num price;
  final int? state;
  final Map<String, dynamic> source;

  factory Reservation.fromJson(Map<String, dynamic> json) {
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
    final service = json['servicio'];
    return Reservation(
      source: Map<String, dynamic>.from(json),
      id: json['id'] as int,
      startsAt: start,
      endsAt: withTime(json['horaFin'], start),
      customer: fullName(json['cliente']),
      professional: fullName(json['profesional']),
      service: service is Map
          ? service['nombre'] as String? ?? 'Servicio'
          : 'Servicio',
      price: service is Map ? service['precio'] as num? ?? 0 : 0,
      state: json['estado'] as int?,
    );
  }
  int get durationMinutes => endsAt.difference(startsAt).inMinutes;
}

/// Valores opcionales hasta confirmar el enum del servidor.
class ReservationStates {
  const ReservationStates({
    this.scheduled,
    this.confirmed,
    this.attended,
    this.cancelled,
  });
  final int? scheduled, confirmed, attended, cancelled;
  static final configured = ReservationStates(
    scheduled: int.tryParse(const String.fromEnvironment('RESERVA_PROGRAMADA')),
    confirmed: int.tryParse(const String.fromEnvironment('RESERVA_CONFIRMADA')),
    attended: int.tryParse(const String.fromEnvironment('RESERVA_ATENDIDA')),
    cancelled: int.tryParse(const String.fromEnvironment('RESERVA_CANCELADA')),
  );
  String? label(int? value) {
    if (value == null) return null;
    if (value == scheduled) return 'PROGRAMADA';
    if (value == confirmed) return 'CONFIRMADA';
    if (value == attended) return 'ATENDIDA';
    if (value == cancelled) return 'CANCELADA';
    return null;
  }
}

class DashboardSnapshot {
  DashboardSnapshot(Iterable<Reservation> reservations, this.day)
    : reservations =
          reservations
              .where(
                (r) =>
                    r.startsAt.year == day.year &&
                    r.startsAt.month == day.month &&
                    r.startsAt.day == day.day,
              )
              .toList()
            ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  final List<Reservation> reservations;
  final DateTime day;
  int? pending(ReservationStates states) => states.scheduled == null
      ? null
      : reservations.where((r) => r.state == states.scheduled).length;
  int? inProgress(ReservationStates states, DateTime now) =>
      states.confirmed == null
      ? null
      : reservations
            .where(
              (r) =>
                  r.state == states.confirmed &&
                  !r.startsAt.isAfter(now) &&
                  r.endsAt.isAfter(now),
            )
            .length;
  Reservation? next(ReservationStates states, DateTime now) {
    if (states.scheduled == null || states.confirmed == null) return null;
    for (final r in reservations) {
      if (r.startsAt.isAfter(now) &&
          (r.state == states.scheduled || r.state == states.confirmed)) {
        return r;
      }
    }
    return null;
  }
}
