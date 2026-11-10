import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/domain/reservation.dart';
import '../data/management_repository.dart';
import '../domain/module.dart';
import 'shared.dart';
import 'record_form.dart';
import 'record_detail.dart';

typedef Record = Map<String, dynamic>;
ReservationStates statesFor(ManagementRepository repo) => repo.preview
    ? const ReservationStates(
        scheduled: 0,
        confirmed: 1,
        attended: 2,
        cancelled: 3,
      )
    : ReservationStates.configured;
String clockLabel(Object? value) {
  final parts = value?.toString().split(':') ?? [];
  if (parts.length < 2) return '—';
  final hour = int.tryParse(parts[0]);
  if (hour == null) return '—';
  return '${hour % 12 == 0 ? 12 : hour % 12}:${parts[1]} ${hour < 12 ? 'AM' : 'PM'}';
}

Record nested(Record row, String key) =>
    row[key] is Map ? Map<String, dynamic>.from(row[key] as Map) : {};
Widget panel(Widget child, {bool accent = false}) => Container(
  margin: const EdgeInsets.only(bottom: 12),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: accent
        ? AppColors.primary.withValues(alpha: .12)
        : AppColors.surface,
    border: Border.all(color: accent ? AppColors.primary : AppColors.border),
    borderRadius: BorderRadius.circular(14),
  ),
  child: child,
);
Widget pair(String label, Object? value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 5),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          '${value ?? '—'}',
          textAlign: TextAlign.end,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    ],
  ),
);
Widget profileCard(Record? profile) => panel(
  Row(
    children: [
      CircleAvatar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        child: Text(
          initials(profile == null ? 'Profesional' : recordName(profile)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(profile == null ? 'Profesional' : recordName(profile)),
            const SizedBox(height: 3),
            Text(
              'CC ${profile?['documento'] ?? '—'} · ${nested(profile ?? {}, 'especialidad')['nombre'] ?? 'Especialidad sin informar'}',
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
      ),
    ],
  ),
);
Widget totals(List<(String, String)> items) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    for (final item in items)
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.$2,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item.$1,
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
  ],
);

/// Dedicated layouts for the agenda, weekly timetable, absences and commission consolidated screens.
class OperationalView extends StatefulWidget {
  const OperationalView({
    super.key,
    required this.module,
    required this.repository,
    this.professionalId,
    this.readOnly = false,
    this.filters = const {},
    this.onHome,
  });
  final Module module;
  final ManagementRepository repository;
  final int? professionalId;
  final bool readOnly;
  final Map<String, String> filters;
  final VoidCallback? onHome;
  @override
  State<OperationalView> createState() => _OperationalViewState();
}

class _OperationalViewState extends State<OperationalView> {
  late Future<List<Record>> _future;
  Future<List<Record>>? _people, _closures;
  Future<Record?>? _profile;
  int? _professional, _closure;
  int? _status;
  String _query = '';
  DateTime _day = DateUtils.dateOnly(DateTime.now());
  @override
  void initState() {
    super.initState();
    _professional = widget.professionalId;
    _closure = int.tryParse(widget.filters['liquidacionComisionId'] ?? '');
    if (_professional != null) {
      _profile = widget.repository.professional(_professional!);
    }
    if (!widget.readOnly) {
      _people = widget.repository.list(Module.professionals);
    }
    if (widget.module == Module.commissions) {
      _closures = widget.repository.list(Module.closures);
    }
    _load();
  }

  void _load() {
    _future = widget.repository.list(
      widget.module,
      filters: {
        ...widget.filters,
        if (_professional != null) 'profesionalId': '$_professional',
        if (_closure != null) 'liquidacionComisionId': '$_closure',
        if (widget.module == Module.reservations)
          'fechaInicio': _day.toIso8601String(),
        if (widget.module == Module.reservations)
          'fechaFin': _day
              .add(const Duration(days: 1))
              .subtract(const Duration(seconds: 1))
              .toIso8601String(),
      },
    );
  }

  Future<void> _refresh() async {
    setState(_load);
    try {
      await _future;
    } catch (_) {}
  }

