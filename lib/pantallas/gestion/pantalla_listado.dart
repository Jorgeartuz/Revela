import 'package:revela/pantallas/profesional/navegacion_profesional.dart';
import 'package:revela/pantallas/gestion/vistas_gestion.dart';
import 'package:flutter/material.dart';

import 'package:revela/configuracion/tema_aplicacion.dart';
import 'package:revela/modelos/gestion/modulo_gestion.dart';
import 'package:revela/servicios/remoto/servicio_gestion.dart';
import 'package:revela/componentes/gestion/componentes_compartidos.dart';
import 'package:revela/pantallas/gestion/pantalla_formulario.dart';
import 'package:revela/pantallas/gestion/pantalla_detalle.dart';

/// Lista, busca y filtra registros; permite abrir su formulario o su detalle.
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
  String _busqueda = '';
  String _filtroEstado = 'todos';
  String? _especialidadSeleccionada;
  DateTimeRange? _periodo;
  int? _esProfesional;
  Future<List<Map<String, dynamic>>>? _profesionales;
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
    if ([
          ModuloGestion.horarios,
          ModuloGestion.inasistencias,
          ModuloGestion.comisiones,
          ModuloGestion.reservas,
        ].contains(widget.modulo) &&
        widget.idProfesional == null) {
      _profesionales = widget.servicio.listar(ModuloGestion.profesionales);
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
      if (_esProfesional != null) 'profesionalId': '$_esProfesional',
    };
    if (_periodo != null) {
      filtros['fechaInicio'] = widget.modulo == ModuloGestion.reservas
          ? _periodo!.start.toIso8601String()
          : _periodo!.start.toIso8601String().split('T').first;
      filtros['fechaFin'] = widget.modulo == ModuloGestion.reservas
          ? _periodo!.end
                .add(const Duration(days: 1))
                .subtract(const Duration(microseconds: 1))
                .toIso8601String()
          : _periodo!.end.toIso8601String().split('T').first;
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
      MaterialPageRoute(
        builder: (context) => PantallaFormulario(
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
      MaterialPageRoute(
        builder: (context) => PantallaDetalle(
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
            alIrAlInicio: () {
              widget.servicio.alIrAlInicio?.call();
              Navigator.popUntil(context, (r) => r.isFirst);
            },
          )
        : _contenido();
    if (widget.integrado) return content;
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
      vistaPrevia: widget.servicio.vistaPrevia,
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
            const SizedBox(height: 20),
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
            if (widget.modulo == ModuloGestion.servicios ||
                widget.modulo == ModuloGestion.profesionales)
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _especialidades,
                builder: (context, s) => s.hasError
                    ? cuadroInformacion(mensajeError(s.error))
                    : s.hasData
                    ? DropdownButtonFormField<String>(
                        key: ValueKey(
                          'specialty:$_especialidadSeleccionada:${s.data!.map((r) => r['id']).join(',')}',
                        ),
                        initialValue:
                            s.data!.any(
                              (r) => '${r['id']}' == _especialidadSeleccionada,
                            )
                            ? _especialidadSeleccionada
                            : null,
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
                              child: Text(nombreRegistro(r)),
                            ),
                        ],
                        onChanged: (v) =>
                            setState(() => _especialidadSeleccionada = v),
                      )
                    : const SizedBox.shrink(),
              ),
            if (_profesionales != null)
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _profesionales,
                builder: (context, s) => s.hasData
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: DropdownButtonFormField<int>(
                          initialValue: _esProfesional,
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
                                child: Text(nombreRegistro(r)),
                              ),
                          ],
                          onChanged: (v) => setState(() {
                            _esProfesional = v;
                            _cargar();
                          }),
                        ),
                      )
                    : const SizedBox.shrink(),
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
                      _esProfesional = null;
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
                  vistaPrevia: widget.servicio.vistaPrevia,
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
  @override
  Widget build(BuildContext context) => SectionShell(
    title: 'Más',
    vistaPrevia: servicio.vistaPrevia,
    child: ListView(
      padding: const EdgeInsets.all(21),
      children: [
        tituloSeccion('GESTIÓN DEL CENTRO'),
        for (final modulo in ModuloGestion.values)
          ListTile(
            title: Text(modulo.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PantallaListado(modulo: modulo, servicio: servicio),
              ),
            ),
          ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () {
            servicio.alIrAlInicio?.call();
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          child: const Text('Volver al inicio'),
        ),
      ],
    ),
  );
}
