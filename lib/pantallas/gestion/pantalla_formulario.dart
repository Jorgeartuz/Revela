import 'package:revela/pantallas/gestion/pantalla_operacion_exitosa.dart';
import 'package:revela/pantallas/gestion/pantalla_revision_datos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';

import 'package:revela/configuracion/tema_aplicacion.dart';
import 'package:revela/modelos/gestion/modulo_gestion.dart';
import 'package:revela/modelos/gestion/campos_formulario.dart';
import 'package:revela/modelos/gestion/valores_registro.dart';
import 'package:revela/modelos/gestion/datos_para_api.dart';
import 'package:revela/servicios/remoto/servicio_gestion.dart';
import 'package:revela/componentes/gestion/componentes_compartidos.dart';
import 'package:revela/pantallas/gestion/pantalla_listado.dart';
import 'package:revela/pantallas/gestion/pantalla_detalle.dart';

/// Formulario compartido que cambia sus campos según ModuloGestion.
/// Reutilizarlo evita mantener nueve copias de la validación y del guardado.
class PantallaFormulario extends StatefulWidget {
  const PantallaFormulario({
    super.key,
    required this.modulo,
    required this.servicio,
    this.datosIniciales,
    this.esEdicion = false,
    this.mostrarErrores = false,
    this.errorInicial,
    this.accionInicial,
  });
  final ModuloGestion modulo;
  final ServicioGestion servicio;
  final Map<String, dynamic>? datosIniciales;
  final bool esEdicion;
  final bool mostrarErrores;
  final String? errorInicial, accionInicial;
  @override
  State<PantallaFormulario> createState() => _EstadoPantallaFormulario();
}

class _EstadoPantallaFormulario extends State<PantallaFormulario> {
  final _claveFormulario = GlobalKey<FormState>();
  final _desplazamiento = ScrollController();
  final _valores = <String, dynamic>{};
  final _controladores = <String, TextEditingController>{};
  final _opciones = <String, List<Map<String, dynamic>>>{};
  late final List<CampoFormulario> _campos;
  bool _cargando = true, _guardando = false, _hayCambios = false;
  String? _error;
  bool _errorCargaOpciones = false;
  Map<String, dynamic>? _clienteExistente;
  @override
  void initState() {
    super.initState();
    _campos = camposFormulario(widget.modulo, esEdicion: widget.esEdicion);
    for (final f in _campos) {
      var value = widget.datosIniciales?[f.key];
      if (f.key == 'fechaDia') {
        value = widget.datosIniciales?['fecha']?.toString().split('T').first;
      }
      if (f.key == 'hora') value = widget.datosIniciales?['horaInicio'];
      if (f.kind == TipoCampo.fecha && value is String) {
        value = value.split('T').first;
      }
      if (f.key == 'tipoFecha') {
        final start = widget.datosIniciales?['fechaInicio']
            ?.toString()
            .split('T')
            .first;
        final end = widget.datosIniciales?['fechaFin']
            ?.toString()
            .split('T')
            .first;
        value =
            widget.datosIniciales?['tipoFecha'] ??
            (start != null && end != null && start != end ? 'rango' : 'dia');
      }
      if (f.key == 'motivoLabel' && value == null) {
        value =
            codigosMotivosInasistencia(vistaPrevia: widget.servicio.vistaPrevia)
                .entries
                .where((e) => e.value == widget.datosIniciales?['motivo'])
                .firstOrNull
                ?.key;
      }
      if (f.kind == TipoCampo.interruptor) value = value ?? false;
      if (value != null) _valores[f.key] = value;
      _controladores[f.key] = TextEditingController(
        text: value?.toString() ?? '',
      );
    }
    _cargarOpciones();
  }

