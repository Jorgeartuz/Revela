import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/module.dart';
import '../domain/form_spec.dart';
import '../domain/record_values.dart';
import '../domain/payload.dart';
import '../data/management_repository.dart';
import 'shared.dart';
import 'module_list.dart';
import 'record_detail.dart';

class RecordFormPage extends StatefulWidget {
  const RecordFormPage({
    super.key,
    required this.module,
    required this.repository,
    this.initial,
    this.editing = false,
    this.showErrors = false,
    this.initialError,
    this.initialAction,
  });
  final Module module;
  final ManagementRepository repository;
  final Map<String, dynamic>? initial;
  final bool editing;
  final bool showErrors;
  final String? initialError, initialAction;
  @override
  State<RecordFormPage> createState() => _RecordFormPageState();
}

class _RecordFormPageState extends State<RecordFormPage> {
  final _key = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _values = <String, dynamic>{};
  final _controllers = <String, TextEditingController>{};
  final _options = <String, List<Map<String, dynamic>>>{};
  late final List<FieldSpec> _fields;
  bool _loading = true, _saving = false, _dirty = false;
  String? _error;
  bool _optionsError = false;
  Map<String, dynamic>? _existingCustomer;
  @override
  void initState() {
    super.initState();
    _fields = formFields(widget.module, editing: widget.editing);
    for (final f in _fields) {
      var value = widget.initial?[f.key];
      if (f.key == 'fechaDia') {
        value = widget.initial?['fecha']?.toString().split('T').first;
      }
      if (f.key == 'hora') value = widget.initial?['horaInicio'];
      if (f.kind == InputKind.date && value is String) {
        value = value.split('T').first;
      }
      if (f.key == 'tipoFecha') {
        final start = widget.initial?['fechaInicio']
            ?.toString()
            .split('T')
            .first;
        final end = widget.initial?['fechaFin']?.toString().split('T').first;
        value =
            widget.initial?['tipoFecha'] ??
            (start != null && end != null && start != end ? 'rango' : 'dia');
      }
      if (f.key == 'motivoLabel' && value == null) {
        value = absenceCodes(preview: widget.repository.preview).entries
            .where((e) => e.value == widget.initial?['motivo'])
            .firstOrNull
            ?.key;
      }
      if (f.kind == InputKind.toggle) value = value ?? false;
      if (value != null) _values[f.key] = value;
      _controllers[f.key] = TextEditingController(
        text: value?.toString() ?? '',
      );
    }
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      for (final f in _fields.where((f) => f.source != null)) {
        final rows = await widget.repository.list(f.source!);
        _options[f.key] = rows
            .where(
              (r) =>
                  widget.editing ||
                  (r['activa'] != false &&
                      r['activo'] != false &&
                      r['estado'] != false),
            )
            .toList();
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _optionsError = false;
          _error = widget.repository.preview ? widget.initialError : null;
        });
      }
      if (widget.repository.preview && widget.initialAction == 'deactivate') {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final f = _fields.firstWhere((f) => f.kind == InputKind.toggle);
          await _deactivate(f);
        });
      }
      if (widget.showErrors) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _key.currentState?.validate(),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _optionsError = true;
          _error = errorMessage(e);
        });
      }
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _deactivate(FieldSpec f) async {
    final professional = widget.module == Module.professionals;
    final confirmed = await confirmAction(
      context,
      title: professional
          ? '¿Desactivar este profesional?'
          : '¿Desactivar este servicio?',
      description:
          '${widget.initial?['nombre'] ?? recordName(widget.initial ?? {})} quedará en estado Inactivo. Podrás activarlo nuevamente desde su edición.',
      action: professional
          ? 'Sí, desactivar profesional'
          : 'Sí, desactivar servicio',
    );
    if (confirmed && mounted) _set(f, false);
  }

  void _set(FieldSpec f, Object? value) {
    setState(() {
      _dirty = true;
      if (value == null) {
        _values.remove(f.key);
      } else {
        _values[f.key] = value;
      }
      _controllers[f.key]!.text = value?.toString() ?? '';
    });
  }

  Future<void> _save() async {
    if (_saving || !_key.currentState!.validate()) return;
    if (_fields.any((f) => f.source != null && !_options.containsKey(f.key))) {
      setState(
        () => _error =
            'No se pudieron cargar los datos de selección. Reintenta la carga.',
      );
      return;
    }
    Map<String, dynamic> payload;
    try {
      payload = buildPayload(
        widget.module,
        _values,
        editing: widget.editing,
        preview: widget.repository.preview,
      );
    } catch (e) {
      setState(() => _error = errorMessage(e));
      return;
    }
    if ([Module.reservations, Module.closures].contains(widget.module)) {
      setState(() => _saving = true);
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => RecordReviewPage(
            module: widget.module,
            values: _values,
            fields: _fields,
            options: _options,
            repository: widget.repository,
          ),
        ),
      );
      if (!mounted) return;
      if (confirmed != true) {
        setState(() => _saving = false);
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
      _existingCustomer = null;
    });
    try {
      await widget.repository.save(
        widget.module,
        payload,
        id: widget.editing ? widget.initial!['id'] as int : null,
      );
      if (!mounted) return;
      setState(() => _dirty = false);
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (context) => OperationSuccessPage(
            title: widget.editing
                ? 'Cambios guardados'
                : '${widget.module.singular} guardado correctamente',
            message: 'La operación se completó correctamente.',
          ),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = errorMessage(e);
          _existingCustomer = e is CustomerAlreadyExistsException
              ? e.customer
              : null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scroll.hasClients) {
            _scroll.animateTo(
              0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _back() async {
    if (_saving) return;
    if (_dirty &&
        !await confirmAction(
          context,
          title: '¿Descartar cambios?',
          description: 'Los cambios sin guardar se perderán.',
          action: 'Descartar',
        )) {
      return;
    }
    if (mounted) {
      setState(() => _dirty = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_dirty && !_saving,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _back();
    },
    child: SectionShell(
      title: widget.editing
          ? (widget.module == Module.reservations
                ? 'Reagendar Reserva'
                : 'Editar ${widget.module.singular}')
          : switch (widget.module) {
              Module.schedules => 'Configurar Horario',
              Module.absences => 'Registrar Inasistencia',
              Module.reservations => 'Nueva Reserva',
              Module.specialties => 'Nueva especialidad',
              _ => 'Nuevo ${widget.module.singular}',
            },
      preview: widget.repository.preview,
      bottom: SectionNavigation(module: widget.module, onSelect: _navigate),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _key,
              child: Column(
                children: [
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: const MaterialScrollBehavior().copyWith(
                        dragDevices: {
                          ...const MaterialScrollBehavior().dragDevices,
                          PointerDeviceKind.mouse,
                        },
                      ),
                      child: Scrollbar(
                        controller: _scroll,
                        thumbVisibility: true,
                        interactive: true,
                        child: ListView(
                          controller: _scroll,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(21, 8, 21, 32),
                          children: [
                            if (_error != null)
                              Semantics(
                                liveRegion: true,
                                child: infoBox(_error!),
                              ),
                            if (_optionsError)
                              TextButton(
                                onPressed: _saving
                                    ? null
                                    : () {
                                        setState(() => _loading = true);
                                        _loadOptions();
                                      },
                                child: const Text('Reintentar carga'),
                              ),
                            if (_existingCustomer != null)
                              TextButton(
                                onPressed: _saving
                                    ? null
                                    : () => Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => RecordDetailPage(
                                            module: Module.customers,
                                            row: _existingCustomer!,
                                            repository: widget.repository,
                                          ),
                                        ),
                                      ),
                                child: const Text('Ver cliente registrado'),
                              ),
                            for (final f in _fields)
                              if (_visible(f)) ...[
                                if (f.section != null) section(f.section!),
                                _field(f),
                                const SizedBox(height: 18),
                              ],
                            if (widget.editing &&
                                [
                                  Module.professionals,
                                  Module.services,
                                ].contains(widget.module)) ...[
                              section('ESPECIALIDAD'),
                              infoBox(
                                '${widget.initial?['especialidad'] is Map ? (widget.initial!['especialidad'] as Map)['nombre'] ?? 'Especialidad asignada' : 'Especialidad asignada'} · Solo lectura',
                              ),
                            ],
                            if (widget.editing &&
                                widget.module == Module.professionals) ...[
                              section('AGENDA DEL PROFESIONAL'),
                              OutlinedButton(
                                onPressed: () => Navigator.push<void>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ModuleListPage(
                                      module: Module.schedules,
                                      repository: widget.repository,
                                      professionalId:
                                          widget.initial!['id'] as int,
                                    ),
                                  ),
                                ),
                                child: const Text('Configurar horario'),
                              ),
                              OutlinedButton(
                                onPressed: () => Navigator.push<void>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ModuleListPage(
                                      module: Module.absences,
                                      repository: widget.repository,
                                      professionalId:
                                          widget.initial!['id'] as int,
                                    ),
                                  ),
                                ),
                                child: const Text('Ver inasistencias'),
                              ),
                            ],
                            if (widget.module == Module.specialties)
                              infoBox(
                                'La especialidad se crea activa. El servicio permite editar el nombre y eliminarla; la reactivación no está disponible.',
                              ),
                            if (widget.module == Module.reservations) ...[
                              if (!widget.editing)
                                infoBox(
                                  'El centro asignará el profesional al crear la reserva. El registro de pagos aún no está habilitado.',
                                ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.schedule),
                                label: const Text('Consultar disponibilidad'),
                                onPressed: _saving ? null : _availability,
                              ),
                            ],
                            if (widget.module == Module.schedules &&
                                !widget.repository.preview)
                              infoBox(
                                'La configuración de los días laborales debe estar habilitada por el centro antes de guardar.',
                              ),
                            if (widget.module == Module.absences &&
                                !widget.repository.preview)
                              infoBox(
                                'El registro requiere que el centro tenga habilitados los motivos de inasistencia.',
                              ),
                            const SizedBox(height: 12),
                            if (widget.module != Module.customers)
                              _saveButton(),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _saving ? null : _back,
                              child: const Text('Cancelar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (widget.module == Module.customers)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(21, 8, 21, 12),
                      child: _saveButton(),
                    ),
                ],
              ),
            ),
    ),
  );
  Widget _saveButton() => FilledButton(
    onPressed: _saving ? null : _save,
    child: _saving
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(
            widget.module == Module.reservations
                ? 'Confirmar Reserva'
                : widget.module == Module.closures
                ? 'Revisar y crear cierre'
                : 'Guardar ${widget.module.singular.toLowerCase()}',
          ),
  );

  Future<void> _navigate(Module? module) async {
    if (_saving) return;
    if (_dirty &&
        !await confirmAction(
          context,
          title: '¿Descartar cambios?',
          description: 'Los cambios sin guardar se perderán.',
          action: 'Descartar',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() => _dirty = false);
    final navigator = Navigator.of(context);
    if (module == null) {
      widget.repository.onHome?.call();
      navigator.popUntil((r) => r.isFirst);
    } else {
      navigator.pushReplacement<void, void>(
        MaterialPageRoute(
          builder: (context) => module == Module.specialties
              ? ManagementMenuPage(repository: widget.repository)
              : ModuleListPage(module: module, repository: widget.repository),
        ),
      );
    }
  }

  bool _visible(FieldSpec f) {
    if (['horaInicioAlmuerzo', 'horaFinAlmuerzo'].contains(f.key)) {
      return _values['tieneAlmuerzo'] == true;
    }
    if (widget.module == Module.absences && f.key == 'fechaFin') {
      return _values['tipoFecha'] == 'rango';
    }
    return true;
  }

  Widget _field(FieldSpec f) {
    final input = _inputField(f);
    if (f.kind == InputKind.toggle) return input;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${f.label}${f.required ? '*' : ''}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        input,
      ],
    );
  }

  Widget _inputField(FieldSpec f) {
    if (f.kind == InputKind.toggle) {
      return SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(f.label),
        value: _values[f.key] == true,
        onChanged: _saving
            ? null
            : (v) {
                if (!v &&
                    widget.editing &&
                    [
                      Module.services,
                      Module.professionals,
                    ].contains(widget.module)) {
                  _deactivate(f);
                } else {
                  _set(f, v);
                }
              },
      );
    }
    if (f.options != null &&
        ['dia', 'tipoFecha', 'motivoLabel'].contains(f.key)) {
      return FormField<String>(
        initialValue: _values[f.key]?.toString(),
        validator: (v) => validateField(f, v),
        builder: (state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final e in f.options!.entries)
                  ChoiceChip(
                    showCheckmark: false,
                    selectedColor: AppColors.primary.withValues(alpha: .25),
                    label: Text(
                      f.key == 'dia' ? e.value.substring(0, 3) : e.value,
                    ),
                    selected: _values[f.key] == e.key,
                    onSelected: _saving
                        ? null
                        : (_) {
                            state.didChange(e.key);
                            _set(f, e.key);
                          },
                  ),
              ],
            ),
            if (state.hasError)
              Text(
                state.errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      );
    }
    if (f.kind == InputKind.select) {
      final options =
          f.options ??
          {for (final r in _options[f.key] ?? []) '${r['id']}': recordName(r)};
      final current = _values[f.key]?.toString();
      return DropdownButtonFormField<String>(
        key: ValueKey('${f.key}:$current:${options.length}'),
        initialValue: options.containsKey(current) ? current : null,
        isExpanded: true,
        hint: Text('Seleccionar ${f.label.toLowerCase()}'),
        decoration: InputDecoration(labelText: null),
        items: [
          for (final e in options.entries)
            DropdownMenuItem(
              value: e.key,
              child: Text(e.value, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: _saving
            ? null
            : (v) => _set(f, f.source != null && v != null ? int.parse(v) : v),
        validator: (v) => validateField(f, v),
      );
    }
    if (f.kind == InputKind.date || f.kind == InputKind.time) {
      final raw = _values[f.key]?.toString();
      final display = raw == null
          ? ''
          : f.kind == InputKind.date
          ? dateLabel(raw)
          : timeMinutes(raw) == null
          ? 'Hora no válida'
          : '${(timeMinutes(raw)! ~/ 60).toString().padLeft(2, '0')}:${(timeMinutes(raw)! % 60).toString().padLeft(2, '0')}';
      return FormField<String>(
        initialValue: raw,
        validator: (_) => validateField(f, _values[f.key]),
        builder: (state) => InkWell(
          onTap: _saving
              ? null
              : () async {
                  if (f.kind == InputKind.date) {
                    final initial =
                        DateTime.tryParse(raw ?? '') ?? DateTime.now();
                    final date = await showDatePicker(
                      context: context,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                      initialDate: initial.isBefore(DateTime(1900))
                          ? DateTime(1900)
                          : initial.isAfter(DateTime(2100))
                          ? DateTime(2100)
                          : initial,
                    );
                    if (date != null && mounted) {
                      _set(f, DateFormat('yyyy-MM-dd').format(date));
                      state.didChange(_values[f.key]?.toString());
                    }
                  } else {
                    final minutes = timeMinutes(raw) ?? 9 * 60;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: minutes ~/ 60,
                        minute: minutes % 60,
                      ),
                    );
                    if (time != null && mounted) {
                      _set(
                        f,
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00',
                      );
                      state.didChange(_values[f.key]?.toString());
                    }
                  }
                },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: null,
              errorText: state.errorText,
              suffixIcon: Icon(
                f.kind == InputKind.date
                    ? Icons.calendar_today_outlined
                    : Icons.schedule,
                size: 20,
              ),
            ),
            child: Text(
              display.isEmpty
                  ? (f.kind == InputKind.date ? 'dd/mm/aaaa' : 'Elegir hora')
                  : display,
              style: TextStyle(
                color: display.isEmpty ? AppColors.muted : AppColors.text,
              ),
            ),
          ),
        ),
      );
    }
    return TextFormField(
      key: ValueKey(f.key),
      controller: _controllers[f.key],
      enabled: !_saving,
      maxLength: f.maxLength,
      maxLines: f.kind == InputKind.multiline ? 3 : 1,
      keyboardType: f.kind == InputKind.integer
          ? TextInputType.number
          : f.kind == InputKind.decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : f.kind == InputKind.email
          ? TextInputType.emailAddress
          : TextInputType.text,
      decoration: InputDecoration(labelText: null, hintText: f.hint),
      validator: (v) => validateField(f, v),
      onChanged: (v) {
        setState(() {
          _dirty = true;
          if (f.key == 'documento' && _existingCustomer != null) {
            _existingCustomer = null;
            _error = null;
          }
          if (v.trim().isEmpty) {
            if (widget.editing && !f.required) {
              _values[f.key] = null;
            } else {
              _values.remove(f.key);
            }
          } else {
            _values[f.key] = f.kind == InputKind.integer
                ? int.tryParse(v)
                : f.kind == InputKind.decimal
                ? double.tryParse(v.replaceAll(',', '.'))
                : v.trim();
          }
        });
      },
    );
  }

  Future<void> _availability() async {
    final id = _values['servicioId'];
    final date = DateTime.tryParse(_values['fechaDia']?.toString() ?? '');
    if (id is! int || date == null) {
      setState(
        () => _error =
            'Selecciona un servicio y una fecha para consultar disponibilidad.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final data = await widget.repository.availability(
        serviceId: id,
        date: date,
        professionalId: _values['profesionalId'] as int?,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disponibilidad'),
          content: Text(
            data is List && data.isEmpty
                ? 'No se encontraron horarios disponibles para la selección.'
                : 'La disponibilidad fue consultada. El centro validará el horario al guardar la reserva.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class RecordReviewPage extends StatelessWidget {
  const RecordReviewPage({
    super.key,
    required this.module,
    required this.values,
    required this.fields,
    required this.options,
    this.repository,
  });
  final Module module;
  final Map<String, dynamic> values;
  final List<FieldSpec> fields;
  final Map<String, List<Map<String, dynamic>>> options;
  final ManagementRepository? repository;
  @override
  Widget build(BuildContext context) => SectionShell(
    title: module == Module.reservations
        ? 'Confirmación de Reserva'
        : 'Resumen del Cierre',
    child: ListView(
      padding: const EdgeInsets.all(21),
      children: [
        section('REVISA LOS DATOS'),
        for (final f in fields)
          if (values[f.key] != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                f.label,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              subtitle: Text(
                f.source != null
                    ? (options[f.key] ?? <Map<String, dynamic>>[])
                              .where((r) => r['id'] == values[f.key])
                              .map(recordName)
                              .firstOrNull ??
                          'Sin seleccionar'
                    : f.kind == InputKind.date
                    ? dateLabel(values[f.key])
                    : values[f.key].toString(),
                style: const TextStyle(color: AppColors.text, fontSize: 16),
              ),
            ),
        if (module == Module.reservations) ...[
          for (final service
              in options['servicioId'] ?? <Map<String, dynamic>>[])
            if (service['id'] == values['servicioId']) ...[
              ListTile(
                title: const Text('Precio'),
                trailing: Text(money(service['precio'])),
              ),
              ListTile(
                title: const Text('Duración'),
                trailing: Text('${service['duracion']} min'),
              ),
            ],
        ],
        if (module == Module.closures) ...[
          section('RESUMEN DEL PERÍODO'),
          if (repository?.preview == true) ...[
            ListTile(
              title: const Text('Total de servicios de ejemplo'),
              trailing: Text(
                '${repository!.memory[Module.reservations]!.length}',
              ),
            ),
            ListTile(
              title: const Text('Total de profesionales de ejemplo'),
              trailing: Text(
                '${repository!.memory[Module.professionals]!.length}',
              ),
            ),
          ],
          infoBox(
            'El sistema calculará el total y las comisiones al crear el cierre. El período no se modificará después de confirmar.',
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            module == Module.reservations
                ? 'Confirmar y crear reserva'
                : 'Confirmar y crear cierre',
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Volver a editar'),
        ),
      ],
    ),
  );
}

class OperationSuccessPage extends StatelessWidget {
  const OperationSuccessPage({
    super.key,
    required this.title,
    required this.message,
  });
  final String title, message;
  @override
  Widget build(BuildContext context) => SectionShell(
    title: 'Confirmación',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.primary,
            size: 72,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar'),
          ),
        ],
      ),
    ),
  );
}
