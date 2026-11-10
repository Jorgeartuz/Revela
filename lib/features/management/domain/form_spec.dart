import 'module.dart';

enum InputKind {
  text,
  integer,
  decimal,
  email,
  date,
  time,
  select,
  toggle,
  multiline,
}

class FieldSpec {
  const FieldSpec(
    this.key,
    this.label, {
    this.kind = InputKind.text,
    this.required = false,
    this.source,
    this.options,
    this.min,
    this.max,
    this.maxLength,
    this.section,
    this.hint,
    this.readOnly = false,
  });
  final String key, label;
  final InputKind kind;
  final bool required, readOnly;
  final Module? source;
  final Map<String, String>? options;
  final double? min, max;
  final int? maxLength;
  final String? section, hint;
}

List<FieldSpec> formFields(Module m, {bool editing = false}) => switch (m) {
  Module.customers => [
    const FieldSpec(
      'documento',
      'Documento',
      required: true,
      section: 'DATOS PERSONALES',
      hint: 'CC/NIT',
    ),
    const FieldSpec('nombres', 'Nombres', required: true, hint: 'Ej. Juan'),
    const FieldSpec('apellidos', 'Apellidos', required: true),
    const FieldSpec(
      'fechaNacimiento',
      'Fecha de nacimiento',
      kind: InputKind.date,
    ),
    const FieldSpec('celular', 'Celular', section: 'CONTACTO'),
    const FieldSpec('correo', 'Correo', kind: InputKind.email),
  ],
  Module.professionals => [
    const FieldSpec(
      'documento',
      'Documento',
      required: true,
      section: 'DATOS PERSONALES',
    ),
    const FieldSpec('nombres', 'Nombres', required: true),
    const FieldSpec('apellidos', 'Apellidos'),
    const FieldSpec(
      'fechaNacimiento',
      'Fecha de nacimiento',
      kind: InputKind.date,
    ),
    const FieldSpec(
      'porcentaje',
      'Comisión (%)',
      required: true,
      kind: InputKind.decimal,
      min: 0,
      max: 100,
      section: 'DATOS LABORALES',
    ),
    if (!editing)
      const FieldSpec(
        'especialidad',
        'Especialidad',
        required: true,
        kind: InputKind.select,
        source: Module.specialties,
      ),
    if (editing) const FieldSpec('estado', 'Activo', kind: InputKind.toggle),
  ],
  Module.services => [
    const FieldSpec(
      'nombre',
      'Nombre',
      required: true,
      maxLength: 50,
      section: 'DATOS DEL SERVICIO',
    ),
    const FieldSpec(
      'precio',
      'Precio',
      required: true,
      kind: InputKind.integer,
      min: 0,
      max: 2147483647,
    ),
    const FieldSpec(
      'duracion',
      'Duración (minutos)',
      required: true,
      kind: InputKind.integer,
      min: 1,
      max: 1440,
    ),
    if (!editing)
      const FieldSpec('descripcion', 'Descripción', kind: InputKind.multiline),
    if (!editing)
      const FieldSpec(
        'especialidad',
        'Especialidad',
        required: true,
        kind: InputKind.select,
        source: Module.specialties,
        section: 'ESPECIALIDAD',
      ),
    if (editing) const FieldSpec('activo', 'Activo', kind: InputKind.toggle),
  ],
  Module.specialties => [
    const FieldSpec(
      'nombre',
      'Nombre',
      required: true,
      hint: 'Ej. Barbería',
      maxLength: 100,
    ),
  ],
  Module.reservations => [
    const FieldSpec(
      'clienteId',
      'Cliente',
      required: true,
      kind: InputKind.select,
      source: Module.customers,
      section: 'CLIENTE',
    ),
    const FieldSpec(
      'servicioId',
      'Servicio',
      required: true,
      kind: InputKind.select,
      source: Module.services,
      section: 'SERVICIO',
    ),
    if (editing)
      const FieldSpec(
        'profesionalId',
        'Profesional',
        kind: InputKind.select,
        source: Module.professionals,
        section: 'PROFESIONAL Y HORARIO',
      ),
    FieldSpec(
      'fechaDia',
      'Fecha',
      required: true,
      kind: InputKind.date,
      section: editing ? null : 'PROFESIONAL Y HORARIO',
    ),
    const FieldSpec('hora', 'Horario', required: true, kind: InputKind.time),
  ],
  Module.schedules => [
    if (!editing)
      const FieldSpec(
        'profesionalId',
        'Profesional',
        required: true,
        kind: InputKind.select,
        source: Module.professionals,
        section: 'PROFESIONAL',
      ),
    if (!editing)
      const FieldSpec(
        'dia',
        'Día',
        required: true,
        kind: InputKind.select,
        section: 'DÍA',
        options: {
          'lunes': 'Lunes',
          'martes': 'Martes',
          'miercoles': 'Miércoles',
          'jueves': 'Jueves',
          'viernes': 'Viernes',
          'sabado': 'Sábado',
          'domingo': 'Domingo',
        },
      ),
    const FieldSpec(
      'horaInicio',
      'Hora de inicio',
      required: true,
      kind: InputKind.time,
      section: 'JORNADA LABORAL',
    ),
    const FieldSpec(
      'horaFin',
      'Hora de fin',
      required: true,
      kind: InputKind.time,
    ),
    const FieldSpec(
      'tieneAlmuerzo',
      'Tiene almuerzo',
      kind: InputKind.toggle,
      section: 'ALMUERZO',
    ),
    const FieldSpec(
      'horaInicioAlmuerzo',
      'Inicio almuerzo',
      kind: InputKind.time,
    ),
    const FieldSpec('horaFinAlmuerzo', 'Fin almuerzo', kind: InputKind.time),
  ],
  Module.absences => [
    if (!editing)
      const FieldSpec(
        'profesionalId',
        'Profesional',
        required: true,
        kind: InputKind.select,
        source: Module.professionals,
      ),
    const FieldSpec(
      'tipoFecha',
      'Tipo de fecha',
      required: true,
      kind: InputKind.select,
      options: {'dia': 'Día específico', 'rango': 'Rango de fechas'},
    ),
    const FieldSpec(
      'fechaInicio',
      'Fecha inicial',
      required: true,
      kind: InputKind.date,
    ),
    const FieldSpec('fechaFin', 'Fecha final', kind: InputKind.date),
    const FieldSpec(
      'motivoLabel',
      'Motivo',
      required: true,
      kind: InputKind.select,
      options: {
        'salud': 'Salud',
        'familiar': 'Familiar',
        'otro': 'Otra causa justificada',
      },
    ),
    const FieldSpec('observacion', 'Observación', kind: InputKind.multiline),
  ],
  Module.closures => [
    const FieldSpec(
      'fechaInicio',
      'Inicio del período',
      required: true,
      kind: InputKind.date,
      section: 'PERÍODO DEL CIERRE',
    ),
    const FieldSpec(
      'fechaFin',
      'Fin del período',
      required: true,
      kind: InputKind.date,
    ),
  ],
  Module.commissions => [],
};

