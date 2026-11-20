import 'package:revela/routes/rutas_aplicacion.dart';
import 'package:revela/models/navegacion/argumentos_gestion.dart';
import 'package:revela/widgets/gestion/componentes_operativos.dart';
import 'package:revela/widgets/agenda/agenda_administrativa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/services/remote/servicio_gestion.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/widgets/gestion/componentes_compartidos.dart';

class VistaGestion extends StatefulWidget {
  const VistaGestion({
    super.key,
    required this.modulo,
    required this.servicio,
    this.idProfesional,
    this.soloLectura = false,
    this.filtros = const {},
    this.alIrAlInicio,
    this.mostrarTitulo = false,
  });
  final ModuloGestion modulo;
  final ServicioGestion servicio;
  final int? idProfesional;
  final bool soloLectura;
  final Map<String, String> filtros;
  final VoidCallback? alIrAlInicio;
  final bool mostrarTitulo;
  @override
  State<VistaGestion> createState() => _EstadoVistaGestion();
}

class _EstadoVistaGestion extends State<VistaGestion> {
  late Future<List<Registro>> _consulta;
  Future<List<Registro>>? _profesionales, _cierres;
  Future<Registro?>? _perfil;
  bool get _necesitaPerfil =>
      widget.modulo == ModuloGestion.horarios ||
      (widget.modulo == ModuloGestion.inasistencias && widget.soloLectura);
  Future<T> _observar<T>(Future<T> consulta) {
    consulta.ignore();
    return consulta;
  }

  void _cargarPerfil() {
    _perfil = _necesitaPerfil && _profesionalSeleccionado != null
        ? _observar(
            widget.servicio.obtenerProfesional(_profesionalSeleccionado!),
          )
        : null;
  }

  int? _profesionalSeleccionado, _cierreSeleccionado;
  int? _estadoSeleccionado;
  String _busqueda = '';
  DateTime _diaSeleccionado = DateUtils.dateOnly(DateTime.now());
  @override
  void initState() {
    super.initState();
    _profesionalSeleccionado = widget.idProfesional;
    _cierreSeleccionado = int.tryParse(
      widget.filtros['liquidacionComisionId'] ?? '',
    );
    _cargarPerfil();
    if (!widget.soloLectura && widget.modulo != ModuloGestion.reservas) {
      _profesionales = _observar(
        widget.servicio.listar(ModuloGestion.profesionales),
      );
    }
    if (widget.modulo == ModuloGestion.comisiones) {
      _cierres = _observar(widget.servicio.listar(ModuloGestion.cierres));
    }
    _cargar();
  }

  void _cargar() {
    _consulta = widget.servicio.listar(
      widget.modulo,
      filtros: {
        ...widget.filtros,
        if (_profesionalSeleccionado != null)
          'profesionalId': '$_profesionalSeleccionado',
        if (_cierreSeleccionado != null)
          'liquidacionComisionId': '$_cierreSeleccionado',
        if (widget.modulo == ModuloGestion.reservas)
          'fechaInicio': _diaSeleccionado.toIso8601String(),
        if (widget.modulo == ModuloGestion.reservas)
          'fechaFin': _diaSeleccionado
              .add(const Duration(days: 1))
              .subtract(const Duration(seconds: 1))
              .toIso8601String(),
      },
    );
  }

  Future<void> _actualizar() async {
    setState(() {
      if (_profesionales != null) {
        _profesionales = _observar(
          widget.servicio.listar(ModuloGestion.profesionales),
        );
      }
      if (_cierres != null) {
        _cierres = _observar(widget.servicio.listar(ModuloGestion.cierres));
      }
      _cargarPerfil();
      _cargar();
    });
    try {
      await _consulta;
    } catch (_) {}
  }

  Future<void> _formulario({
    Registro? datosIniciales,
    bool esEdicion = false,
  }) async {
    final changed = await Navigator.push<bool>(
      context,
      RutasAplicacion.formulario(
        ArgumentosFormulario(
          modulo: widget.modulo,
          servicio: widget.servicio,
          datosIniciales:
              datosIniciales ??
              {
                if (_profesionalSeleccionado != null)
                  'profesionalId': _profesionalSeleccionado,
              },
          esEdicion: esEdicion,
        ),
      ),
    );
    if (changed == true && mounted) await _actualizar();
  }

