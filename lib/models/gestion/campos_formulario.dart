import 'package:revela/models/gestion/valores_registro.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';

enum TipoCampo {
  texto,
  entero,
  decimal,
  correo,
  fecha,
  hora,
  seleccion,
  interruptor,
  textoLargo,
}

class CampoFormulario {
  const CampoFormulario(
    this.key,
    this.label, {
    this.kind = TipoCampo.texto,
    this.required = false,
    this.origen,
    this.opciones,
    this.min,
    this.max,
    this.maxLength,
    this.tituloSeccion,
    this.hint,
    this.soloLectura = false,
  });
  final String key, label;
  final TipoCampo kind;
  final bool required, soloLectura;
  final ModuloGestion? origen;
  final Map<String, String>? opciones;
  final double? min, max;
  final int? maxLength;
  final String? tituloSeccion, hint;
}

List<CampoFormulario> camposFormulario(
  ModuloGestion m, {
  bool esEdicion = false,
}) => switch (m) {
  ModuloGestion.clientes => [
    const CampoFormulario(
      'documento',
      'Documento',
      required: true,
      tituloSeccion: 'DATOS PERSONALES',
      hint: 'CC/NIT',
    ),
    const CampoFormulario(
      'nombres',
      'Nombres',
      required: true,
      hint: 'Ej. Juan',
    ),
    const CampoFormulario('apellidos', 'Apellidos', required: true),
    const CampoFormulario(
      'fechaNacimiento',
      'Fecha de nacimiento',
      kind: TipoCampo.fecha,
    ),
    const CampoFormulario('celular', 'Celular', tituloSeccion: 'CONTACTO'),
    const CampoFormulario('correo', 'Correo', kind: TipoCampo.correo),
  ],
  ModuloGestion.profesionales => [
    const CampoFormulario(
      'documento',
      'Documento',
      required: true,
      tituloSeccion: 'DATOS PERSONALES',
    ),
    const CampoFormulario('nombres', 'Nombres', required: true),
    const CampoFormulario('apellidos', 'Apellidos'),
    const CampoFormulario(
      'fechaNacimiento',
      'Fecha de nacimiento',
      kind: TipoCampo.fecha,
    ),
    const CampoFormulario(
      'porcentaje',
      'Comisión (%)',
      required: true,
      kind: TipoCampo.decimal,
      min: 0,
      max: 100,
      tituloSeccion: 'DATOS LABORALES',
    ),
    if (!esEdicion)
      const CampoFormulario(
        'especialidad',
        'Especialidad',
        required: true,
        kind: TipoCampo.seleccion,
        origen: ModuloGestion.especialidades,
      ),
    if (esEdicion)
      const CampoFormulario('estado', 'Activo', kind: TipoCampo.interruptor),
  ],
  ModuloGestion.servicios => [
    const CampoFormulario(
      'nombre',
      'Nombre',
      required: true,
      maxLength: 50,
      tituloSeccion: 'DATOS DEL SERVICIO',
    ),
    const CampoFormulario(
      'precio',
      'Precio',
      required: true,
      kind: TipoCampo.entero,
      min: 0,
      max: 2147483647,
    ),
    const CampoFormulario(
      'duracion',
      'Duración (minutos)',
      required: true,
      kind: TipoCampo.entero,
      min: 1,
      max: 1440,
    ),
    if (!esEdicion)
      const CampoFormulario(
        'descripcion',
        'Descripción',
        kind: TipoCampo.textoLargo,
      ),
    if (!esEdicion)
      const CampoFormulario(
        'especialidad',
        'Especialidad',
        required: true,
        kind: TipoCampo.seleccion,
        origen: ModuloGestion.especialidades,
        tituloSeccion: 'ESPECIALIDAD',
      ),
    if (esEdicion)
      const CampoFormulario('activo', 'Activo', kind: TipoCampo.interruptor),
  ],
  ModuloGestion.especialidades => [
    const CampoFormulario(
      'nombre',
      'Nombre',
      required: true,
      hint: 'Ej. Barbería',
      maxLength: 100,
    ),
  ],
  ModuloGestion.reservas => [
    const CampoFormulario(
      'clienteId',
      'Cliente',
      required: true,
      kind: TipoCampo.seleccion,
      origen: ModuloGestion.clientes,
      tituloSeccion: 'CLIENTE',
    ),
    const CampoFormulario(
      'servicioId',
      'Servicio',
      required: true,
      kind: TipoCampo.seleccion,
      origen: ModuloGestion.servicios,
      tituloSeccion: 'SERVICIO',
    ),
    if (esEdicion)
      const CampoFormulario(
        'profesionalId',
        'Profesional',
        kind: TipoCampo.seleccion,
        origen: ModuloGestion.profesionales,
        tituloSeccion: 'PROFESIONAL Y HORARIO',
      ),
    CampoFormulario(
      'fechaDia',
      'Fecha',
      required: true,
      kind: TipoCampo.fecha,
      tituloSeccion: esEdicion ? null : 'PROFESIONAL Y HORARIO',
    ),
    const CampoFormulario(
      'hora',
      'Horario',
      required: true,
      kind: TipoCampo.hora,
    ),
  ],
  ModuloGestion.horarios => [
    if (!esEdicion)
      const CampoFormulario(
        'profesionalId',
        'Profesional',
        required: true,
        kind: TipoCampo.seleccion,
        origen: ModuloGestion.profesionales,
        tituloSeccion: 'PROFESIONAL',
      ),
    if (!esEdicion)
      const CampoFormulario(
        'dia',
        'Día',
        required: true,
        kind: TipoCampo.seleccion,
        tituloSeccion: 'DÍA',
        opciones: {
          'lunes': 'Lunes',
          'martes': 'Martes',
          'miercoles': 'Miércoles',
          'jueves': 'Jueves',
          'viernes': 'Viernes',
          'sabado': 'Sábado',
          'domingo': 'Domingo',
        },
      ),
    const CampoFormulario(
      'horaInicio',
      'Hora de inicio',
      required: true,
      kind: TipoCampo.hora,
      tituloSeccion: 'JORNADA LABORAL',
    ),
    const CampoFormulario(
      'horaFin',
      'Hora de fin',
      required: true,
      kind: TipoCampo.hora,
    ),
    const CampoFormulario(
      'tieneAlmuerzo',
      'Tiene almuerzo',
      kind: TipoCampo.interruptor,
      tituloSeccion: 'ALMUERZO',
    ),
    const CampoFormulario(
      'horaInicioAlmuerzo',
      'Inicio almuerzo',
      kind: TipoCampo.hora,
    ),
    const CampoFormulario(
      'horaFinAlmuerzo',
      'Fin almuerzo',
      kind: TipoCampo.hora,
    ),
  ],
  ModuloGestion.inasistencias => [
    if (!esEdicion)
      const CampoFormulario(
        'profesionalId',
        'Profesional',
        required: true,
        kind: TipoCampo.seleccion,
        origen: ModuloGestion.profesionales,
      ),
    const CampoFormulario(
      'tipoFecha',
      'Tipo de fecha',
      required: true,
      kind: TipoCampo.seleccion,
      opciones: {'dia': 'Día específico', 'rango': 'Rango de fechas'},
    ),
    const CampoFormulario(
      'fechaInicio',
      'Fecha inicial',
      required: true,
      kind: TipoCampo.fecha,
    ),
    const CampoFormulario('fechaFin', 'Fecha final', kind: TipoCampo.fecha),
    const CampoFormulario(
      'motivoLabel',
      'Motivo',
      required: true,
      kind: TipoCampo.seleccion,
      opciones: {
        'salud': 'Salud',
        'familiar': 'Familiar',
        'otro': 'Otra causa justificada',
      },
    ),
    const CampoFormulario(
      'observacion',
      'Observación',
      kind: TipoCampo.textoLargo,
    ),
  ],
  ModuloGestion.cierres => [
    const CampoFormulario(
      'fechaInicio',
      'Inicio del período',
      required: true,
      kind: TipoCampo.fecha,
      tituloSeccion: 'PERÍODO DEL CIERRE',
    ),
    const CampoFormulario(
      'fechaFin',
      'Fin del período',
      required: true,
      kind: TipoCampo.fecha,
    ),
  ],
  ModuloGestion.comisiones => [],
};