  Future<void> _form({Record? initial, bool editing = false}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RecordFormPage(
          module: widget.module,
          repository: widget.repository,
          initial:
              initial ??
              {if (_professional != null) 'profesionalId': _professional},
          editing: editing,
        ),
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  Future<void> _detail(Record row) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RecordDetailPage(
          module: widget.module,
          repository: widget.repository,
          row: row,
          readOnly: widget.readOnly,
        ),
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  Widget _professionalPicker() => FutureBuilder<List<Record>>(
    future: _people,
    builder: (context, s) {
      if (s.hasError) return infoBox(errorMessage(s.error));
      if (!s.hasData) return const LinearProgressIndicator();
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DropdownButtonFormField<int>(
          initialValue: _professional,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Profesional'),
          items: [
            if (widget.module != Module.schedules)
              const DropdownMenuItem<int>(
                value: null,
                child: Text('Todos los profesionales'),
              ),
            for (final p in s.data!)
              DropdownMenuItem(
                value: p['id'] as int,
                child: Text(recordName(p)),
              ),
          ],
          onChanged: (v) => setState(() {
            _professional = v;
            _profile = v == null ? null : widget.repository.professional(v);
            _load();
          }),
        ),
      );
    },
  );
  Widget _empty(String title, String message) => panel(
    Column(
      children: [
        const SizedBox(height: 16),
        const Icon(
          Icons.event_available_outlined,
          size: 42,
          color: AppColors.muted,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 16),
        if (widget.onHome != null)
          OutlinedButton(
            onPressed: widget.onHome,
            child: const Text('Volver al inicio'),
          ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _refresh,
    child: FutureBuilder<List<Record>>(
      future: _future,
      builder: (context, s) {
        if (s.hasError) {
          return ListView(
            padding: const EdgeInsets.all(21),
            children: [
              infoBox(errorMessage(s.error)),
              TextButton(onPressed: _refresh, child: const Text('Reintentar')),
            ],
          );
        }
        if (!s.hasData) {
          return ListView(
            children: const [
              Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(21, 16, 21, 32),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (widget.module == Module.reservations) ..._agenda(s.data!),
            if (widget.module == Module.schedules) ..._schedule(s.data!),
            if (widget.module == Module.absences) ..._absences(s.data!),
            if (widget.module == Module.commissions) ..._commissions(s.data!),
          ],
        );
      },
    ),
  );
  List<Widget> _agenda(List<Record> all) {
    final states = statesFor(widget.repository);
    final dayRows =
        all
            .where(
              (r) =>
                  DateUtils.isSameDay(DateTime.tryParse('${r['fecha']}'), _day),
            )
            .toList()
          ..sort(
            (a, b) => '${a['horaInicio']}'.compareTo('${b['horaInicio']}'),
          );
    final rows = dayRows
        .where(
          (r) =>
              (_status == null || r['estado'] == _status) &&
              '${personName(r['cliente'])} ${nested(r, 'servicio')['nombre']} ${personName(r['profesional'])}'
                  .toLowerCase()
                  .contains(_query.toLowerCase()),
        )
        .toList();
    String count(int? code) => code == null
        ? '—'
        : '${dayRows.where((r) => r['estado'] == code).length}';
    final monday = _day.subtract(Duration(days: _day.weekday - 1));
    return [
      if (widget.readOnly)
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: ChoiceChip(
                    labelPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'][i],
                      style: const TextStyle(fontSize: 10),
                    ),
                    selected: _day.weekday == i + 1,
                    onSelected: (_) => setState(() {
                      _day = monday.add(Duration(days: i));
                      _load();
                    }),
                  ),
                ),
              ),
          ],
        ),
      if (!widget.readOnly)
        TextField(
          decoration: const InputDecoration(
            hintText: 'Buscar cliente, servicio...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
      const SizedBox(height: 16),
      panel(
        totals([
          ('Citas del día', '${dayRows.length}'),
          ('Confirmadas', count(states.confirmed)),
          ('Pendientes', count(states.scheduled)),
        ]),
      ),
      Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Todas'),
            selected: _status == null,
            onSelected: (_) => setState(() => _status = null),
          ),
          for (final item in [
            ('Programada', states.scheduled),
            ('Confirmada', states.confirmed),
            ('Atendida', states.attended),
            ('Cancelada', states.cancelled),
          ])
            ChoiceChip(
              label: Text(item.$1),
              selected: item.$2 != null && _status == item.$2,
              onSelected: item.$2 == null
                  ? null
                  : (_) => setState(() => _status = item.$2),
            ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: section(
              DateFormat('EEEE · d MMMM', 'es').format(_day).toUpperCase(),
            ),
          ),
          IconButton(
            tooltip: 'Elegir fecha',
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _day,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (d != null && mounted) {
                setState(() {
                  _day = d;
                  _load();
                });
              }
            },
          ),
        ],
      ),
      if (!widget.readOnly && _people != null) _professionalPicker(),
      if (rows.isEmpty)
        _empty(
          widget.readOnly ? 'Sin citas para este día' : 'Sin reservas',
          'No hay citas que coincidan con los filtros seleccionados.',
        ),
      for (final r in rows)
        panel(
          InkWell(
            onTap: () => _detail(r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        clockLabel(r['horaInicio']),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      states.label(r['estado'] as int?) ??
                          'Estado por confirmar',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      child: Text(initials(personName(r['cliente']))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            personName(r['cliente']),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${nested(r, 'servicio')['nombre'] ?? 'Servicio'} · ${widget.readOnly ? '${nested(r, 'servicio')['duracion'] ?? '—'} min' : personName(r['profesional'])}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${nested(nested(r, 'profesional'), 'especialidad')['nombre'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      if (!widget.readOnly)
        Align(
          alignment: Alignment.centerRight,
          child: Tooltip(
            message: 'Crear reserva',
            child: FilledButton.icon(
              onPressed: () => _form(),
              icon: const Icon(Icons.add_circle),
              label: const Text('Reserva'),
            ),
          ),
        ),
    ];
  }

  List<Widget> _schedule(List<Record> all) {
    final rows = all
        .where(
          (r) => _professional == null || r['profesionalId'] == _professional,
        )
        .toList();
    const keys = [
      'lunes',
      'martes',
      'miercoles',
      'jueves',
      'viernes',
      'sabado',
      'domingo',
    ];
    const labels = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    final Map codes = widget.repository.preview
        ? {
            'lunes': 1,
            'martes': 2,
            'miercoles': 3,
            'jueves': 4,
            'viernes': 5,
            'sabado': 6,
            'domingo': 0,
          }
        : jsonDecode(
            const String.fromEnvironment('WEEKDAY_MAP', defaultValue: '{}'),
          ) as Map;
    Widget clockLine(String asset, String text, {bool muted = false}) =>
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/$asset.svg',
                width: 13,
                height: 13,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    color: muted ? AppColors.muted : AppColors.text,
                  ),
                ),
              ),
            ],
          ),
        );
    Widget day(Record? row, String label, {String? key}) => panel(
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14)),
                if (row == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Sin horario configurado',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  )
                else ...[
                  clockLine(
                    'schedule_clock',
                    '${clockLabel(row['horaInicio'])} – ${clockLabel(row['horaFin'])}',
                  ),
                  clockLine(
                    'schedule_lunch',
                    row['tieneAlmuerzo'] == true
                        ? 'Almuerzo ${clockLabel(row['horaInicioAlmuerzo'])} – ${clockLabel(row['horaFinAlmuerzo'])}'
                        : 'Sin almuerzo',
                    muted: true,
                  ),
                ],
              ],
            ),
          ),
          if (!widget.readOnly)
            IconButton(
              tooltip: row == null ? 'Configurar $label' : 'Editar $label',
              icon: Icon(
                row == null ? Icons.add : Icons.edit_outlined,
                size: 18,
              ),
              onPressed: _professional == null
                  ? null
                  : () => _form(
                      initial:
                          row ?? {'profesionalId': _professional, 'dia': key},
                      editing: row != null,
                    ),
            ),
        ],
      ),
    );
    return [
      section('PROFESIONAL'),
      if (!widget.readOnly && widget.professionalId == null)
        _professionalPicker(),
      if (_profile != null)
        FutureBuilder<Record?>(
          future: _profile,
          builder: (c, s) => profileCard(s.data),
        ),
      if (_professional == null)
        infoBox('Selecciona un profesional para ver su horario de trabajo.')
      else ...[
        section('HORARIO SEMANAL'),
        if (codes.length == 7)
          for (var i = 0; i < 7; i++)
            day(
              rows.where((r) => r['diaSemana'] == codes[keys[i]]).firstOrNull,
              labels[i],
              key: keys[i],
            )
        else ...[
          for (final r in rows) day(r, dayLabel(r['diaSemana'])),
          infoBox(
            'Los nombres de los días se mostrarán cuando el centro confirme su configuración.',
          ),
        ],
      ],
    ];
  }

  List<Widget> _absences(List<Record> rows) => [
    if (widget.readOnly) ...[
      section('PROFESIONAL'),
      FutureBuilder<Record?>(
        future: _profile,
        builder: (c, s) => profileCard(s.data),
      ),
    ] else if (_people != null)
      _professionalPicker(),
    section('${rows.length} INASISTENCIAS REGISTRADAS'),
    if (rows.isEmpty)
      _empty(
        'Sin inasistencias',
        'No tienes inasistencias registradas. Cuando se registre una ausencia por salud, situación familiar u otra causa justificada, aparecerá aquí.',
      ),
    for (final r in rows) _absence(r),
    if (!widget.readOnly)
      FilledButton.icon(
        onPressed: () => _form(),
        icon: const Icon(Icons.add),
        label: const Text('Registrar inasistencia'),
      ),
  ];
  Widget _absence(Record r) {
    final start = DateTime.tryParse('${r['fechaInicio']}'),
        end = DateTime.tryParse('${r['fechaFin']}');
    final range =
        start != null && end != null && !DateUtils.isSameDay(start, end);
    final duration = start == null || end == null
        ? null
        : DateUtils.dateOnly(end).difference(DateUtils.dateOnly(start)).inDays +
              1;
    final finished = end?.isBefore(DateTime.now()) ?? false;
    final motive = widget.repository.preview
        ? ['Salud', 'Familiar', 'Otra causa justificada'].elementAtOrNull(
            r['motivo'] is int && (r['motivo'] as int) >= 0
                ? r['motivo'] as int
                : 3,
          )
        : r['motivoNombre'];
    return panel(
      InkWell(
        onTap: widget.readOnly ? null : () => _detail(r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    range ? '↔ Rango de fechas' : 'Día específico',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                Text(
                  '${finished ? 'Finalizada' : 'Próxima'} · ${duration ?? '—'} ${duration == 1 ? 'día' : 'días'}',
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              range
                  ? '${dateLabel(r['fechaInicio'])} → ${dateLabel(r['fechaFin'])}'
                  : dateLabel(r['fechaInicio']),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              r['profesional'] is Map
                  ? personName(r['profesional'])
                  : 'Profesional #${r['profesionalId']}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Text(
              'Motivo: ${motive ?? r['observacion'] ?? 'Sin descripción'}',
              style: const TextStyle(fontSize: 12, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _commissions(List<Record> all) {
    final rows = all
        .where(
          (r) =>
              (_professional == null || r['profesionalId'] == _professional) &&
              (_closure == null ||
                  r['liquidacionComisionId'] == _closure ||
                  r['liquidacionId'] == _closure),
        )
        .toList();
    num sum(String key) =>
        rows.fold<num>(0, (v, r) => v + (r[key] is num ? r[key] as num : 0));
    return [
      if (_closures != null)
        FutureBuilder<List<Record>>(
          future: _closures,
          builder: (c, s) => s.hasData
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<int>(
                    initialValue: _closure,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Cierre'),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Todos los cierres'),
                      ),
                      for (final r in s.data!)
                        DropdownMenuItem(
                          value: r['id'] as int,
                          child: Text(
                            '#CIE-${r['id']} · ${dateLabel(r['fechaInicio'])} – ${dateLabel(r['fechaFin'])}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      _closure = v;
                      _load();
                    }),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      if (_people != null) _professionalPicker(),
      section('CONSOLIDADO DEL CIERRE'),
      panel(
        totals([
          ('Servicios', '${sum('cantidadServicios')}'),
          ('Base/total', money(sum('base'))),
          ('Comisiones', money(sum('valorComision'))),
        ]),
        accent: true,
      ),
      section('${rows.length} PROFESIONALES'),
      if (rows.isEmpty)
        _empty(
          'Sin comisiones',
          'No hay comisiones para el cierre y los filtros seleccionados.',
        ),
      for (final r in rows)
        panel(
          InkWell(
            onTap: () => _detail(r),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      child: Text(initials(personName(r['profesional']))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        personName(r['profesional']),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${r['porcentaje'] ?? '—'}%',
                      style: const TextStyle(fontSize: 11),
                    ),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
                const SizedBox(height: 14),
                totals([
                  ('Servicios realizados', '${r['cantidadServicios'] ?? '—'}'),
                  ('Base/total', money(r['base'])),
                  ('Valor comisión', money(r['valorComision'])),
                ]),
              ],
            ),
          ),
        ),
    ];
  }
}

/// Professional service history is deliberately separate from settled commissions.
class ProfessionalServicesView extends StatefulWidget {
  const ProfessionalServicesView({
    super.key,
    required this.repository,
    required this.professionalId,
  });
  final ManagementRepository repository;
  final int professionalId;
  @override
  State<ProfessionalServicesView> createState() =>
      _ProfessionalServicesViewState();
}

class _ProfessionalServicesViewState extends State<ProfessionalServicesView> {
  late Future<(Record?, List<Record>, List<Record>)> _future;
  DateTimeRange? _period;
  int? _service;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = () async {
      final profile = await widget.repository.professional(
        widget.professionalId,
      );
      final reservations = await widget.repository.list(
        Module.reservations,
        filters: {'profesionalId': '${widget.professionalId}'},
      );
      final services = await widget.repository.list(Module.services);
      return (profile, reservations, services);
    }();
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<(Record?, List<Record>, List<Record>)>(
    future: _future,
    builder: (c, s) {
      if (s.hasError) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            infoBox(errorMessage(s.error)),
            TextButton(
              onPressed: () => setState(_load),
              child: const Text('Reintentar'),
            ),
          ],
        );
      }
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      final (profile, reservations, services) = s.data!;
      final attended = statesFor(widget.repository).attended;
      final rows = reservations.where((r) {
        final d = DateTime.tryParse('${r['fecha']}');
        return attended != null &&
            r['estado'] == attended &&
            (_service == null || r['servicioId'] == _service) &&
            (_period == null ||
                (d != null &&
                    !d.isBefore(_period!.start) &&
                    d.isBefore(_period!.end.add(const Duration(days: 1)))));
      }).toList();
      final percentage = profile?['porcentaje'];
      final assigned = services
          .where(
            (r) =>
                profile?['especialidadId'] != null &&
                r['especialidadId'] == profile?['especialidadId'],
          )
          .toList();
      num? commission(Record r) =>
          nested(r, 'servicio')['precio'] is num && percentage is num
          ? (nested(r, 'servicio')['precio'] as num) * percentage / 100
          : null;
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '${profile == null ? 'Profesional' : recordName(profile)} · ${nested(profile ?? {}, 'especialidad')['nombre'] ?? 'Especialidad sin informar'}',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          section('SERVICIOS DE TU ESPECIALIDAD'),
          for (final service in assigned)
            panel(
              Column(
                children: [
                  pair('${service['nombre']}', money(service['precio'])),
                  pair(
                    '${service['duracion']} min · ${service['activo'] == true ? 'Activo' : 'Inactivo'}',
                    'Comisión ${percentage ?? '—'}%',
                  ),
                ],
              ),
            ),
          if (assigned.isEmpty)
            infoBox('No hay servicios de tu especialidad para mostrar.'),
          section('SERVICIOS REALIZADOS'),
          OutlinedButton(
            onPressed: () async {
              final r = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (r != null && mounted) setState(() => _period = r);
            },
            child: Text(
              _period == null
                  ? 'Seleccionar período'
                  : '${dateLabel(_period!.start)} – ${dateLabel(_period!.end)}',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _service,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Servicio'),
            items: [
              const DropdownMenuItem<int>(
                value: null,
                child: Text('Todos los servicios'),
              ),
              for (final r in services)
                DropdownMenuItem(
                  value: r['id'] as int,
                  child: Text('${r['nombre']}'),
                ),
            ],
            onChanged: (v) => setState(() => _service = v),
          ),
          const SizedBox(height: 16),
          if (attended == null)
            infoBox(
              'El centro debe confirmar la configuración de estados para identificar los servicios atendidos.',
            )
          else if (rows.isEmpty)
            infoBox('No hay servicios atendidos en este período.'),
          for (final r in rows)
            panel(
              Column(
                children: [
                  pair(
                    personName(r['cliente']),
                    money(nested(r, 'servicio')['precio']),
                  ),
                  pair(
                    '${nested(r, 'servicio')['nombre']} · ${dateLabel(r['fecha'])}',
                    '+${money(commission(r))} comisión',
                  ),
                ],
              ),
            ),
          panel(
            pair(
              'Comisión estimada del período',
              percentage is num
                  ? money(rows.fold<num>(0, (v, r) => v + (commission(r) ?? 0)))
                  : '—',
            ),
            accent: true,
          ),
          const Text(
            'La liquidación definitiva se consulta en el cierre del centro.',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      );
    },
  );
}

class ReservationPanels extends StatelessWidget {
  const ReservationPanels({
    super.key,
    required this.row,
    required this.repository,
  });
  final Record row;
  final ManagementRepository repository;
  @override
  Widget build(BuildContext context) {
    final client = nested(row, 'cliente'), service = nested(row, 'servicio');
    final status = statesFor(repository).label(row['estado'] as int?);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Chip(label: Text(status ?? 'Estado por confirmar')),
        ),
        section('CLIENTE'),
        panel(
          Column(
            children: [
              pair('Nombre', personName(row['cliente'])),
              pair('Documento', client['documento']),
              pair('Celular', client['celular']),
              pair('Correo', client['correo']),
            ],
          ),
        ),
        section('SERVICIO'),
        panel(
          Column(
            children: [
              pair('Servicio', service['nombre']),
              pair('Precio', money(service['precio'])),
              pair('Duración', '${service['duracion'] ?? '—'} min'),
              pair('Profesional', personName(row['profesional'])),
            ],
          ),
        ),
        section('DATOS DE LA RESERVA'),
        panel(
          Column(
            children: [
              pair('ID', '#RV-${row['id']}'),
              pair('Fecha', dateLabel(row['fecha'])),
              pair(
                'Hora',
                '${clockLabel(row['horaInicio'])} – ${clockLabel(row['horaFin'])}',
              ),
              if (row['fechaCreacion'] != null)
                pair('Creada el', dateLabel(row['fechaCreacion'])),
            ],
          ),
        ),
        if (status == 'CANCELADA')
          infoBox('Esta reserva fue cancelada. No admite más acciones.'),
        if (status == 'ATENDIDA')
          infoBox(
            'Este servicio ya fue atendido. La reserva no admite más cambios.',
          ),
      ],
    );
  }
}

