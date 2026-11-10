import '../domain/module.dart';

Map<Module, List<Map<String, dynamic>>> previewData() {
  final date = DateTime.now().toIso8601String().split('T').first;
  final customer = {
    'id': 1,
    'documento': '100000001',
    'nombres': 'Mariana',
    'apellidos': 'Gómez',
    'celular': '3000000000',
    'correo': 'ejemplo@revela.test',
    'fechaNacimiento': '1999-04-12',
  };
  final professional = {
    'id': 1,
    'documento': '100000002',
    'nombres': 'Camilo',
    'apellidos': 'Ruiz',
    'porcentaje': 10.0,
    'estado': true,
    'especialidadId': 1,
    'especialidad': {'id': 1, 'nombre': 'Estilismo y Peinados'},
  };
  final service = {
    'id': 1,
    'nombre': 'Corte y cepillado',
    'precio': 45000,
    'duracion': 60,
    'activo': true,
    'especialidadId': 1,
    'descripcion': 'Servicio de ejemplo',
  };
  return {
    Module.customers: [customer],
    Module.professionals: [professional],
    Module.services: [service],
    Module.specialties: [
      {'id': 1, 'nombre': 'Estilismo y Peinados', 'activa': true},
      {'id': 2, 'nombre': 'Barbería', 'activa': false},
    ],
    Module.reservations: [
      {
        'id': 1,
        'fecha': date,
        'horaInicio': '10:00:00',
        'horaFin': '11:00:00',
        'clienteId': 1,
        'profesionalId': 1,
        'servicioId': 1,
        'estado': 1,
        'cliente': customer,
        'profesional': professional,
        'servicio': service,
      },
    ],
    Module.schedules: [
      for (final d in [1, 2, 3, 4, 5])
        {
          'id': d,
          'profesionalId': 1,
          'diaSemana': d,
          'horaInicio': '08:00:00',
          'horaFin': '17:00:00',
          'tieneAlmuerzo': true,
          'horaInicioAlmuerzo': '12:00:00',
          'horaFinAlmuerzo': '13:00:00',
        },
    ],
    Module.absences: [
      {
        'id': 1,
        'profesionalId': 1,
        'fechaInicio':
            '$date'
            'T00:00:00',
        'fechaFin':
            '$date'
            'T23:59:59',
        'motivo': 0,
        'observacion': 'Salud',
      },
    ],
    Module.closures: [
      {
        'id': 1,
        'fechaInicio': date,
        'fechaFin': date,
        'total': 45000,
        'cantidadServicios': 1,
      },
    ],
    Module.commissions: [
      {
        'id': 1,
        'profesionalId': 1,
        'profesional': professional,
        'liquidacionId': 1,
        'porcentaje': 10,
        'cantidadServicios': 1,
        'base': 45000,
        'valorComision': 4500,
      },
    ],
  };
}
