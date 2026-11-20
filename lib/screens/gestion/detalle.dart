import 'package:revela/routes/rutas_aplicacion.dart';
import 'package:revela/models/navegacion/argumentos_gestion.dart';
import 'package:revela/screens/gestion/operacion_exitosa.dart';
import 'package:revela/screens/profesional/navegacion_profesional.dart';
import 'package:revela/widgets/gestion/secciones_detalle.dart';
import 'package:flutter/material.dart';

import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/services/remote/servicio_gestion.dart';
import 'package:revela/widgets/gestion/componentes_compartidos.dart';
import 'package:revela/screens/gestion/listado.dart';

class PantallaDetalle extends StatefulWidget {
  const PantallaDetalle({
    super.key,
    required this.modulo,
    required this.registro,
    required this.servicio,
    this.soloLectura = false,
  });
  final ModuloGestion modulo;
  final Map<String, dynamic> registro;
  final ServicioGestion servicio;
  final bool soloLectura;
  @override
  State<PantallaDetalle> createState() => _EstadoPantallaDetalle();
}

class _EstadoPantallaDetalle extends State<PantallaDetalle> {
  bool _procesando = false;
  bool _accionPendiente = false;
  String? _error;
  Map<String, dynamic> get registro => widget.registro;
  Future<void> _editar() async {
    final changed = await Navigator.push<bool>(
      context,
      RutasAplicacion.formulario(
        ArgumentosFormulario(
          modulo: widget.modulo,
          servicio: widget.servicio,
          datosIniciales: registro,
          esEdicion: true,
        ),
      ),
    );
    if (changed == true && mounted) Navigator.pop(context, true);
  }

