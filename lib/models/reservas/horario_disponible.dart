class HorarioDisponible {
  const HorarioDisponible(this.fecha);

  final DateTime fecha;

  factory HorarioDisponible.fromJson(Map<String, dynamic> json) {
    final valor = json['fecha'];
    final fecha = valor is String ? DateTime.tryParse(valor) : null;
    final contieneHora =
        valor is String && RegExp(r'[T ]\d{2}:\d{2}').hasMatch(valor);
    if (fecha == null || !contieneHora) {
      throw const FormatException('Horario de disponibilidad inválido.');
    }
    return HorarioDisponible(fecha.toLocal());
  }
}
