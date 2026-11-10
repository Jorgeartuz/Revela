import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/domain/reservation.dart';
import '../domain/module.dart';
import '../data/management_repository.dart';
import 'shared.dart';
import 'operational_views.dart';
import 'record_form.dart';
import 'module_list.dart';

class RecordDetailPage extends StatefulWidget {
  const RecordDetailPage({
    super.key,
    required this.module,
    required this.row,
    required this.repository,
    this.readOnly = false,
    this.initialAction,
  });
  final Module module;
  final Map<String, dynamic> row;
  final ManagementRepository repository;
  final bool readOnly;
  final String? initialAction;
  @override
  State<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends State<RecordDetailPage> {
  @override
  void initState() {
    super.initState();
    if (widget.repository.preview && widget.initialAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.initialAction == 'cancel') _remove();
        if (widget.initialAction == 'attendance') _attendance();
      });
    }
  }

  bool _busy = false;
  bool _actionPending = false;
  String? _error;
  Map<String, dynamic> get row => widget.row;
  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RecordFormPage(
          module: widget.module,
          repository: widget.repository,
          initial: row,
          editing: true,
        ),
      ),
    );
    if (changed == true && mounted) Navigator.pop(context, true);
  }

  Future<void> _remove() async {
    if (_actionPending || _busy) return;
    _actionPending = true;
    try {
      final reservation = widget.module == Module.reservations;
      if (!await confirmAction(
            context,
            title: reservation
                ? '¿Cancelar reserva?'
                : '¿Eliminar ${widget.module.singular.toLowerCase()}?',
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
          builder: (context) => const _CancellationReasonDialog(),
        );
        if (reason == null || !mounted) return;
        body = {'motivoOtro': reason};
      }
      setState(() {
        _busy = true;
        _error = null;
      });
      try {
        await widget.repository.remove(
          widget.module,
          row['id'] as int,
          body: body,
        );
        if (!mounted) return;
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (context) => OperationSuccessPage(
              title: reservation ? 'Reserva cancelada' : 'Registro eliminado',
              message: 'El cambio se guardó correctamente.',
            ),
          ),
        );
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) setState(() => _error = errorMessage(e));
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    } finally {
      _actionPending = false;
    }
  }

  Future<void> _attendance() async {
    if (_actionPending || _busy) return;
    _actionPending = true;
    try {
      if (!await confirmAction(
            context,
            title: 'Confirmar asistencia',
            description: '¿El servicio de esta reserva fue atendido?',
            action: 'Confirmar',
          ) ||
          !mounted) {
        return;
      }
      if (widget.repository.preview) {
        final stored = widget.repository.memory[Module.reservations]!
            .where((r) => r['id'] == row['id'])
            .firstOrNull;
        if (stored != null) stored['estado'] = 2;
        setState(() => row['estado'] = 2);
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (context) => const OperationSuccessPage(
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
      _actionPending = false;
    }
  }

  void _open(Module module, {Map<String, String> filters = const {}}) =>
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (context) => ModuleListPage(
            module: module,
            repository: widget.repository,
            professionalId:
                module == Module.schedules || module == Module.absences
                ? row['id'] as int
                : null,
            readOnly: widget.readOnly,
            initialFilters: filters,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    final fields = <String, Object?>{};
    void add(String label, Object? value) {
      if (value != null && '$value'.isNotEmpty) fields[label] = value;
    }

    if (module == Module.customers || module == Module.professionals) {
      add('Documento', row['documento']);
      add('Nombres', row['nombres']);
      add('Apellidos', row['apellidos']);
      add(
        'Fecha de nacimiento',
        row['fechaNacimiento'] == null
            ? null
            : dateLabel(row['fechaNacimiento']),
      );
      add('Celular', row['celular']);
      add('Correo', row['correo']);
      if (module == Module.professionals) {
        add('Comisión', '${row['porcentaje'] ?? '—'}%');
        add(
          'Especialidad',
          row['especialidad'] is Map
              ? (row['especialidad'] as Map)['nombre']
              : null,
        );
        add('Estado', row['estado'] == true ? 'Activo' : 'Inactivo');
      }
    }
    if (module == Module.services || module == Module.specialties) {
      add('Nombre', row['nombre']);
      add('Descripción', row['descripcion']);
      if (module == Module.services) {
        add('Precio', money(row['precio']));
        add('Duración', '${row['duracion'] ?? '—'} min');
        add('Estado', row['activo'] == true ? 'Activo' : 'Inactivo');
      } else {
        add('Estado', row['activa'] == true ? 'Activa' : 'Inactiva');
      }
    }
    final states = widget.repository.preview
        ? const ReservationStates(
            scheduled: 0,
            confirmed: 1,
            attended: 2,
            cancelled: 3,
          )
        : ReservationStates.configured;
    final status = states.label(
      row['estado'] is int ? row['estado'] as int : null,
    );
    if (module == Module.reservations) {
      add('Cliente', personName(row['cliente']));
      add(
        'Servicio',
        row['servicio'] is Map ? (row['servicio'] as Map)['nombre'] : null,
      );
      add('Profesional', personName(row['profesional']));
      add('Fecha', dateLabel(row['fecha']));
      add('Horario', '${row['horaInicio'] ?? ''} – ${row['horaFin'] ?? ''}');
      add('Estado', status);
    }
    if (module == Module.schedules) {
      add(
        'Día',
        dayLabel(row['diaSemana'], preview: widget.repository.preview),
      );
      add('Inicio', row['horaInicio']);
      add('Fin', row['horaFin']);
      add(
        'Almuerzo',
        row['tieneAlmuerzo'] == true
            ? '${row['horaInicioAlmuerzo']} – ${row['horaFinAlmuerzo']}'
            : 'Sin almuerzo',
      );
    }
    if (module == Module.absences) {
      add('Desde', dateLabel(row['fechaInicio']));
      add('Hasta', dateLabel(row['fechaFin']));
      add('Observación', row['observacion']);
    }
    if (module == Module.closures) {
      add('Desde', dateLabel(row['fechaInicio']));
      add('Hasta', dateLabel(row['fechaFin']));
      add('Total del cierre', money(row['total']));
      add('Servicios', row['cantidadServicios']);
    }
    if (module == Module.commissions) {
      add('Profesional', personName(row['profesional']));
      add('Servicios realizados', row['cantidadServicios']);
      add('Base / total', money(row['base']));
      add('Comisión', '${row['porcentaje'] ?? '—'}%');
      add('Valor de comisión', money(row['valorComision']));
    }
    final completed = status == 'ATENDIDA' || status == 'CANCELADA';
    return SectionShell(
      title: 'Detalle de ${module.singular}',
      preview: widget.repository.preview,
      bottom: widget.readOnly
          ? ProfessionalNavigation(
              repository: widget.repository,
              selected: module == Module.commissions ? 2 : 1,
            )
          : SectionNavigation(
              module: module,
              onSelect: (target) {
                if (_busy) return;
                if (target == null) {
                  widget.repository.onHome?.call();
                  Navigator.popUntil(context, (r) => r.isFirst);
                } else {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => target == Module.specialties
                          ? ManagementMenuPage(repository: widget.repository)
                          : ModuleListPage(
                              module: target,
                              repository: widget.repository,
                            ),
                    ),
                  );
                }
              },
            ),
      child: ListView(
        padding: const EdgeInsets.all(21),
        children: [
          if (_error != null) infoBox(_error!),
          if (module == Module.customers || module == Module.professionals) ...[
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary,
              child: Text(
                initials(recordName(row)),
                style: const TextStyle(color: AppColors.background),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              recordName(row),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
          ],
          if (module == Module.reservations)
            ReservationPanels(row: row, repository: widget.repository)
          else if (module == Module.closures || module == Module.commissions)
            SettlementPanels(
              row: row,
              repository: widget.repository,
              commission: module == Module.commissions,
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '#${row['id']}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final entry in fields.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                color: AppColors.muted,
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
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (!widget.readOnly && module.canEdit && !completed)
            FilledButton(
              onPressed: _busy ? null : _edit,
              child: Text(
                module == Module.reservations
                    ? 'Reagendar'
                    : 'Editar ${module.singular.toLowerCase()}',
              ),
            ),
          if (module == Module.professionals) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _open(Module.schedules),
              child: const Text('Horario de trabajo'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _open(Module.absences),
              child: const Text('Inasistencias'),
            ),
          ],
          if (module == Module.closures) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _open(
                Module.commissions,
                filters: {'liquidacionComisionId': '${row['id']}'},
              ),
              child: const Text('Ver comisiones del cierre'),
            ),
          ],
          if (module == Module.reservations &&
              !completed &&
              (!widget.readOnly || status == 'CONFIRMADA')) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy ? null : _attendance,
              child: const Text('Confirmar asistencia'),
            ),
          ],
          if (!widget.readOnly && module.canDelete && !completed) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
              ),
              onPressed: _busy ? null : _remove,
              child: Text(
                module == Module.reservations
                    ? 'Cancelar Reserva'
                    : 'Eliminar ${module.singular.toLowerCase()}',
              ),
            ),
          ],
          if (widget.readOnly && module == Module.reservations)
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver a mi agenda'),
            ),
          if (module == Module.reservations && !widget.readOnly) ...[
            section('HISTORIAL'),
            infoBox(
              widget.repository.preview ? 'Reserva creada · datos de ejemplo' : 'El historial de cambios no está disponible para esta reserva.',
            ),
          ],
        ],
      ),
    );
  }
}

class _CancellationReasonDialog extends StatefulWidget {
  const _CancellationReasonDialog();
  @override
  State<_CancellationReasonDialog> createState() =>
      _CancellationReasonDialogState();
}

class _CancellationReasonDialogState extends State<_CancellationReasonDialog> {
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
