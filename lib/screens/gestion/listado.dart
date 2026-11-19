import 'package:revela/widgets/servicios/listado_servicios.dart';
import 'package:revela/widgets/menu/menu_administrativo.dart';
import 'package:revela/widgets/profesionales/listado_profesionales.dart';
import 'package:revela/routes/rutas_aplicacion.dart';
import 'package:revela/models/navegacion/argumentos_gestion.dart';
import 'package:revela/screens/profesional/navegacion_profesional.dart';
import 'package:revela/screens/gestion/vistas_gestion.dart';
import 'package:flutter/material.dart';

import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/services/remote/servicio_gestion.dart';
import 'package:revela/widgets/gestion/componentes_compartidos.dart';

class PantallaListado extends StatefulWidget {
  const PantallaListado({
    super.key,
    required this.modulo,
    required this.servicio,
    this.integrado = false,
    this.idProfesional,
    this.soloLectura = false,
    this.filtrosIniciales = const {},
  });
  final ModuloGestion modulo;
  final ServicioGestion servicio;
  final bool integrado, soloLectura;
  final int? idProfesional;
  final Map<String, String> filtrosIniciales;
  @override
  State<PantallaListado> createState() => _EstadoPantallaListado();
}

class _EstadoPantallaListado extends State<PantallaListado> {
  late Future<List<Map<String, dynamic>>> _consulta;
  final _controladorBusqueda = TextEditingController();
  Future<List<Map<String, dynamic>>>? _especialidades;
  final _serviciosProcesando = <int>{};
  String _busqueda = '';
  String _filtroEstado = 'todos';
  String? _especialidadSeleccionada;
  DateTimeRange? _periodo;
  bool get _tieneVistaEspecifica => [
    ModuloGestion.reservas,
    ModuloGestion.horarios,
    ModuloGestion.inasistencias,
    ModuloGestion.comisiones,
  ].contains(widget.modulo);
  @override
  void initState() {
    super.initState();
    if (_tieneVistaEspecifica) return;
    _cargar();
    if (widget.modulo == ModuloGestion.servicios ||
        widget.modulo == ModuloGestion.profesionales) {
      _especialidades = widget.servicio.listar(ModuloGestion.especialidades);
    }
  }

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  void _cargar() {
    final filtros = {
      ...widget.filtrosIniciales,
      if (widget.idProfesional != null)
        'profesionalId': '${widget.idProfesional}',
    };
    if (_periodo != null) {
      filtros['fechaInicio'] = _periodo!.start
          .toIso8601String()
          .split('T')
          .first;
      filtros['fechaFin'] = _periodo!.end.toIso8601String().split('T').first;
    }
    _consulta = widget.servicio.listar(widget.modulo, filtros: filtros);
  }

  Future<void> _actualizar() async {
    setState(() {
      if (_especialidades != null) {
        _especialidades = widget.servicio.listar(ModuloGestion.especialidades);
      }
      _cargar();
    });
    try {
      await _consulta;
    } catch (_) {}
  }

  Future<void> _formulario() async {
    final changed = await Navigator.push<bool>(
      context,
      RutasAplicacion.formulario(
        ArgumentosFormulario(
          modulo: widget.modulo,
          servicio: widget.servicio,
          datosIniciales: widget.idProfesional == null
              ? null
              : {'profesionalId': widget.idProfesional},
        ),
      ),
    );
    if (changed == true && mounted) await _actualizar();
  }

  Future<void> _abrirDetalle(Map<String, dynamic> registro) async {
    final changed = await Navigator.push<bool>(
      context,
      RutasAplicacion.detalle(
        ArgumentosDetalle(
          modulo: widget.modulo,
          registro: registro,
          servicio: widget.servicio,
          soloLectura: widget.soloLectura,
        ),
      ),
    );
    if (changed == true && mounted) await _actualizar();
  }

