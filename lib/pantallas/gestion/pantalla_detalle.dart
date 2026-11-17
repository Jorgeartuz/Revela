import 'package:revela/pantallas/gestion/pantalla_operacion_exitosa.dart';
import 'package:revela/pantallas/profesional/navegacion_profesional.dart';
import 'package:revela/componentes/gestion/secciones_detalle.dart';
import 'package:flutter/material.dart';

import 'package:revela/configuracion/tema_aplicacion.dart';
import 'package:revela/modelos/inicio/reserva.dart';
import 'package:revela/modelos/gestion/modulo_gestion.dart';
import 'package:revela/servicios/remoto/servicio_gestion.dart';
import 'package:revela/componentes/gestion/componentes_compartidos.dart';
import 'package:revela/pantallas/gestion/pantalla_formulario.dart';
import 'package:revela/pantallas/gestion/pantalla_listado.dart';

/// Muestra los datos del registro y sus acciones permitidas.
class PantallaDetalle extends StatefulWidget {
  const PantallaDetalle({
    super.key,
    required this.modulo,
    required this.registro,
    required this.servicio,
    this.soloLectura = false,
    this.accionInicial,
  });
  final ModuloGestion modulo;
  final Map<String, dynamic> registro;
  final ServicioGestion servicio;
  final bool soloLectura;
  final String? accionInicial;
  @override
  State<PantallaDetalle> createState() => _EstadoPantallaDetalle();
}

class _EstadoPantallaDetalle extends State<PantallaDetalle> {
  @override
  void initState() {
    super.initState();
    if (widget.servicio.vistaPrevia && widget.accionInicial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.accionInicial == 'cancel') _eliminar();
        if (widget.accionInicial == 'attendance') _confirmarAsistencia();
      });
    }
  }

  bool _procesando = false;
  bool _accionPendiente = false;
  String? _error;
  Map<String, dynamic> get registro => widget.registro;
  Future<void> _editar() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaFormulario(
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

  Future<void> _confirmarAsistencia() async {
    if (_accionPendiente || _procesando) return;
    _accionPendiente = true;
    try {
      if (!await confirmarAccion(
            context,
            title: 'Confirmar asistencia',
            description: '¿El servicio de esta reserva fue atendido?',
            action: 'Confirmar',
          ) ||
          !mounted) {
        return;
      }
      if (widget.servicio.vistaPrevia) {
        final stored = widget.servicio.memoria[ModuloGestion.reservas]!
            .where((r) => r['id'] == registro['id'])
            .firstOrNull;
        if (stored != null) stored['estado'] = 2;
        setState(() => registro['estado'] = 2);
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (context) => const PantallaOperacionExitosa(
              title: 'Asistencia confirmada',
              message: 'Cambio aplicado en la vista de diseño.',
            ),
          ),
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar asistencia'),
            content: const Text(
              'La confirmación de asistencia todavía no está habilitada para este centro. Contacta al administrador.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    } finally {
      _accionPendiente = false;
    }
  }

  void _abrir(ModuloGestion modulo, {Map<String, String> filtros = const {}}) =>
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (context) => PantallaListado(
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
    final states = widget.servicio.vistaPrevia
        ? const EstadosReserva(
            programada: 0,
            confirmada: 1,
            atendida: 2,
            cancelada: 3,
          )
        : EstadosReserva.configurados;
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
      add(
        'Día',
        nombreDia(
          registro['diaSemana'],
          vistaPrevia: widget.servicio.vistaPrevia,
        ),
      );
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
      add('Total del cierre', formatoMoneda(registro['total']));
      add('Servicios', registro['cantidadServicios']);
    }
    if (modulo == ModuloGestion.comisiones) {
      add('Profesional', nombrePersona(registro['profesional']));
      add('Servicios realizados', registro['cantidadServicios']);
      add('Base / total', formatoMoneda(registro['base']));
      add('Comisión', '${registro['porcentaje'] ?? '—'}%');
      add('Valor de comisión', formatoMoneda(registro['valorComision']));
    }
    final completed = status == 'ATENDIDA' || status == 'CANCELADA';
    return SectionShell(
      title: 'Detalle de ${modulo.nombreSingular}',
      vistaPrevia: widget.servicio.vistaPrevia,
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
          if (!widget.soloLectura && modulo.puedeEditar && !completed)
            FilledButton(
              onPressed: _procesando ? null : _editar,
              child: Text(
                modulo == ModuloGestion.reservas
                    ? 'Reagendar'
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
          if (modulo == ModuloGestion.reservas &&
              !completed &&
              (!widget.soloLectura || status == 'CONFIRMADA')) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _procesando ? null : _confirmarAsistencia,
              child: const Text('Confirmar asistencia'),
            ),
          ],
          if (!widget.soloLectura && modulo.puedeEliminar && !completed) ...[
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
              widget.servicio.vistaPrevia
                  ? 'Reserva creada · datos de ejemplo'
                  : 'El historial de cambios no está disponible para esta reserva.',
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