  Future<void> _abrirDetalle(Registro registro) async {
    final changed = await Navigator.push<bool>(
      context,
      RutasAplicacion.detalle(
        ArgumentosDetalle(
          modulo: widget.modulo,
          servicio: widget.servicio,
          registro: registro,
          soloLectura: widget.soloLectura,
        ),
      ),
    );
    if (changed == true && mounted) await _actualizar();
  }

  Widget _selectorProfesional() => FutureBuilder<List<Registro>>(
    future: _profesionales,
    builder: (context, s) {
      if (s.hasError) return cuadroInformacion(mensajeError(s.error));
      if (!s.hasData) return const LinearProgressIndicator();
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DropdownButtonFormField<int>(
          key: ValueKey(
            'professional:$_profesionalSeleccionado:${s.data!.map((r) => r['id']).join(',')}',
          ),
          initialValue: s.data!.any((p) => p['id'] == _profesionalSeleccionado)
              ? _profesionalSeleccionado
              : null,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Profesional'),
          items: [
            if (widget.modulo != ModuloGestion.horarios)
              const DropdownMenuItem<int>(
                value: null,
                child: Text('Todos los profesionales'),
              ),
            for (final p in s.data!)
              DropdownMenuItem(
                value: p['id'] as int,
                child: Text(nombreRegistro(p)),
              ),
          ],
          onChanged: (v) => setState(() {
            _profesionalSeleccionado = v;
            _cargarPerfil();
            _cargar();
          }),
        ),
      );
    },
  );
  Widget _estadoVacio(String title, String message) => tarjeta(
    Column(
      children: [
        const SizedBox(height: 16),
        const Icon(
          Icons.event_available_outlined,
          size: 42,
          color: ColoresAplicacion.textoSecundario,
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
          style: const TextStyle(
            color: ColoresAplicacion.textoSecundario,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        if (widget.alIrAlInicio != null)
          OutlinedButton(
            onPressed: widget.alIrAlInicio,
            child: const Text('Volver al inicio'),
          ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _actualizar,
    child: FutureBuilder<List<Registro>>(
      future: _consulta,
      builder: (context, s) {
        if (s.hasError) {
          return ListView(
            padding: const EdgeInsets.all(21),
            children: [
              cuadroInformacion(mensajeError(s.error)),
              TextButton(
                onPressed: _actualizar,
                child: const Text('Reintentar'),
              ),
            ],
          );
        }
        if (!s.hasData || s.connectionState == ConnectionState.waiting) {
          return ListView(
            children: const [
              Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        }
        if (widget.modulo == ModuloGestion.reservas && !widget.soloLectura) {
          return AgendaAdministrativa(
            registros: s.data!,
            estados: estadosDelServicio(widget.servicio),
            fecha: _diaSeleccionado,
            busqueda: _busqueda,
            estadoSeleccionado: _estadoSeleccionado,
            mostrarTitulo: widget.mostrarTitulo,
            alBuscar: (valor) => setState(() => _busqueda = valor),
            alFiltrar: (estado) => setState(() => _estadoSeleccionado = estado),
            alElegirFecha: _elegirFechaAgenda,
            alCrearReserva: _formulario,
            alAbrirReserva: _abrirDetalle,
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(21, 16, 21, 32),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (widget.modulo == ModuloGestion.reservas) ..._agenda(s.data!),
            if (widget.modulo == ModuloGestion.horarios) ..._horario(s.data!),
            if (widget.modulo == ModuloGestion.inasistencias)
              ..._inasistencias(s.data!),
            if (widget.modulo == ModuloGestion.comisiones)
              ..._comisiones(s.data!),
          ],
        );
      },
    ),
  );
  Future<void> _elegirFechaAgenda() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _diaSeleccionado,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha != null && mounted) {
      setState(() {
        _diaSeleccionado = DateUtils.dateOnly(fecha);
        _cargar();
      });
    }
  }

  List<Widget> _agenda(List<Registro> all) {
    final states = estadosDelServicio(widget.servicio);
    final dayRows =
        all
            .where(
              (r) => DateUtils.isSameDay(
                DateTime.tryParse('${r['fecha']}'),
                _diaSeleccionado,
              ),
            )
            .toList()
          ..sort(
            (a, b) => '${a['horaInicio']}'.compareTo('${b['horaInicio']}'),
          );
    final registros = dayRows
        .where(
          (r) =>
              (_estadoSeleccionado == null ||
                  r['estado'] == _estadoSeleccionado) &&
              '${nombrePersona(r['cliente'])} ${datosAnidados(r, 'servicio')['nombre']} ${nombrePersona(r['profesional'])}'
                  .toLowerCase()
                  .contains(_busqueda.toLowerCase()),
        )
        .toList();
    String count(int? code) => code == null
        ? '—'
        : '${dayRows.where((r) => r['estado'] == code).length}';
    final monday = _diaSeleccionado.subtract(
      Duration(days: _diaSeleccionado.weekday - 1),
    );
    return [
      if (widget.soloLectura)
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: ChoiceChip(
                    padding: EdgeInsets.zero,
                    showCheckmark: false,
                    selectedColor: ColoresAplicacion.principal.withValues(
                      alpha: .25,
                    ),
                    labelPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'][i],
                      style: const TextStyle(fontSize: 10),
                    ),
                    selected: _diaSeleccionado.weekday == i + 1,
                    onSelected: (_) => setState(() {
                      _diaSeleccionado = monday.add(Duration(days: i));
                      _cargar();
                    }),
                  ),
                ),
              ),
          ],
        ),
      if (!widget.soloLectura)
        TextField(
          decoration: const InputDecoration(
            hintText: 'Buscar cliente, servicio...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _busqueda = v),
        ),
      const SizedBox(height: 16),
      tarjeta(
        resumenTotales([
          ('Citas del día', '${dayRows.length}'),
          ('Confirmadas', count(states.confirmada)),
          ('Pendientes', count(states.programada)),
        ]),
      ),
      Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            showCheckmark: false,
            selectedColor: ColoresAplicacion.principal.withValues(alpha: .25),
            label: const Text('Todas'),
            selected: _estadoSeleccionado == null,
            onSelected: (_) => setState(() => _estadoSeleccionado = null),
          ),
          for (final item in [
            ('Programada', states.programada),
            ('Confirmada', states.confirmada),
            ('Atendida', states.atendida),
            ('Cancelada', states.cancelada),
          ])
            ChoiceChip(
              showCheckmark: false,
              selectedColor: ColoresAplicacion.principal.withValues(alpha: .25),
              label: Text(item.$1),
              selected: item.$2 != null && _estadoSeleccionado == item.$2,
              onSelected: item.$2 == null
                  ? null
                  : (_) => setState(() => _estadoSeleccionado = item.$2),
            ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: tituloSeccion(
              DateFormat(
                'EEEE · d MMMM',
                'es',
              ).format(_diaSeleccionado).toUpperCase(),
            ),
          ),
          IconButton(
            tooltip: 'Elegir fecha',
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _diaSeleccionado,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (d != null && mounted) {
                setState(() {
                  _diaSeleccionado = DateUtils.dateOnly(d);
                  _cargar();
                });
              }
            },
          ),
        ],
      ),
      if (!widget.soloLectura && _profesionales != null) _selectorProfesional(),
      if (registros.isEmpty)
        _estadoVacio(
          widget.soloLectura ? 'Sin citas para este día' : 'Sin reservas',
          'No hay citas que coincidan con los filtros seleccionados.',
        ),
      for (final r in registros)
        tarjeta(
          InkWell(
            onTap: () => _abrirDetalle(r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        textoHora(r['horaInicio']),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      states.label(r['estado'] as int?) ??
                          'Estado sin identificar',
                      style: const TextStyle(
                        fontSize: 10,
                        color: ColoresAplicacion.principal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: ColoresAplicacion.principal,
                      foregroundColor: ColoresAplicacion.fondo,
                      child: Text(iniciales(nombrePersona(r['cliente']))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombrePersona(r['cliente']),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${datosAnidados(r, 'servicio')['nombre'] ?? 'Servicio'} · ${widget.soloLectura ? '${datosAnidados(r, 'servicio')['duracion'] ?? '—'} min' : nombrePersona(r['profesional'])}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: ColoresAplicacion.textoSecundario,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${datosAnidados(datosAnidados(r, 'profesional'), 'especialidad')['nombre'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: ColoresAplicacion.principal,
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
      if (!widget.soloLectura)
        Align(
          alignment: Alignment.centerRight,
          child: Tooltip(
            message: 'Crear reserva',
            child: FilledButton.icon(
              onPressed: () => _formulario(),
              icon: const Icon(Icons.add_circle),
              label: const Text('Reserva'),
            ),
          ),
        ),
    ];
  }

  List<Widget> _horario(List<Registro> all) {
    final registros = all
        .where(
          (r) =>
              _profesionalSeleccionado == null ||
              r['profesionalId'] == _profesionalSeleccionado,
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
    final codes = widget.servicio.diasSemana;
    Widget clockLine(String asset, String text, {bool muted = false}) =>
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            children: [
              SvgPicture.asset(
                'recursos/iconos/$asset.svg',
                width: 13,
                height: 13,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    color: muted
                        ? ColoresAplicacion.textoSecundario
                        : ColoresAplicacion.texto,
                  ),
                ),
              ),
            ],
          ),
        );
    Widget day(Registro? registro, String label, {String? key}) => tarjeta(
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14)),
                if (registro == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Sin horario configurado',
                      style: TextStyle(
                        fontSize: 12,
                        color: ColoresAplicacion.textoSecundario,
                      ),
                    ),
                  )
                else ...[
                  clockLine(
                    'schedule_clock',
                    '${textoHora(registro['horaInicio'])} – ${textoHora(registro['horaFin'])}',
                  ),
                  clockLine(
                    'schedule_lunch',
                    registro['tieneAlmuerzo'] == true
                        ? 'Almuerzo ${textoHora(registro['horaInicioAlmuerzo'])} – ${textoHora(registro['horaFinAlmuerzo'])}'
                        : 'Sin almuerzo',
                    muted: true,
                  ),
                ],
              ],
            ),
          ),
          if (!widget.soloLectura)
            IconButton(
              tooltip: registro == null ? 'Configurar $label' : 'Editar $label',
              icon: Icon(
                registro == null ? Icons.add : Icons.edit_outlined,
                size: 18,
              ),
              onPressed: _profesionalSeleccionado == null
                  ? null
                  : () => _formulario(
                      datosIniciales:
                          registro ??
                          {
                            'profesionalId': _profesionalSeleccionado,
                            'dia': key,
                          },
                      esEdicion: registro != null,
                    ),
            ),
        ],
      ),
    );
    return [
      tituloSeccion('PROFESIONAL'),
      if (!widget.soloLectura && widget.idProfesional == null)
        _selectorProfesional(),
      if (_perfil != null)
        FutureBuilder<Registro?>(
          future: _perfil,
          builder: (c, s) => s.hasError
              ? cuadroInformacion(mensajeError(s.error))
              : s.connectionState == ConnectionState.waiting
              ? const LinearProgressIndicator()
              : tarjetaProfesional(s.data),
        ),
      if (_profesionalSeleccionado == null)
        cuadroInformacion(
          'Selecciona un profesional para ver su horario de trabajo.',
        )
      else ...[
        tituloSeccion('HORARIO SEMANAL'),
        if (codes.length == 7)
          for (var i = 0; i < 7; i++)
            day(
              registros
                  .where((r) => r['diaSemana'] == codes[keys[i]])
                  .firstOrNull,
              labels[i],
              key: keys[i],
            )
        else ...[
          for (final r in registros) day(r, nombreDia(r['diaSemana'])),
          cuadroInformacion(
            'Los nombres de los días se mostrarán cuando el centro confirme su configuración.',
          ),
        ],
      ],
    ];
  }

  List<Widget> _inasistencias(List<Registro> registros) => [
    if (widget.soloLectura) ...[
      tituloSeccion('PROFESIONAL'),
      FutureBuilder<Registro?>(
        future: _perfil,
        builder: (c, s) => s.hasError
            ? cuadroInformacion(mensajeError(s.error))
            : s.connectionState == ConnectionState.waiting
            ? const LinearProgressIndicator()
            : tarjetaProfesional(s.data),
      ),
    ] else if (_profesionales != null)
      _selectorProfesional(),
    tituloSeccion('${registros.length} INASISTENCIAS REGISTRADAS'),
    if (registros.isEmpty)
      _estadoVacio(
        'Sin inasistencias',
        'No tienes inasistencias registradas. Cuando se registre una ausencia por salud, situación familiar u otra causa justificada, aparecerá aquí.',
      ),
    for (final r in registros) _tarjetaInasistencia(r),
    if (!widget.soloLectura)
      FilledButton.icon(
        onPressed: () => _formulario(),
        icon: const Icon(Icons.add),
        label: const Text('Registrar inasistencia'),
      ),
  ];
  Widget _tarjetaInasistencia(Registro r) {
    final start = DateTime.tryParse('${r['fechaInicio']}'),
        end = DateTime.tryParse('${r['fechaFin']}');
    final range =
        start != null && end != null && !DateUtils.isSameDay(start, end);
    final duration = start == null || end == null
        ? null
        : DateUtils.dateOnly(end).difference(DateUtils.dateOnly(start)).inDays +
              1;
    final finished = end?.isBefore(DateTime.now()) ?? false;
    final motive = r['motivoNombre'];
    return tarjeta(
      InkWell(
        onTap: widget.soloLectura ? null : () => _abrirDetalle(r),
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
                      color: ColoresAplicacion.textoSecundario,
                    ),
                  ),
                ),
                Text(
                  '${finished ? 'Finalizada' : 'Próxima'} · ${duration ?? '—'} ${duration == 1 ? 'día' : 'días'}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: ColoresAplicacion.textoSecundario,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              range
                  ? '${formatoFecha(r['fechaInicio'])} → ${formatoFecha(r['fechaFin'])}'
                  : formatoFecha(r['fechaInicio']),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              r['profesional'] is Map
                  ? nombrePersona(r['profesional'])
                  : 'Profesional #${r['profesionalId']}',
              style: const TextStyle(
                fontSize: 12,
                color: ColoresAplicacion.textoSecundario,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Motivo: ${motive ?? r['observacion'] ?? 'Sin descripción'}',
              style: const TextStyle(
                fontSize: 12,
                color: ColoresAplicacion.principal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _comisiones(List<Registro> all) {
    final registros = all
        .where(
          (r) =>
              (_profesionalSeleccionado == null ||
                  r['profesionalId'] == _profesionalSeleccionado) &&
              (_cierreSeleccionado == null ||
                  r['liquidacionComisionId'] == _cierreSeleccionado ||
                  r['liquidacionId'] == _cierreSeleccionado),
        )
        .toList();
    num? sum(String key) => registros.any((r) => r[key] is! num)
        ? null
        : registros.fold<num>(0, (v, r) => v + (r[key] as num));
    return [
      if (_cierres != null)
        FutureBuilder<List<Registro>>(
          future: _cierres,
          builder: (c, s) => s.hasError
              ? cuadroInformacion(mensajeError(s.error))
              : !s.hasData
              ? const LinearProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<int>(
                    key: ValueKey(
                      'closure:$_cierreSeleccionado:${s.data!.map((r) => r['id']).join(',')}',
                    ),
                    initialValue:
                        s.data!.any((r) => r['id'] == _cierreSeleccionado)
                        ? _cierreSeleccionado
                        : null,
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
                            '#CIE-${r['id']} · ${formatoFecha(r['fechaInicio'])} – ${formatoFecha(r['fechaFin'])}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      _cierreSeleccionado = v;
                      _cargar();
                    }),
                  ),
                ),
        ),
      if (_profesionales != null) _selectorProfesional(),
      tituloSeccion(
        _cierreSeleccionado == null
            ? 'CONSOLIDADO DE COMISIONES'
            : 'CONSOLIDADO DEL CIERRE',
      ),
      tarjeta(
        resumenTotales([
          ('Servicios', '${sum('cantidadServicios') ?? '—'}'),
          ('Base/total', formatoMoneda(sum('base'))),
          ('Comisiones', formatoMoneda(sum('valorComision'))),
        ]),
        accent: true,
      ),
      tituloSeccion('${registros.length} COMISIONES'),
      if (registros.isEmpty)
        _estadoVacio(
          'Sin comisiones',
          'No hay comisiones para el cierre y los filtros seleccionados.',
        ),
      for (final r in registros)
        tarjeta(
          InkWell(
            onTap: () => _abrirDetalle(r),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: ColoresAplicacion.principal,
                      foregroundColor: ColoresAplicacion.fondo,
                      child: Text(iniciales(nombrePersona(r['profesional']))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        nombrePersona(r['profesional']),
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
                resumenTotales([
                  ('Servicios realizados', '${r['cantidadServicios'] ?? '—'}'),
                  ('Base/total', formatoMoneda(r['base'])),
                  ('Valor comisión', formatoMoneda(r['valorComision'])),
                ]),
              ],
            ),
          ),
        ),
    ];
  }
}
