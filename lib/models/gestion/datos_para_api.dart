import 'package:revela/models/clientes/cliente.dart';
import 'package:revela/models/reservas/solicitud_reserva.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/models/gestion/valores_registro.dart';
import 'package:revela/services/remote/servicio_gestion.dart';

Map<String, dynamic> prepararDatosEnvio(
  ModuloGestion modulo,
  Map<String, dynamic> valores, {
  bool esEdicion = false,
  Map<String, int>? diasSemana,
  Map<String, int>? motivosInasistencia,
}) {
  final datosEnvio = Map<String, dynamic>.from(valores);
  if (modulo == ModuloGestion.clientes) {
    final cliente = Cliente.fromJson(datosEnvio);
    return cliente.toJson();
  }
  if (modulo == ModuloGestion.profesionales && !esEdicion) {
    datosEnvio['estado'] = true;
  }
  if (modulo == ModuloGestion.reservas) {
    final fecha = datosEnvio.remove('fechaDia');
    final hora = datosEnvio.remove('hora');
    if (fecha is! String || DateTime.tryParse(fecha) == null) {
      throw const ErrorGestion('Selecciona una fecha válida para la reserva.');
    }
    if (hora is! String || minutosDeHora(hora) == null) {
      throw const ErrorGestion('Selecciona un horario válido para la reserva.');
    }
    final fechaSeleccionada = DateTime.tryParse('${fecha}T$hora');
    if (fechaSeleccionada == null) {
      throw const ErrorGestion(
        'La fecha y el horario de la reserva no son válidos.',
      );
    }
    if (!esEdicion && fechaSeleccionada.isBefore(DateTime.now())) {
      throw const ErrorGestion(
        'La reserva debe ser para una fecha y hora futuras.',
      );
    }
    final clienteId = datosEnvio['clienteId'];
    final servicioId = datosEnvio['servicioId'];
    if (clienteId is! int || servicioId is! int) {
      throw const ErrorGestion(
        'Selecciona un cliente y un servicio para la reserva.',
      );
    }
    final solicitud = SolicitudReserva(
      fecha: fechaSeleccionada,
      servicioId: servicioId,
      clienteId: clienteId,
      profesionalId: esEdicion ? datosEnvio['profesionalId'] as int? : null,
    );
    return solicitud.toJson();
  }
  if (modulo == ModuloGestion.horarios) {
    final inicio = datosEnvio['horaInicio'] as String;
    final fin = datosEnvio['horaFin'] as String;
    if (minutosDeHora(inicio) == null ||
        minutosDeHora(fin) == null ||
        minutosDeHora(inicio)! >= minutosDeHora(fin)!) {
      throw const ErrorGestion(
        'La hora de inicio debe ser anterior a la hora de fin.',
      );
    }
    if (datosEnvio['tieneAlmuerzo'] == true) {
      final inicioAlmuerzo = datosEnvio['horaInicioAlmuerzo'] as String?;
      final finAlmuerzo = datosEnvio['horaFinAlmuerzo'] as String?;
      if (inicioAlmuerzo == null ||
          finAlmuerzo == null ||
          minutosDeHora(inicioAlmuerzo) == null ||
          minutosDeHora(finAlmuerzo) == null ||
          minutosDeHora(inicioAlmuerzo)! < minutosDeHora(inicio)! ||
          minutosDeHora(finAlmuerzo)! > minutosDeHora(fin)! ||
          minutosDeHora(inicioAlmuerzo)! >= minutosDeHora(finAlmuerzo)!) {
        throw const ErrorGestion(
          'El almuerzo debe estar dentro de la jornada, con inicio anterior al fin.',
        );
      }
    } else {
      datosEnvio['horaInicioAlmuerzo'] = null;
      datosEnvio['horaFinAlmuerzo'] = null;
    }
    if (!esEdicion) {
      final codigosPorDia = diasSemana ?? codigosDiasSemana();
      final codigo = codigosPorDia[datosEnvio.remove('dia')];
      if (codigo is! int || codigo < 0 || codigo > 6) {
        throw const ErrorGestion(
          'La configuración de días laborales aún no está habilitada para este centro.',
        );
      }
      datosEnvio['diaSemana'] = codigo;
    }
  }
  if (modulo == ModuloGestion.inasistencias) {
    final esDiaUnico = datosEnvio.remove('tipoFecha') == 'dia';
    final inicio = DateTime.parse(datosEnvio['fechaInicio'] as String);
    final fin = esDiaUnico
        ? inicio
        : DateTime.tryParse(datosEnvio['fechaFin']?.toString() ?? '');
    if (fin == null || fin.isBefore(inicio)) {
      throw const ErrorGestion(
        'La fecha final debe ser igual o posterior a la inicial.',
      );
    }
    final motivoElegido = datosEnvio.remove('motivoLabel');
    final codigos = motivosInasistencia ?? codigosMotivosInasistencia();
    final codigo = codigos[motivoElegido];
    if (codigo == null || codigo < 0 || codigo > 4) {
      throw const ErrorGestion(
        'El registro de motivos aún no está habilitado para este centro.',
      );
    }
    datosEnvio['motivo'] = codigo;
    final periodo = {
      'fechaInicio': inicio.toIso8601String(),
      'fechaFin': fin
          .add(const Duration(days: 1))
          .subtract(const Duration(seconds: 1))
          .toIso8601String(),
    };
    datosEnvio.remove('fechaInicio');
    datosEnvio.remove('fechaFin');
    if (esEdicion) {
      datosEnvio.addAll(periodo);
    } else {
      datosEnvio['periodos'] = [periodo];
    }
  }
  if (modulo == ModuloGestion.cierres) {
    final inicio = DateTime.parse(datosEnvio['fechaInicio'] as String);
    final fin = DateTime.parse(datosEnvio['fechaFin'] as String);
    if (fin.isBefore(inicio)) {
      throw const ErrorGestion(
        'El fin del período no puede ser anterior al inicio.',
      );
    }
    if (fin.isAfter(DateTime.now())) {
      throw const ErrorGestion('No se puede cerrar un período futuro.');
    }
  }
  return datosEnvio;
}
