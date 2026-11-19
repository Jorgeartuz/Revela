class DatosProfesional {
  const DatosProfesional({
    required this.perfil,
    required this.reservas,
    this.servicios = const [],
  });
  final Map<String, dynamic>? perfil;
  final List<Map<String, dynamic>> reservas;
  final List<Map<String, dynamic>> servicios;
}