  void _navegar(ModuloGestion? modulo) {
    if (modulo == null) {
      widget.servicio.alIrAlInicio?.call();
      Navigator.popUntil(context, (r) => r.isFirst);
      return;
    }
    Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute(
        builder: (context) => modulo == ModuloGestion.especialidades
            ? PantallaMenuGestion(servicio: widget.servicio)
            : PantallaListado(modulo: modulo, servicio: widget.servicio),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final specialized = [
      ModuloGestion.reservas,
      ModuloGestion.horarios,
      ModuloGestion.inasistencias,
      ModuloGestion.comisiones,
    ].contains(widget.modulo);
    final content = specialized
        ? VistaGestion(
            modulo: widget.modulo,
            servicio: widget.servicio,
            idProfesional: widget.idProfesional,
            soloLectura: widget.soloLectura,
            filtros: widget.filtrosIniciales,
            mostrarTitulo: widget.integrado,
            alIrAlInicio: () {
              widget.servicio.alIrAlInicio?.call();
              Navigator.popUntil(context, (r) => r.isFirst);
            },
          )
        : widget.modulo == ModuloGestion.profesionales
        ? _contenidoProfesionales()
        : widget.modulo == ModuloGestion.servicios
        ? _contenidoServicios()
        : _contenido();
    if (widget.integrado) return content;
    if (widget.modulo == ModuloGestion.profesionales ||
        widget.modulo == ModuloGestion.servicios) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: content,
            ),
          ),
        ),
        bottomNavigationBar: SectionNavigation(
          modulo: widget.modulo,
          seleccionCuadrada: true,
          onSelect: _navegar,
        ),
      );
    }
    return SectionShell(
      title: widget.soloLectura
          ? switch (widget.modulo) {
              ModuloGestion.reservas => 'Mi Agenda',
              ModuloGestion.horarios => 'Mi Horario',
              ModuloGestion.inasistencias => 'Mis Inasistencias',
              _ => widget.modulo.title,
            }
          : widget.modulo == ModuloGestion.horarios
          ? 'Horario de Trabajo'
          : widget.modulo.title,

      centrarTitulo:
          widget.modulo == ModuloGestion.reservas && !widget.soloLectura,
      actions: widget.modulo.puedeCrear && !widget.soloLectura && !specialized
          ? [
              IconButton(
                tooltip: 'Crear ${widget.modulo.nombreSingular.toLowerCase()}',
                onPressed: _formulario,
                icon: const Icon(Icons.add),
              ),
            ]
          : null,
      bottom: widget.soloLectura
          ? NavegacionProfesional(
              servicio: widget.servicio,
              selected: widget.modulo == ModuloGestion.horarios
                  ? 3
                  : widget.modulo == ModuloGestion.inasistencias
                  ? 4
                  : 1,
            )
          : SectionNavigation(modulo: widget.modulo, onSelect: _navegar),
      child: content,
    );
  }

  Widget _contenidoProfesionales() => RefreshIndicator(
    onRefresh: _actualizar,
    child: FutureBuilder<List<Map<String, dynamic>>>(
      future: _consulta,
      builder: (context, resultado) =>
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _especialidades,
            builder: (context, catalogo) => ListadoProfesionales(
              registros: resultado.data ?? [],
              especialidades: catalogo.data ?? [],
              controladorBusqueda: _controladorBusqueda,
              busqueda: _busqueda,
              filtroEstado: _filtroEstado,
              especialidadSeleccionada: _especialidadSeleccionada,
              cargando:
                  resultado.connectionState == ConnectionState.waiting ||
                  catalogo.connectionState == ConnectionState.waiting,
              error: resultado.hasError
                  ? mensajeError(resultado.error)
                  : catalogo.hasError
                  ? mensajeError(catalogo.error)
                  : null,
              alBuscar: (valor) => setState(() => _busqueda = valor),
              alFiltrarEstado: (valor) => setState(() => _filtroEstado = valor),
              alFiltrarEspecialidad: (valor) =>
                  setState(() => _especialidadSeleccionada = valor),
              alCrear: widget.soloLectura ? null : _formulario,
              alAbrir: _abrirDetalle,
              alActualizar: _actualizar,
            ),
          ),
    ),
  );

  Future<void> _editarServicio(Map<String, dynamic> registro) async {
    final cambio = await Navigator.push<bool>(
      context,
      RutasAplicacion.formulario(
        ArgumentosFormulario(
          modulo: ModuloGestion.servicios,
          servicio: widget.servicio,
          datosIniciales: registro,
          esEdicion: true,
        ),
      ),
    );
    if (cambio == true && mounted) await _actualizar();
  }

  Future<void> _cambiarEstadoServicio(Map<String, dynamic> registro) async {
    final id = registro['id'];
    final activo = registro['activo'] ?? registro['estado'];
    if (id is! int || activo is! bool || _serviciosProcesando.contains(id)) {
      return;
    }
    setState(() {
      _serviciosProcesando.add(id);
    });
    try {
      await widget.servicio.guardar(ModuloGestion.servicios, {
        'activo': !activo,
      }, id: id);
      if (mounted) await _actualizar();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mensajeError(error))));
      }
    } finally {
      if (mounted) {
        setState(() {
          _serviciosProcesando.remove(id);
        });
      }
    }
  }

  Widget _contenidoServicios() => RefreshIndicator(
    onRefresh: _actualizar,
    child: FutureBuilder<List<Map<String, dynamic>>>(
      future: _consulta,
      builder: (context, resultado) =>
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _especialidades,
            builder: (context, catalogo) => ListadoServicios(
              registros: resultado.data ?? [],
              especialidades: catalogo.data ?? [],
              controladorBusqueda: _controladorBusqueda,
              busqueda: _busqueda,
              filtroEstado: _filtroEstado,
              especialidadSeleccionada: _especialidadSeleccionada,
              cargando:
                  resultado.connectionState == ConnectionState.waiting ||
                  catalogo.connectionState == ConnectionState.waiting,
              error: resultado.hasError
                  ? mensajeError(resultado.error)
                  : catalogo.hasError
                  ? mensajeError(catalogo.error)
                  : null,
              alBuscar: (valor) => setState(() => _busqueda = valor),
              alFiltrarEstado: (valor) => setState(() => _filtroEstado = valor),
              alFiltrarEspecialidad: (valor) =>
                  setState(() => _especialidadSeleccionada = valor),
              alCrear: widget.soloLectura ? null : _formulario,
              alEditar: widget.soloLectura ? null : _editarServicio,
              alCambiarEstado: widget.soloLectura
                  ? null
                  : _cambiarEstadoServicio,
              procesando: _serviciosProcesando,
              alActualizar: _actualizar,
            ),
          ),
    ),
  );

  Widget _contenido() => RefreshIndicator(
    onRefresh: _actualizar,
    child: FutureBuilder<List<Map<String, dynamic>>>(
      future: _consulta,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              cuadroInformacion(mensajeError(snapshot.error)),
              TextButton(
                onPressed: _actualizar,
                child: const Text('Reintentar'),
              ),
            ],
          );
        }
        final all = snapshot.data ?? [];
        final registros = all.where((r) {
          final text =
              '${nombreRegistro(r)} ${r['documento'] ?? ''} ${r['descripcion'] ?? ''} ${nombrePersona(r['cliente'])} ${nombrePersona(r['profesional'])}'
                  .toLowerCase();
          if (!text.contains(_busqueda.toLowerCase())) return false;
          final active = r['activo'] ?? r['estado'] ?? r['activa'];
          if (active is bool &&
              _filtroEstado != 'todos' &&
              active != (_filtroEstado == 'activos')) {
            return false;
          }
          if (_especialidadSeleccionada != null &&
              '${r['especialidadId'] ?? (r['especialidad'] is Map ? (r['especialidad'] as Map)['id'] : null)}' !=
                  _especialidadSeleccionada) {
            return false;
          }
          return true;
        }).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(21, 16, 21, 32),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (widget.integrado)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.modulo.title,
                      style: const TextStyle(
                        fontFamily: 'OpenSans',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (widget.modulo.puedeCrear && !widget.soloLectura)
                    IconButton.filled(
                      tooltip:
                          'Crear ${widget.modulo.nombreSingular.toLowerCase()}',
                      onPressed: _formulario,
                      icon: const Icon(Icons.add),
                    ),
                ],
              ),
            if (widget.integrado) const SizedBox(height: 20),
            TextField(
              controller: _controladorBusqueda,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o documento...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _busqueda = v),
            ),
            const SizedBox(height: 14),
            if ([
              ModuloGestion.servicios,
              ModuloGestion.profesionales,
              ModuloGestion.especialidades,
            ].contains(widget.modulo))
              Wrap(
                spacing: 8,
                children: [
                  for (final option in {
                    'todos': 'Todos',
                    'activos': 'Activos',
                    'inactivos': 'Inactivos',
                  }.entries)
                    ChoiceChip(
                      showCheckmark: false,
                      selectedColor: ColoresAplicacion.principal.withValues(
                        alpha: .25,
                      ),
                      label: Text(option.value),
                      selected: _filtroEstado == option.key,
                      onSelected: (_) =>
                          setState(() => _filtroEstado = option.key),
                    ),
                ],
              ),
            if ([
              ModuloGestion.reservas,
              ModuloGestion.cierres,
              ModuloGestion.comisiones,
            ].contains(widget.modulo))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _periodo == null
                        ? 'Seleccionar período'
                        : '${formatoFecha(_periodo!.start.toIso8601String())} — ${formatoFecha(_periodo!.end.toIso8601String())}',
                  ),
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDateRange: _periodo,
                    );
                    if (range != null && mounted) {
                      setState(() {
                        _periodo = range;
                        _cargar();
                      });
                    }
                  },
                ),
              ),
            tituloSeccion(
              '${registros.length} ${widget.modulo.title.toUpperCase()}',
            ),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (registros.isEmpty)
              Column(
                children: [
                  const SizedBox(height: 20),
                  const Icon(
                    Icons.search_off,
                    size: 40,
                    color: ColoresAplicacion.textoSecundario,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No hay resultados para mostrar.',
                    style: TextStyle(color: ColoresAplicacion.textoSecundario),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _controladorBusqueda.clear();
                      _busqueda = '';
                      _filtroEstado = 'todos';
                      _especialidadSeleccionada = null;
                      _periodo = null;
                      _cargar();
                    }),
                    child: const Text('Limpiar filtros'),
                  ),
                  if (widget.modulo.puedeCrear && !widget.soloLectura)
                    TextButton(
                      onPressed: _formulario,
                      child: Text(
                        'Crear ${widget.modulo.nombreSingular.toLowerCase()}',
                      ),
                    ),
                ],
              )
            else
              ...registros.map(
                (registro) => RecordCard(
                  modulo: widget.modulo,
                  registro: registro,

                  onTap: () => _abrirDetalle(registro),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class PantallaMenuGestion extends StatelessWidget {
  const PantallaMenuGestion({super.key, required this.servicio});
  final ServicioGestion servicio;

  void _navegar(BuildContext context, ModuloGestion? modulo) {
    if (modulo == null) {
      servicio.alIrAlInicio?.call();
      Navigator.popUntil(context, (route) => route.isFirst);
    } else if (modulo != ModuloGestion.especialidades) {
      Navigator.pushReplacement<void, void>(
        context,
        RutasAplicacion.listado(
          ArgumentosListado(modulo: modulo, servicio: servicio),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: MenuAdministrativo(
            alCerrarSesion: servicio.alCerrarSesion,
            alAbrirModulo: (modulo) => Navigator.push<void>(
              context,
              RutasAplicacion.listado(
                ArgumentosListado(modulo: modulo, servicio: servicio),
              ),
            ),
          ),
        ),
      ),
    ),
    bottomNavigationBar: SectionNavigation(
      modulo: ModuloGestion.especialidades,
      seleccionCuadrada: true,
      onSelect: (modulo) => _navegar(context, modulo),
    ),
  );
}