  /// Carga las listas que necesitan los selectores, por ejemplo clientes o especialidades.
  Future<void> _cargarOpciones() async {
    try {
      for (final f in _campos.where((f) => f.origen != null)) {
        final registros = await widget.servicio.listar(f.origen!);
        _opciones[f.key] = registros
            .where(
              (r) =>
                  widget.esEdicion ||
                  (r['activa'] != false &&
                      r['activo'] != false &&
                      r['estado'] != false),
            )
            .toList();
      }
      if (mounted) {
        setState(() {
          _cargando = false;
          _errorCargaOpciones = false;
          _error = widget.servicio.vistaPrevia ? widget.errorInicial : null;
        });
      }
      if (widget.servicio.vistaPrevia && widget.accionInicial == 'deactivate') {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final f = _campos.firstWhere((f) => f.kind == TipoCampo.interruptor);
          await _confirmarDesactivacion(f);
        });
      }
      if (widget.mostrarErrores) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _claveFormulario.currentState?.validate(),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _errorCargaOpciones = true;
          _error = mensajeError(e);
        });
      }
    }
  }

  @override
  void dispose() {
    _desplazamiento.dispose();
    for (final c in _controladores.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _confirmarDesactivacion(CampoFormulario f) async {
    final profesional = widget.modulo == ModuloGestion.profesionales;
    final confirmada = await confirmarAccion(
      context,
      title: profesional
          ? '¿Desactivar este profesional?'
          : '¿Desactivar este servicio?',
      description:
          '${widget.datosIniciales?['nombre'] ?? nombreRegistro(widget.datosIniciales ?? {})} quedará en estado Inactivo. Podrás activarlo nuevamente desde su edición.',
      action: profesional
          ? 'Sí, desactivar profesional'
          : 'Sí, desactivar servicio',
    );
    if (confirmada && mounted) _asignarValor(f, false);
  }

  void _asignarValor(CampoFormulario f, Object? value) {
    setState(() {
      _hayCambios = true;
      if (value == null) {
        _valores.remove(f.key);
      } else {
        _valores[f.key] = value;
      }
      _controladores[f.key]!.text = value?.toString() ?? '';
    });
  }

  /// Lleva el mensaje al área visible para que no quede arriba fuera de pantalla.
  void _mostrarError(String mensaje) {
    setState(() => _error = mensaje);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _desplazamiento.hasClients) {
        _desplazamiento.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Pasos: validar, preparar los datos, confirmar si corresponde, guardar y mostrar el resultado.
  Future<void> _guardar() async {
    if (_guardando || _cargando) return;
    FocusScope.of(context).unfocus();
    final camposVisiblesValidos =
        _claveFormulario.currentState?.validate() ?? false;

    // ListView desmonta campos al desplazarse. Validamos todos los datos,
    // incluso los que ya no tienen un FormField visible en la pantalla.
    for (final campo in _campos.where(_esVisible)) {
      final valor = switch (campo.kind) {
        TipoCampo.texto ||
        TipoCampo.textoLargo ||
        TipoCampo.entero ||
        TipoCampo.decimal ||
        TipoCampo.correo => _controladores[campo.key]?.text,
        _ => _valores[campo.key],
      };
      final error = validarCampo(campo, valor);
      if (error != null) {
        _mostrarError('${campo.label}: $error');
        return;
      }
      if (campo.origen != null &&
          valor != null &&
          !(_opciones[campo.key] ?? []).any(
            (registro) => registro['id'] == valor,
          )) {
        _mostrarError('${campo.label}: selecciona una opción disponible.');
        return;
      }
    }
    if (!camposVisiblesValidos) return;
    if (_campos.any((f) => f.origen != null && !_opciones.containsKey(f.key))) {
      setState(
        () => _error =
            'No se pudieron cargar los datos de selección. Reintenta la carga.',
      );
      return;
    }
    Map<String, dynamic> payload;
    try {
      payload = prepararDatosEnvio(
        widget.modulo,
        _valores,
        esEdicion: widget.esEdicion,
        vistaPrevia: widget.servicio.vistaPrevia,
      );
    } catch (e) {
      _mostrarError(mensajeError(e));
      return;
    }
    if ([
      ModuloGestion.reservas,
      ModuloGestion.cierres,
    ].contains(widget.modulo)) {
      setState(() => _guardando = true);
      final confirmada = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PantallaRevisionDatos(
            modulo: widget.modulo,
            values: _valores,
            campos: _campos,
            opciones: _opciones,
            servicio: widget.servicio,
          ),
        ),
      );
      if (!mounted) return;
      if (confirmada != true) {
        setState(() => _guardando = false);
        return;
      }
    }
    setState(() {
      _guardando = true;
      _error = null;
      _clienteExistente = null;
    });
    try {
      await widget.servicio.guardar(
        widget.modulo,
        payload,
        id: widget.esEdicion ? widget.datosIniciales!['id'] as int : null,
      );
      if (!mounted) return;
      setState(() => _hayCambios = false);
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (context) => PantallaOperacionExitosa(
            title: widget.esEdicion
                ? 'Cambios guardados'
                : '${widget.modulo.nombreSingular} guardado correctamente',
            message: 'La operación se completó correctamente.',
          ),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = mensajeError(e);
          _clienteExistente = e is ErrorClienteExistente ? e.cliente : null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _desplazamiento.hasClients) {
            _desplazamiento.animateTo(
              0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _volver() async {
    if (_guardando) return;
    if (_hayCambios &&
        !await confirmarAccion(
          context,
          title: '¿Descartar cambios?',
          description: 'Los cambios sin guardar se perderán.',
          action: 'Descartar',
        )) {
      return;
    }
    if (mounted) {
      setState(() => _hayCambios = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_hayCambios && !_guardando,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _volver();
    },
    child: SectionShell(
      title: widget.esEdicion
          ? (widget.modulo == ModuloGestion.reservas
                ? 'Reagendar Reserva'
                : 'Editar ${widget.modulo.nombreSingular}')
          : switch (widget.modulo) {
              ModuloGestion.horarios => 'Configurar Horario',
              ModuloGestion.inasistencias => 'Registrar Inasistencia',
              ModuloGestion.reservas => 'Nueva Reserva',
              ModuloGestion.especialidades => 'Nueva especialidad',
              _ => 'Nuevo ${widget.modulo.nombreSingular}',
            },
      vistaPrevia: widget.servicio.vistaPrevia,
      bottom: SectionNavigation(modulo: widget.modulo, onSelect: _navegar),
      child: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _claveFormulario,
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
                        controller: _desplazamiento,
                        thumbVisibility: true,
                        interactive: true,
                        child: ListView(
                          controller: _desplazamiento,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(21, 8, 21, 32),
                          children: [
                            if (_error != null)
                              Semantics(
                                liveRegion: true,
                                child: cuadroInformacion(_error!),
                              ),
                            if (_errorCargaOpciones)
                              TextButton(
                                onPressed: _guardando
                                    ? null
                                    : () {
                                        setState(() => _cargando = true);
                                        _cargarOpciones();
                                      },
                                child: const Text('Reintentar carga'),
                              ),
                            if (_clienteExistente != null)
                              TextButton(
                                onPressed: _guardando
                                    ? null
                                    : () => Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PantallaDetalle(
                                            modulo: ModuloGestion.clientes,
                                            registro: _clienteExistente!,
                                            servicio: widget.servicio,
                                          ),
                                        ),
                                      ),
                                child: const Text('Ver cliente registrado'),
                              ),
                            for (final f in _campos)
                              if (_esVisible(f)) ...[
                                if (f.tituloSeccion != null)
                                  tituloSeccion(f.tituloSeccion!),
                                _campo(f),
                                const SizedBox(height: 18),
                              ],
                            if (widget.esEdicion &&
                                [
                                  ModuloGestion.profesionales,
                                  ModuloGestion.servicios,
                                ].contains(widget.modulo)) ...[
                              tituloSeccion('ESPECIALIDAD'),
                              cuadroInformacion(
                                '${widget.datosIniciales?['especialidad'] is Map ? (widget.datosIniciales!['especialidad'] as Map)['nombre'] ?? 'Especialidad asignada' : 'Especialidad asignada'} · Solo lectura',
                              ),
                            ],
                            if (widget.esEdicion &&
                                widget.modulo ==
                                    ModuloGestion.profesionales) ...[
                              tituloSeccion('AGENDA DEL PROFESIONAL'),
                              OutlinedButton(
                                onPressed: () => Navigator.push<void>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PantallaListado(
                                      modulo: ModuloGestion.horarios,
                                      servicio: widget.servicio,
                                      idProfesional:
                                          widget.datosIniciales!['id'] as int,
                                    ),
                                  ),
                                ),
                                child: const Text('Configurar horario'),
                              ),
                              OutlinedButton(
                                onPressed: () => Navigator.push<void>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PantallaListado(
                                      modulo: ModuloGestion.inasistencias,
                                      servicio: widget.servicio,
                                      idProfesional:
                                          widget.datosIniciales!['id'] as int,
                                    ),
                                  ),
                                ),
                                child: const Text('Ver inasistencias'),
                              ),
                            ],
                            if (widget.modulo == ModuloGestion.especialidades)
                              cuadroInformacion(
                                'La especialidad se crea activa. El servicio permite editar el nombre y eliminarla; la reactivación no está disponible.',
                              ),
                            if (widget.modulo == ModuloGestion.reservas) ...[
                              if (!widget.esEdicion)
                                cuadroInformacion(
                                  'El centro asignará el profesional al crear la reserva. El registro de pagos aún no está habilitado.',
                                ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.schedule),
                                label: const Text('Consultar disponibilidad'),
                                onPressed: _guardando
                                    ? null
                                    : _consultarDisponibilidad,
                              ),
                            ],
                            if (widget.modulo == ModuloGestion.horarios &&
                                !widget.servicio.vistaPrevia)
                              cuadroInformacion(
                                'La configuración de los días laborales debe estar habilitada por el centro antes de guardar.',
                              ),
                            if (widget.modulo == ModuloGestion.inasistencias &&
                                !widget.servicio.vistaPrevia)
                              cuadroInformacion(
                                'El registro requiere que el centro tenga habilitados los motivos de inasistencia.',
                              ),
                            const SizedBox(height: 12),
                            if (widget.modulo != ModuloGestion.clientes)
                              _botonGuardar(),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _guardando ? null : _volver,
                              child: const Text('Cancelar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (widget.modulo == ModuloGestion.clientes)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(21, 8, 21, 12),
                      child: _botonGuardar(),
                    ),
                ],
              ),
            ),
    ),
  );
  Widget _botonGuardar() => FilledButton(
    onPressed: _guardando ? null : _guardar,
    child: _guardando
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(
            widget.modulo == ModuloGestion.reservas
                ? 'Confirmar Reserva'
                : widget.modulo == ModuloGestion.cierres
                ? 'Revisar y crear cierre'
                : 'Guardar ${widget.modulo.nombreSingular.toLowerCase()}',
          ),
  );

  Future<void> _navegar(ModuloGestion? modulo) async {
    if (_guardando) return;
    if (_hayCambios &&
        !await confirmarAccion(
          context,
          title: '¿Descartar cambios?',
          description: 'Los cambios sin guardar se perderán.',
          action: 'Descartar',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() => _hayCambios = false);
    final navigator = Navigator.of(context);
    if (modulo == null) {
      widget.servicio.alIrAlInicio?.call();
      navigator.popUntil((r) => r.isFirst);
    } else {
      navigator.pushReplacement<void, void>(
        MaterialPageRoute(
          builder: (context) => modulo == ModuloGestion.especialidades
              ? PantallaMenuGestion(servicio: widget.servicio)
              : PantallaListado(modulo: modulo, servicio: widget.servicio),
        ),
      );
    }
  }

  /// Algunos campos dependen de una selección: almuerzo o rango de fechas, por ejemplo.
  bool _esVisible(CampoFormulario f) {
    if (['horaInicioAlmuerzo', 'horaFinAlmuerzo'].contains(f.key)) {
      return _valores['tieneAlmuerzo'] == true;
    }
    if (widget.modulo == ModuloGestion.inasistencias && f.key == 'fechaFin') {
      return _valores['tipoFecha'] == 'rango';
    }
    return true;
  }

  Widget _campo(CampoFormulario f) {
    final input = _entradaCampo(f);
    if (f.kind == TipoCampo.interruptor) return input;
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

  Widget _entradaCampo(CampoFormulario f) {
    if (f.kind == TipoCampo.interruptor) {
      return SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(f.label),
        value: _valores[f.key] == true,
        onChanged: _guardando
            ? null
            : (v) {
                if (!v &&
                    widget.esEdicion &&
                    [
                      ModuloGestion.servicios,
                      ModuloGestion.profesionales,
                    ].contains(widget.modulo)) {
                  _confirmarDesactivacion(f);
                } else {
                  _asignarValor(f, v);
                }
              },
      );
    }
    if (f.opciones != null &&
        ['dia', 'tipoFecha', 'motivoLabel'].contains(f.key)) {
      return FormField<String>(
        initialValue: _valores[f.key]?.toString(),
        validator: (v) => validarCampo(f, v),
        builder: (estado) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final e in f.opciones!.entries)
                  ChoiceChip(
                    showCheckmark: false,
                    selectedColor: ColoresAplicacion.principal.withValues(
                      alpha: .25,
                    ),
                    label: Text(
                      f.key == 'dia' ? e.value.substring(0, 3) : e.value,
                    ),
                    selected: _valores[f.key] == e.key,
                    onSelected: _guardando
                        ? null
                        : (_) {
                            estado.didChange(e.key);
                            _asignarValor(f, e.key);
                          },
                  ),
              ],
            ),
            if (estado.hasError)
              Text(
                estado.errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      );
    }
    if (f.kind == TipoCampo.seleccion) {
      final opciones =
          f.opciones ??
          {
            for (final r in _opciones[f.key] ?? [])
              '${r['id']}': nombreRegistro(r),
          };
      final current = _valores[f.key]?.toString();
      return DropdownButtonFormField<String>(
        key: ValueKey('${f.key}:$current:${opciones.length}'),
        initialValue: opciones.containsKey(current) ? current : null,
        isExpanded: true,
        hint: Text('Seleccionar ${f.label.toLowerCase()}'),
        decoration: InputDecoration(labelText: null),
        items: [
          for (final e in opciones.entries)
            DropdownMenuItem(
              value: e.key,
              child: Text(e.value, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: _guardando
            ? null
            : (v) => _asignarValor(
                f,
                f.origen != null && v != null ? int.parse(v) : v,
              ),
        validator: (v) => validarCampo(f, v),
      );
    }
    if (f.kind == TipoCampo.fecha || f.kind == TipoCampo.hora) {
      final raw = _valores[f.key]?.toString();
      final display = raw == null
          ? ''
          : f.kind == TipoCampo.fecha
          ? formatoFecha(raw)
          : minutosDeHora(raw) == null
          ? 'Hora no válida'
          : '${(minutosDeHora(raw)! ~/ 60).toString().padLeft(2, '0')}:${(minutosDeHora(raw)! % 60).toString().padLeft(2, '0')}';
      return FormField<String>(
        initialValue: raw,
        validator: (_) => validarCampo(f, _valores[f.key]),
        builder: (estado) => InkWell(
          onTap: _guardando
              ? null
              : () async {
                  if (f.kind == TipoCampo.fecha) {
                    final datosIniciales =
                        DateTime.tryParse(raw ?? '') ?? DateTime.now();
                    final date = await showDatePicker(
                      context: context,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                      initialDate: datosIniciales.isBefore(DateTime(1900))
                          ? DateTime(1900)
                          : datosIniciales.isAfter(DateTime(2100))
                          ? DateTime(2100)
                          : datosIniciales,
                    );
                    if (date != null && mounted) {
                      _asignarValor(f, DateFormat('yyyy-MM-dd').format(date));
                      estado.didChange(_valores[f.key]?.toString());
                    }
                  } else {
                    final minutes = minutosDeHora(raw) ?? 9 * 60;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: minutes ~/ 60,
                        minute: minutes % 60,
                      ),
                    );
                    if (time != null && mounted) {
                      _asignarValor(
                        f,
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00',
                      );
                      estado.didChange(_valores[f.key]?.toString());
                    }
                  }
                },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: null,
              errorText: estado.errorText,
              suffixIcon: Icon(
                f.kind == TipoCampo.fecha
                    ? Icons.calendar_today_outlined
                    : Icons.schedule,
                size: 20,
              ),
            ),
            child: Text(
              display.isEmpty
                  ? (f.kind == TipoCampo.fecha ? 'dd/mm/aaaa' : 'Elegir hora')
                  : display,
              style: TextStyle(
                color: display.isEmpty
                    ? ColoresAplicacion.textoSecundario
                    : ColoresAplicacion.texto,
              ),
            ),
          ),
        ),
      );
    }
    return TextFormField(
      key: ValueKey(f.key),
      controller: _controladores[f.key],
      enabled: !_guardando,
      maxLength: f.maxLength,
      maxLines: f.kind == TipoCampo.textoLargo ? 3 : 1,
      keyboardType: f.kind == TipoCampo.entero
          ? TextInputType.number
          : f.kind == TipoCampo.decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : f.kind == TipoCampo.correo
          ? TextInputType.emailAddress
          : TextInputType.text,
      decoration: InputDecoration(labelText: null, hintText: f.hint),
      validator: (v) => validarCampo(f, v),
      onChanged: (v) {
        setState(() {
          _hayCambios = true;
          if (f.key == 'documento' && _clienteExistente != null) {
            _clienteExistente = null;
            _error = null;
          }
          if (v.trim().isEmpty) {
            if (widget.esEdicion && !f.required) {
              _valores[f.key] = null;
            } else {
              _valores.remove(f.key);
            }
          } else {
            _valores[f.key] = f.kind == TipoCampo.entero
                ? int.tryParse(v)
                : f.kind == TipoCampo.decimal
                ? double.tryParse(v.replaceAll(',', '.'))
                : v.trim();
          }
        });
      },
    );
  }

  Future<void> _consultarDisponibilidad() async {
    if (_guardando) return;
    final id = _valores['servicioId'];
    final date = DateTime.tryParse(_valores['fechaDia']?.toString() ?? '');
    if (id is! int || date == null) {
      _mostrarError(
        'Selecciona un servicio y una fecha para consultar disponibilidad.',
      );
      return;
    }
    setState(() => _guardando = true);
    try {
      final data = await widget.servicio.consultarDisponibilidad(
        serviceId: id,
        date: date,
        idProfesional: _valores['profesionalId'] as int?,
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
      if (mounted) _mostrarError(mensajeError(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}
