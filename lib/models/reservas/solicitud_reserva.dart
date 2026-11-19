class SolicitudReserva {
  const SolicitudReserva({
    required this.fecha,
    required this.servicioId,
    required this.clienteId,
    this.profesionalId,
  });

  final DateTime fecha;
  final int servicioId;
  final int clienteId;
  final int? profesionalId;

  Map<String, dynamic> toJson() {
    return {
      'fecha': fecha.toIso8601String(),
      'servicioId': servicioId,
      'clienteId': clienteId,

      if (profesionalId != null) 'profesionalId': profesionalId,
    };
  }
}