String? validateField(FieldSpec spec, Object? value, {DateTime? now}) {
  final text = value?.toString().trim() ?? '';
  if (spec.required && text.isEmpty) return 'Este campo es obligatorio.';
  if (text.isEmpty || spec.kind == InputKind.toggle) return null;
  if (spec.maxLength != null && text.length > spec.maxLength!) {
    return 'Máximo ${spec.maxLength} caracteres.';
  }
  if (spec.kind == InputKind.email &&
      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
    return 'Ingresa un correo válido.';
  }
  if (spec.key == 'celular' &&
      !RegExp(r'^\+?[0-9 ()-]{7,20}$').hasMatch(text)) {
    return 'Ingresa un celular válido.';
  }
  if (spec.kind == InputKind.integer || spec.kind == InputKind.decimal) {
    final n = spec.kind == InputKind.integer
        ? int.tryParse(text)
        : double.tryParse(text.replaceAll(',', '.'));
    if (n == null || !n.isFinite) {
      return 'Ingresa un número válido${spec.kind == InputKind.integer ? ' entero' : ''}.';
    }
    if (spec.min != null && n < spec.min!) {
      return 'El valor mínimo es ${spec.min}.';
    }
    if (spec.max != null && n > spec.max!) {
      return 'El valor máximo es ${spec.max}.';
    }
  }
  if (spec.key == 'fechaNacimiento') {
    final date = DateTime.tryParse(text);
    if (date == null || date.isAfter(now ?? DateTime.now())) {
      return 'La fecha no puede ser futura.';
    }
  }
  return null;
}
