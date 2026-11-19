enum ModuloGestion {
  clientes('Clientes', 'Cliente', 'api/Clientes'),
  profesionales('Profesionales', 'Profesional', 'api/Profesionales'),
  servicios('Servicios', 'Servicio', 'api/Servicios'),
  especialidades('Especialidades', 'Especialidad', 'api/Especialidades'),
  reservas('Agenda', 'Reserva', 'api/Reservas'),
  horarios('Horarios de trabajo', 'Horario', 'api/horarios-laboral'),
  inasistencias('Inasistencias', 'Inasistencia', 'api/eventualidades'),
  cierres('Cierres', 'Cierre', 'api/liquidaciones-comisiones'),
  comisiones('Comisiones', 'Comisión', 'api/Comisiones');

  const ModuloGestion(this.title, this.nombreSingular, this.path);
  final String title, nombreSingular, path;
  bool get puedeCrear => this != comisiones;
  bool get puedeEditar => this != cierres && this != comisiones;
  bool get puedeEliminar => this != cierres && this != comisiones;
}

String nombreRegistro(Map<String, dynamic> registro) {
  final name = registro['nombreCompleto'] ?? registro['nombre'];
  if (name is String && name.trim().isNotEmpty) return name;
  final person = [
    registro['nombres'],
    registro['apellidos'],
  ].whereType<String>().join(' ').trim();
  return person.isEmpty ? 'Registro #${registro['id'] ?? '—'}' : person;
}

String nombrePersona(Object? value) => value is Map
    ? nombreRegistro(Map<String, dynamic>.from(value))
    : 'Sin asignar';
String iniciales(String name) => name
    .split(' ')
    .where((s) => s.isNotEmpty)
    .take(2)
    .map((s) => s[0])
    .join()
    .toUpperCase();
