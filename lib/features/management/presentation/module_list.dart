import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/module.dart';
import '../data/management_repository.dart';
import 'shared.dart';
import 'operational_views.dart';
import 'record_form.dart';
import 'record_detail.dart';

class ModuleListPage extends StatefulWidget {
  const ModuleListPage({
    super.key,
    required this.module,
    required this.repository,
    this.embedded = false,
    this.professionalId,
    this.readOnly = false,
    this.initialFilters = const {},
  });
  final Module module;
  final ManagementRepository repository;
  final bool embedded, readOnly;
  final int? professionalId;
  final Map<String, String> initialFilters;
  @override
  State<ModuleListPage> createState() => _ModuleListPageState();
}

class _ModuleListPageState extends State<ModuleListPage> {
  late Future<List<Map<String, dynamic>>> _future;
  final _search = TextEditingController();
  Future<List<Map<String, dynamic>>>? _specialties;
  String _query = '';
  String _state = 'todos';
  String? _specialty;
  DateTimeRange? _period;
  int? _professional;
  Future<List<Map<String, dynamic>>>? _professionals;
  @override
  void initState() {
    super.initState();
    _load();
    if (widget.module == Module.services ||
        widget.module == Module.professionals) {
      _specialties = widget.repository.list(Module.specialties);
    }
    if ([
          Module.schedules,
          Module.absences,
          Module.commissions,
          Module.reservations,
        ].contains(widget.module) &&
        widget.professionalId == null) {
      _professionals = widget.repository.list(Module.professionals);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _load() {
    final filters = {
      ...widget.initialFilters,
      if (widget.professionalId != null)
        'profesionalId': '${widget.professionalId}',
      if (_professional != null) 'profesionalId': '$_professional',
    };
    if (_period != null) {
      filters['fechaInicio'] = widget.module == Module.reservations
          ? _period!.start.toIso8601String()
          : _period!.start.toIso8601String().split('T').first;
      filters['fechaFin'] = widget.module == Module.reservations
          ? _period!.end
                .add(const Duration(days: 1))
                .subtract(const Duration(microseconds: 1))
                .toIso8601String()
          : _period!.end.toIso8601String().split('T').first;
    }
    _future = widget.repository.list(widget.module, filters: filters);
  }

  Future<void> _refresh() async {
    setState(_load);
    try {
      await _future;
    } catch (_) {}
  }

  Future<void> _form() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RecordFormPage(
          module: widget.module,
          repository: widget.repository,
          initial: widget.professionalId == null
              ? null
              : {'profesionalId': widget.professionalId},
        ),
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  Future<void> _detail(Map<String, dynamic> row) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RecordDetailPage(
          module: widget.module,
          row: row,
          repository: widget.repository,
          readOnly: widget.readOnly,
        ),
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  void _navigate(Module? module) {
    if (module == null) {
      widget.repository.onHome?.call();
      Navigator.popUntil(context, (r) => r.isFirst);
      return;
    }
    Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute(
        builder: (context) => module == Module.specialties
            ? ManagementMenuPage(repository: widget.repository)
            : ModuleListPage(module: module, repository: widget.repository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final specialized = [
      Module.reservations,
      Module.schedules,
      Module.absences,
      Module.commissions,
    ].contains(widget.module);
    final content = specialized
        ? OperationalView(
            module: widget.module,
            repository: widget.repository,
            professionalId: widget.professionalId,
            readOnly: widget.readOnly,
            filters: widget.initialFilters,
            onHome: () {
              widget.repository.onHome?.call();
              Navigator.popUntil(context, (r) => r.isFirst);
            },
          )
        : _content();
    if (widget.embedded) return content;
    return SectionShell(
      title: widget.readOnly
          ? switch (widget.module) {
              Module.reservations => 'Mi Agenda',
              Module.schedules => 'Mi Horario',
              Module.absences => 'Mis Inasistencias',
              _ => widget.module.title,
            }
          : widget.module == Module.schedules
          ? 'Horario de Trabajo'
          : widget.module.title,
      preview: widget.repository.preview,
      bottom: widget.readOnly
          ? ProfessionalNavigation(
              repository: widget.repository,
              selected: widget.module == Module.schedules
                  ? 3
                  : widget.module == Module.absences
                  ? 4
                  : 1,
            )
          : SectionNavigation(module: widget.module, onSelect: _navigate),
      child: content,
    );
  }

  Widget _content() => RefreshIndicator(
    onRefresh: _refresh,
    child: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              infoBox(errorMessage(snapshot.error)),
              TextButton(onPressed: _refresh, child: const Text('Reintentar')),
            ],
          );
        }
        final all = snapshot.data ?? [];
        final rows = all.where((r) {
          final text =
              '${recordName(r)} ${r['documento'] ?? ''} ${personName(r['cliente'])} ${personName(r['profesional'])}'
                  .toLowerCase();
          if (!text.contains(_query.toLowerCase())) return false;
          final active = r['activo'] ?? r['estado'] ?? r['activa'];
          if (active is bool &&
              _state != 'todos' &&
              active != (_state == 'activos')) {
            return false;
          }
          if (_specialty != null && '${r['especialidadId']}' != _specialty) {
            return false;
          }
          return true;
        }).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(21, 16, 21, 32),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.module.title,
                    style: const TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.module.canCreate && !widget.readOnly)
                  IconButton.filled(
                    tooltip: 'Crear ${widget.module.singular.toLowerCase()}',
                    onPressed: _form,
                    icon: const Icon(Icons.add),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o documento...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 14),
            if ([
              Module.services,
              Module.professionals,
              Module.specialties,
            ].contains(widget.module))
              Wrap(
                spacing: 8,
                children: [
                  for (final option in {
                    'todos': 'Todos',
                    'activos': 'Activos',
                    'inactivos': 'Inactivos',
                  }.entries)
                    ChoiceChip(
                      label: Text(option.value),
                      selected: _state == option.key,
                      onSelected: (_) => setState(() => _state = option.key),
                    ),
                ],
              ),
            if (widget.module == Module.services ||
                widget.module == Module.professionals)
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _specialties,
                builder: (context, s) => s.hasData
                    ? DropdownButtonFormField<String>(
                        initialValue: _specialty,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Especialidad',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Todas'),
                          ),
                          for (final r in s.data!)
                            DropdownMenuItem(
                              value: '${r['id']}',
                              child: Text(recordName(r)),
                            ),
                        ],
                        onChanged: (v) => setState(() => _specialty = v),
                      )
                    : const SizedBox.shrink(),
              ),
            if (_professionals != null)
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _professionals,
                builder: (context, s) => s.hasData
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: DropdownButtonFormField<int>(
                          initialValue: _professional,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Profesional',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Todos'),
                            ),
                            for (final r in s.data!)
                              DropdownMenuItem(
                                value: r['id'] as int,
                                child: Text(recordName(r)),
                              ),
                          ],
                          onChanged: (v) => setState(() {
                            _professional = v;
                            _load();
                          }),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            if ([
              Module.reservations,
              Module.closures,
              Module.commissions,
            ].contains(widget.module))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _period == null
                        ? 'Seleccionar período'
                        : '${dateLabel(_period!.start.toIso8601String())} — ${dateLabel(_period!.end.toIso8601String())}',
                  ),
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDateRange: _period,
                    );
                    if (range != null && mounted) {
                      setState(() {
                        _period = range;
                        _load();
                      });
                    }
                  },
                ),
              ),
            section('${rows.length} ${widget.module.title.toUpperCase()}'),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (rows.isEmpty)
              Column(
                children: [
                  const SizedBox(height: 20),
                  const Icon(
                    Icons.search_off,
                    size: 40,
                    color: AppColors.muted,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No hay resultados para mostrar.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _search.clear();
                      _query = '';
                      _state = 'todos';
                      _specialty = null;
                      _professional = null;
                      _period = null;
                      _load();
                    }),
                    child: const Text('Limpiar filtros'),
                  ),
                  if (widget.module.canCreate && !widget.readOnly)
                    TextButton(
                      onPressed: _form,
                      child: Text(
                        'Crear ${widget.module.singular.toLowerCase()}',
                      ),
                    ),
                ],
              )
            else
              ...rows.map(
                (row) => RecordCard(
                  module: widget.module,
                  row: row,
                  preview: widget.repository.preview,
                  onTap: () => _detail(row),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class ManagementMenuPage extends StatelessWidget {
  const ManagementMenuPage({super.key, required this.repository});
  final ManagementRepository repository;
  @override
  Widget build(BuildContext context) => SectionShell(
    title: 'Más',
    preview: repository.preview,
    child: ListView(
      padding: const EdgeInsets.all(21),
      children: [
        section('GESTIÓN DEL CENTRO'),
        for (final module in Module.values)
          ListTile(
            title: Text(module.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ModuleListPage(module: module, repository: repository),
              ),
            ),
          ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () {
            repository.onHome?.call();
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          child: const Text('Volver al inicio'),
        ),
      ],
    ),
  );
}
