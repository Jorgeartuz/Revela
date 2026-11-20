class ResumenServicios {
  const ResumenServicios._(
    this.cantidadServicios,
    this.baseTotal,
    this.comisionTotal,
  );

  final int? cantidadServicios;
  final num? baseTotal;
  final num? comisionTotal;

  factory ResumenServicios.calcular({
    required Iterable<Map<String, dynamic>> reservas,
    required bool serviciosIdentificados,
    required num? porcentaje,
  }) {
    if (!serviciosIdentificados) {
      return const ResumenServicios._(null, null, null);
    }
    final unicas = <int, Map<String, dynamic>>{};
    for (final reserva in reservas) {
      final id = reserva['id'];
      if (id is! int) return const ResumenServicios._(null, null, null);
      unicas[id] = reserva;
    }
    num? base = 0;
    num? comision = 0;
    for (final reserva in unicas.values) {
      final precio = _precio(reserva);
      final valorComision = comisionDe(reserva, porcentaje);
      base = base != null && precio != null ? base + precio : null;
      comision = comision != null && valorComision != null
          ? comision + valorComision
          : null;
    }
    return ResumenServicios._(unicas.length, base, comision);
  }

  static num? _precio(Map<String, dynamic> reserva) {
    final servicio = reserva['servicio'];
    final precio = servicio is Map ? servicio['precio'] : null;
    return precio is num && precio.isFinite && precio >= 0 ? precio : null;
  }

  static num? comisionDe(Map<String, dynamic> reserva, num? porcentaje) {
    final precio = _precio(reserva);
    if (precio == null ||
        porcentaje == null ||
        !porcentaje.isFinite ||
        porcentaje < 0 ||
        porcentaje > 100) {
      return null;
    }
    return precio * porcentaje / 100;
  }
}