class SettlementPanels extends StatefulWidget {
  const SettlementPanels({
    super.key,
    required this.row,
    required this.repository,
    required this.commission,
  });
  final Record row;
  final ManagementRepository repository;
  final bool commission;
  @override
  State<SettlementPanels> createState() => _SettlementPanelsState();
}

class _SettlementPanelsState extends State<SettlementPanels> {
  late Future<List<Record>> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.commission
        ? widget.repository.commissionServices(widget.row['id'] as int)
        : widget.repository.list(
            Module.commissions,
            filters: {'liquidacionComisionId': '${widget.row['id']}'},
          );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.row;
    return FutureBuilder<List<Record>>(
      future: _future,
      builder: (c, s) {
        final rows = s.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.commission) ...[
              panel(
                Column(
                  children: [
                    pair('Profesional', personName(r['profesional'])),
                    pair(
                      'Cierre',
                      '#CIE-${r['liquidacionComisionId'] ?? r['liquidacionId'] ?? '—'}',
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DefaultTextStyle(
                  style: const TextStyle(color: AppColors.background),
                  child: Column(
                    children: [
                      const Text('VALOR DE COMISIÓN'),
                      const SizedBox(height: 10),
                      Text(
                        money(r['valorComision']),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          for (final item in [
                            ('Servicios', '${r['cantidadServicios'] ?? '—'}'),
                            ('Comisión', '${r['porcentaje'] ?? '—'}%'),
                            ('Base/total', money(r['base'])),
                          ])
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    item.$2,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    item.$1,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              section('SERVICIOS REALIZADOS EN EL CIERRE'),
              for (final service in rows)
                panel(
                  Column(
                    children: [
                      pair(
                        personName(service['cliente']),
                        '+${money(service['valorComision'] ?? service['comision'])}',
                      ),
                      pair(
                        '${nested(service, 'servicio')['nombre'] ?? service['nombreServicio'] ?? 'Servicio'} · ${dateLabel(service['fecha'])}',
                        money(
                          nested(service, 'servicio')['precio'] ??
                              service['precio'],
                        ),
                      ),
                    ],
                  ),
                ),
            ] else ...[
              section('#CIE-${r['id']}'),
              panel(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'TOTAL DEL CIERRE',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      money(r['total']),
                      style: const TextStyle(
                        fontSize: 28,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    totals([
                      ('Servicios', '${r['cantidadServicios'] ?? '—'}'),
                      ('Profesionales', s.hasData ? '${rows.length}' : '—'),
                    ]),
                  ],
                ),
              ),
              section('PERÍODO'),
              panel(
                Column(
                  children: [
                    pair('Desde', dateLabel(r['fechaInicio'])),
                    pair('Hasta', dateLabel(r['fechaFin'])),
                  ],
                ),
              ),
              section('PROFESIONALES EN ESTE CIERRE'),
              for (final person in rows)
                panel(
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.background,
                        child: Text(
                          initials(personName(person['profesional'])),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(personName(person['profesional'])),
                            Text(
                              '${person['cantidadServicios'] ?? '—'} servicios',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(money(person['base'])),
                    ],
                  ),
                ),
            ],
            if (s.hasError) infoBox(errorMessage(s.error)),
            if (!s.hasData && !s.hasError)
              const Center(child: CircularProgressIndicator()),
            if (s.hasData && rows.isEmpty)
              infoBox('No hay registros asociados para mostrar.'),
          ],
        );
      },
    );
  }
}

class ProfessionalNavigation extends StatelessWidget {
  const ProfessionalNavigation({
    super.key,
    required this.repository,
    this.selected = 1,
  });
  final ManagementRepository repository;
  final int selected;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.surface,
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 80,
        child: Row(
          children: [
            for (var i = 0; i < 5; i++)
              Expanded(
                child: InkWell(
                  onTap: repository.onProfessionalTab == null
                      ? null
                      : () => repository.onProfessionalTab!(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 54,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i == selected
                              ? AppColors.primary.withValues(alpha: .18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/${['nav_home', 'nav_agenda', 'nav_my_services', 'nav_schedule', 'nav_more'][i]}.svg',
                          width: 22,
                          height: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ['Inicio', 'Agenda', 'Servicios', 'Horario', 'Más'][i],
                        style: TextStyle(
                          fontSize: 10.5,
                          color: i == selected
                              ? AppColors.primary
                              : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
