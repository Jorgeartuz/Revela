enum Module {
  customers('Clientes', 'Cliente', 'api/Clientes'),
  professionals('Profesionales', 'Profesional', 'api/Profesionales'),
  services('Servicios', 'Servicio', 'api/Servicios'),
  specialties('Especialidades', 'Especialidad', 'api/Especialidades'),
  reservations('Agenda', 'Reserva', 'api/Reservas'),
  schedules('Horarios de trabajo', 'Horario', 'api/horarios-laboral'),
  absences('Inasistencias', 'Inasistencia', 'api/eventualidades'),
  closures('Cierres', 'Cierre', 'api/liquidaciones-comisiones'),
  commissions('Comisiones', 'Comisión', 'api/Comisiones');

  const Module(this.title, this.singular, this.path);
  final String title, singular, path;
  bool get canCreate => this != commissions;
  bool get canEdit => this != closures && this != commissions;
  bool get canDelete => this != closures && this != commissions;
}

String recordName(Map<String, dynamic> row) {
  final name = row['nombreCompleto'] ?? row['nombre'];
  if (name is String && name.trim().isNotEmpty) return name;
  final person = [
    row['nombres'],
    row['apellidos'],
  ].whereType<String>().join(' ').trim();
  return person.isEmpty ? 'Registro #${row['id'] ?? '—'}' : person;
}

String personName(Object? value) =>
    value is Map ? recordName(Map<String, dynamic>.from(value)) : 'Sin asignar';
String initials(String name) => name
    .split(' ')
    .where((s) => s.isNotEmpty)
    .take(2)
    .map((s) => s[0])
    .join()
    .toUpperCase();