  Future<void> _eliminar() async {
    if (_accionPendiente || _procesando) return;
    _accionPendiente = true;
    try {
      final reservation = widget.modulo == ModuloGestion.reservas;
      if (!await confirmarAccion(
            context,
            title: reservation
                ? '¿Cancelar reserva?'
                : '¿Eliminar ${widget.modulo.nombreSingular.toLowerCase()}?',
            description: reservation
                ? 'La reserva se cancelará. Esta acción no se puede deshacer.'
                : 'Confirma que quieres eliminar este registro. El servicio puede impedirlo si tiene información asociada.',
            action: reservation ? 'Cancelar reserva' : 'Eliminar',
          ) ||
          !mounted) {
        return;
      }
      Map<String, dynamic>? body;
      if (reservation) {
        final reason = await showDialog<String>(
          context: context,
          builder: (context) => const _DialogoMotivoCancelacion(),
        );
        if (reason == null || !mounted) return;
        body = {'motivoOtro': reason};
      }
      setState(() {
        _procesando = true;
        _error = null;
      });
      try {
        await widget.servicio.eliminar(
          widget.modulo,
          registro['id'] as int,
          body: body,
        );
        if (!mounted) return;
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (context) => PantallaOperacionExitosa(
              title: reservation ? 'Reserva cancelada' : 'Registro eliminado',
              message: 'El cambio se guardó correctamente.',
            ),
          ),
        );
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) setState(() => _error = mensajeError(e));
      } finally {
        if (mounted) setState(() => _procesando = false);
      }
    } finally {
      _accionPendiente = false;
    }
  }

  void _abrir(ModuloGestion modulo, {Map<String, String> filtros = const {}}) =>
      Navigator.push<void>(
        context,
        RutasAplicacion.listado(
          ArgumentosListado(
            modulo: modulo,
            servicio: widget.servicio,
            idProfesional:
                modulo == ModuloGestion.horarios ||
                    modulo == ModuloGestion.inasistencias
                ? registro['id'] as int
                : null,
            soloLectura: widget.soloLectura,
            filtrosIniciales: filtros,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final modulo = widget.modulo;
    final campos = <String, Object?>{};
    void add(String label, Object? value) {
      if (value != null && '$value'.isNotEmpty) campos[label] = value;
    }

    if (modulo == ModuloGestion.clientes ||
        modulo == ModuloGestion.profesionales) {
      add('Documento', registro['documento']);
      add('Nombres', registro['nombres']);
      add('Apellidos', registro['apellidos']);
      add(
        'Fecha de nacimiento',
        registro['fechaNacimiento'] == null
            ? null
            : formatoFecha(registro['fechaNacimiento']),
      );
      add('Celular', registro['celular']);
      add('Correo', registro['correo']);
      if (modulo == ModuloGestion.profesionales) {
        add('Comisión', '${registro['porcentaje'] ?? '—'}%');
        add(
          'Especialidad',
          registro['especialidad'] is Map
              ? (registro['especialidad'] as Map)['nombre']
              : null,
        );
        add('Estado', registro['estado'] == true ? 'Activo' : 'Inactivo');
      }
    }
    if (modulo == ModuloGestion.servicios ||
        modulo == ModuloGestion.especialidades) {
      add('Nombre', registro['nombre']);
      add('Descripción', registro['descripcion']);
      if (modulo == ModuloGestion.servicios) {
        add('Precio', formatoMoneda(registro['precio']));
        add('Duración', '${registro['duracion'] ?? '—'} min');
        add('Estado', registro['activo'] == true ? 'Activo' : 'Inactivo');
      } else {
        add('Estado', registro['activa'] == true ? 'Activa' : 'Inactiva');
      }
    }
    final states = widget.servicio.estadosReserva;
    final status = states.label(
      registro['estado'] is int ? registro['estado'] as int : null,
    );
    if (modulo == ModuloGestion.reservas) {
      add('Cliente', nombrePersona(registro['cliente']));
      add(
        'Servicio',
        registro['servicio'] is Map
            ? (registro['servicio'] as Map)['nombre']
            : null,
      );
      add('Profesional', nombrePersona(registro['profesional']));
      add('Fecha', formatoFecha(registro['fecha']));
      add(
        'Horario',
        '${registro['horaInicio'] ?? ''} – ${registro['horaFin'] ?? ''}',
      );
      add('Estado', status);
    }
    if (modulo == ModuloGestion.horarios) {
      add('Día', nombreDia(registro['diaSemana']));
      add('Inicio', registro['horaInicio']);
      add('Fin', registro['horaFin']);
      add(
        'Almuerzo',
        registro['tieneAlmuerzo'] == true
            ? '${registro['horaInicioAlmuerzo']} – ${registro['horaFinAlmuerzo']}'
            : 'Sin almuerzo',
      );
    }
    if (modulo == ModuloGestion.inasistencias) {
      add('Desde', formatoFecha(registro['fechaInicio']));
      add('Hasta', formatoFecha(registro['fechaFin']));
      add('Observación', registro['observacion']);
    }
    if (modulo == ModuloGestion.cierres) {
      add('Desde', formatoFecha(registro['fechaInicio']));
      add('Hasta', formatoFecha(registro['fechaFin']));
      add('Total facturado', formatoMoneda(registro['totalFacturado']));
      add(
        'Comisión del negocio',
        formatoMoneda(registro['subtotalComisionNegocio']),
      );
      add(
        'Comisión de profesionales',
        formatoMoneda(registro['subtotalComisionProfesionales']),
      );
    }
    if (modulo == ModuloGestion.comisiones) {
      add('Profesional', nombrePersona(registro['profesional']));
      add('Servicios realizados', registro['cantidadServicios']);
      add('Base / total', formatoMoneda(registro['base']));
      add('Comisión', '${registro['porcentaje'] ?? '—'}%');
      add('Valor de comisión', formatoMoneda(registro['valorComision']));
    }
    return SectionShell(
      title: 'Detalle de ${modulo.nombreSingular}',

      bottom: widget.soloLectura
          ? NavegacionProfesional(
              servicio: widget.servicio,
              selected: modulo == ModuloGestion.comisiones ? 2 : 1,
            )
          : SectionNavigation(
              modulo: modulo,
              onSelect: (target) {
                if (_procesando) return;
                if (target == null) {
                  widget.servicio.alIrAlInicio?.call();
                  Navigator.popUntil(context, (r) => r.isFirst);
                } else {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          target == ModuloGestion.especialidades
                          ? PantallaMenuGestion(servicio: widget.servicio)
                          : PantallaListado(
                              modulo: target,
                              servicio: widget.servicio,
                            ),
                    ),
                  );
                }
              },
            ),
      child: ListView(
        padding: const EdgeInsets.all(21),
        children: [
          if (_error != null) cuadroInformacion(_error!),
          if (modulo == ModuloGestion.clientes ||
              modulo == ModuloGestion.profesionales) ...[
            CircleAvatar(
              radius: 28,
              backgroundColor: ColoresAplicacion.principal,
              child: Text(
                iniciales(nombreRegistro(registro)),
                style: const TextStyle(color: ColoresAplicacion.fondo),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              nombreRegistro(registro),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
          ],
          if (modulo == ModuloGestion.reservas)
            SeccionesReserva(registro: registro, servicio: widget.servicio)
          else if (modulo == ModuloGestion.cierres ||
              modulo == ModuloGestion.comisiones)
            SeccionesLiquidacion(
              registro: registro,
              servicio: widget.servicio,
              commission: modulo == ModuloGestion.comisiones,
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColoresAplicacion.superficie,
                border: Border.all(color: ColoresAplicacion.borde),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '#${registro['id']}',
                    style: const TextStyle(
                      color: ColoresAplicacion.textoSecundario,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final entry in campos.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                color: ColoresAplicacion.textoSecundario,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${entry.value}',
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (_procesando) const Center(child: CircularProgressIndicator()),
          if (!widget.soloLectura && modulo.puedeEditar)
            FilledButton(
              onPressed: _procesando ? null : _editar,
              child: Text(
                modulo == ModuloGestion.reservas
                    ? 'Editar reserva'
                    : 'Editar ${modulo.nombreSingular.toLowerCase()}',
              ),
            ),
          if (modulo == ModuloGestion.profesionales) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _abrir(ModuloGestion.horarios),
              child: const Text('Horario de trabajo'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _abrir(ModuloGestion.inasistencias),
              child: const Text('Inasistencias'),
            ),
          ],
          if (modulo == ModuloGestion.cierres) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _abrir(
                ModuloGestion.comisiones,
                filtros: {'liquidacionComisionId': '${registro['id']}'},
              ),
              child: const Text('Ver comisiones del cierre'),
            ),
          ],
          if (!widget.soloLectura && modulo.puedeEliminar) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
              ),
              onPressed: _procesando ? null : _eliminar,
              child: Text(
                modulo == ModuloGestion.reservas
                    ? 'Cancelar Reserva'
                    : 'Eliminar ${modulo.nombreSingular.toLowerCase()}',
              ),
            ),
          ],
          if (widget.soloLectura && modulo == ModuloGestion.reservas)
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver a mi agenda'),
            ),
          if (modulo == ModuloGestion.reservas && !widget.soloLectura) ...[
            tituloSeccion('HISTORIAL'),
            cuadroInformacion(
              'El historial de cambios no está disponible para esta reserva.',
            ),
          ],
        ],
      ),
    );
  }
}

class _DialogoMotivoCancelacion extends StatefulWidget {
  const _DialogoMotivoCancelacion();
  @override
  State<_DialogoMotivoCancelacion> createState() =>
      _EstadoDialogoMotivoCancelacion();
}

class _EstadoDialogoMotivoCancelacion extends State<_DialogoMotivoCancelacion> {
  final controller = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Motivo de cancelación'),
    content: Form(
      key: form,
      child: TextFormField(
        controller: controller,
        maxLength: 300,
        decoration: const InputDecoration(labelText: 'Motivo'),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Indica el motivo de cancelación.'
            : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Volver'),
      ),
      TextButton(
        onPressed: () {
          if (form.currentState!.validate()) {
            Navigator.pop(context, controller.text.trim());
          }
        },
        child: const Text('Confirmar cancelación'),
      ),
    ],
  );
}
