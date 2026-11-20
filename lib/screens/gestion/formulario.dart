import 'package:revela/widgets/campos/campo_gestion.dart';
import 'package:revela/models/reservas/horario_disponible.dart';
import 'package:revela/widgets/reservas/selector_horario.dart';
import 'package:revela/routes/rutas_aplicacion.dart';
import 'package:revela/models/navegacion/argumentos_gestion.dart';
import 'package:revela/models/gestion/opcion_seleccion.dart';
import 'package:revela/widgets/botones/boton_principal.dart';
import 'package:revela/screens/gestion/operacion_exitosa.dart';
import 'package:revela/screens/gestion/revision_datos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';

import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/models/gestion/campos_formulario.dart';
import 'package:revela/models/gestion/datos_para_api.dart';
import 'package:revela/services/remote/servicio_gestion.dart';
import 'package:revela/widgets/gestion/componentes_compartidos.dart';
import 'package:revela/screens/gestion/listado.dart';

class PantallaFormulario extends StatefulWidget {
  const PantallaFormulario({
    super.key,
    required this.modulo,
    required this.servicio,
    this.datosIniciales,
    this.esEdicion = false,
  });
  final ModuloGestion modulo;
  final ServicioGestion servicio;
  final Map<String, dynamic>? datosIniciales;
  final bool esEdicion;
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
  String? get _bloqueoConfiguracion {
    if (widget.modulo == ModuloGestion.horarios &&
        !widget.esEdicion &&
        widget.servicio.diasSemana.length != 7) {
      return 'El centro debe confirmar los días laborales antes de registrar horarios.';
    }
    if (widget.modulo == ModuloGestion.inasistencias &&
        widget.servicio.motivosInasistencia.length != 3) {
      return 'El centro debe confirmar los motivos de inasistencia antes de registrar o editar una inasistencia.';
    }
    return null;
  }

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
        value = widget.servicio.motivosInasistencia.entries
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
          _error = null;
        });
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

  Future<void> _guardar() async {
    if (_guardando || _cargando) return;
    if (_bloqueoConfiguracion != null) {
      _mostrarError(_bloqueoConfiguracion!);
      return;
    }
    FocusScope.of(context).unfocus();
    final camposVisiblesValidos =
        _claveFormulario.currentState?.validate() ?? false;

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
        diasSemana: widget.servicio.diasSemana,
        motivosInasistencia: widget.servicio.motivosInasistencia,
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
            esEdicion: widget.esEdicion,
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
                ? 'Editar reserva'
                : 'Editar ${widget.modulo.nombreSingular}')
          : switch (widget.modulo) {
              ModuloGestion.horarios => 'Configurar Horario',
              ModuloGestion.inasistencias => 'Registrar Inasistencia',
              ModuloGestion.reservas => 'Nueva Reserva',
              ModuloGestion.especialidades => 'Nueva especialidad',
              _ => 'Nuevo ${widget.modulo.nombreSingular}',
            },

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
                            if (_bloqueoConfiguracion != null)
                              cuadroInformacion(_bloqueoConfiguracion!),
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
                                        RutasAplicacion.detalle(
                                          ArgumentosDetalle(
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
                                  RutasAplicacion.listado(
                                    ArgumentosListado(
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
                                  RutasAplicacion.listado(
                                    ArgumentosListado(
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
  Widget _botonGuardar() => BotonPrincipal(
    alPulsar: _bloqueoConfiguracion == null ? _guardar : null,
    cargando: _guardando,
    texto: widget.modulo == ModuloGestion.reservas
        ? widget.esEdicion
              ? 'Revisar cambios'
              : 'Revisar reserva'
        : widget.modulo == ModuloGestion.cierres
        ? 'Revisar y crear cierre'
        : 'Guardar ${widget.modulo.nombreSingular.toLowerCase()}',
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

  bool _esVisible(CampoFormulario f) {
    if (['horaInicioAlmuerzo', 'horaFinAlmuerzo'].contains(f.key)) {
      return _valores['tieneAlmuerzo'] == true;
    }
    if (widget.modulo == ModuloGestion.inasistencias && f.key == 'fechaFin') {
      return _valores['tipoFecha'] == 'rango';
    }
    return true;
  }

  Widget _campo(CampoFormulario campo) => CampoGestion(
    key: ValueKey(campo.key),
    campo: campo,
    valor: _valores[campo.key],
    controlador: _controladores[campo.key]!,
    opciones: [
      for (final registro in _opciones[campo.key] ?? <Map<String, dynamic>>[])
        if (registro['id'] is int)
          OpcionSeleccion(
            id: registro['id'] as int,
            nombre: nombreRegistro(registro),
          ),
    ],
    bloqueado: _guardando,
    alCambiar: (valor) => _asignarValor(campo, valor),
    alEscribir: (valor) => _cambiarTexto(campo, valor),
    alDesactivar:
        widget.esEdicion &&
            [
              ModuloGestion.profesionales,
              ModuloGestion.servicios,
            ].contains(widget.modulo)
        ? () => _confirmarDesactivacion(campo)
        : null,
  );

  void _cambiarTexto(CampoFormulario f, String v) {
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
      final horarios = await widget.servicio.consultarDisponibilidad(
        serviceId: id,
        date: date,
        idProfesional: _valores['profesionalId'] as int?,
      );
      if (!mounted) return;
      final elegido = await showModalBottomSheet<HorarioDisponible>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .8,
          maxWidth: 600,
        ),
        builder: (context) => SelectorHorario(horarios: horarios),
      );
      if (elegido != null && mounted) {
        _asignarValor(
          _campos.firstWhere((campo) => campo.key == 'fechaDia'),
          DateFormat('yyyy-MM-dd').format(elegido.fecha),
        );
        _asignarValor(
          _campos.firstWhere((campo) => campo.key == 'hora'),
          DateFormat('HH:mm:ss').format(elegido.fecha),
        );
      }
    } catch (e) {
      if (mounted) _mostrarError(mensajeError(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}