String? validarCampo(CampoFormulario spec, Object? value, {DateTime? now}) {
  final text = value?.toString().trim() ?? '';
  if (spec.required && text.isEmpty) return 'Este campo es obligatorio.';
  if (text.isEmpty || spec.kind == TipoCampo.interruptor) return null;
  if (spec.maxLength != null && text.length > spec.maxLength!) {
    return 'Máximo ${spec.maxLength} caracteres.';
  }
  if (spec.kind == TipoCampo.correo &&
      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
    return 'Ingresa un correo válido.';
  }
  if (spec.key == 'celular' &&
      !RegExp(r'^\+?[0-9 ()-]{7,20}$').hasMatch(text)) {
    return 'Ingresa un celular válido.';
  }
  if (spec.kind == TipoCampo.entero || spec.kind == TipoCampo.decimal) {
    final n = spec.kind == TipoCampo.entero
        ? int.tryParse(text)
        : double.tryParse(text.replaceAll(',', '.'));
    if (n == null || !n.isFinite) {
      return 'Ingresa un número válido${spec.kind == TipoCampo.entero ? ' entero' : ''}.';
    }
    if (spec.min != null && n < spec.min!) {
      return 'El valor mínimo es ${spec.min}.';
    }
    if (spec.max != null && n > spec.max!) {
      return 'El valor máximo es ${spec.max}.';
    }
  }
  if (spec.kind == TipoCampo.fecha && DateTime.tryParse(text) == null) {
    return 'Selecciona una fecha válida.';
  }
  if (spec.kind == TipoCampo.hora && minutosDeHora(text) == null) {
    return 'Selecciona un horario válido.';
  }
  if (spec.key == 'fechaNacimiento') {
    final date = DateTime.tryParse(text);
    if (date == null || date.isAfter(now ?? DateTime.now())) {
      return 'La fecha no puede ser futura.';
    }
  }
  return null;
}
