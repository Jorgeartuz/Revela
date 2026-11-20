import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/models/gestion/valores_registro.dart';
import 'package:revela/models/inicio/reserva.dart';
import 'package:revela/widgets/gestion/componentes_operativos.dart';

class AgendaAdministrativa extends StatelessWidget {
  const AgendaAdministrativa({
    super.key,
    required this.registros,
    required this.estados,
    required this.fecha,
    required this.busqueda,
    required this.estadoSeleccionado,
    required this.alBuscar,
    required this.alFiltrar,
    required this.alElegirFecha,
    required this.alCrearReserva,
    required this.alAbrirReserva,
    this.mostrarTitulo = false,
  });

  final List<Registro> registros;
  final EstadosReserva estados;
  final DateTime fecha;
  final String busqueda;
  final int? estadoSeleccionado;
  final ValueChanged<String> alBuscar;
  final ValueChanged<int?> alFiltrar;
  final VoidCallback alElegirFecha, alCrearReserva;
  final ValueChanged<Registro> alAbrirReserva;
  final bool mostrarTitulo;

  String? _estado(Registro registro) {
    final codigo = registro['estado'];
    if (codigo == null) return null;
    if (estados.confirmada != null && codigo == estados.confirmada) {
      return 'Confirmada';
    }
    if (estados.cancelada != null && codigo == estados.cancelada) {
      return 'Cancelada';
    }
    if (estados.atendida != null && codigo == estados.atendida) {
      return 'Atendida';
    }
    if (estados.programada != null && codigo == estados.programada) {
      return 'Programada';
    }
    return null;
  }

  Color _color(String? estado) => switch (estado) {
    'Confirmada' => ColoresAplicacion.texto,
    'Atendida' => ColoresAplicacion.principal,
    'Programada' => ColoresAplicacion.textoAyuda,
    _ => ColoresAplicacion.textoSecundario,
  };

  Widget _indicador(String etiqueta, String valor, {bool pendiente = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ColoresAplicacion.superficie,
          border: Border.all(
            color: ColoresAplicacion.textoSecundario.withValues(alpha: .15),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valor,
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 20,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: pendiente
                    ? ColoresAplicacion.textoAyuda
                    : ColoresAplicacion.texto,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                etiqueta,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  letterSpacing: 0,
                  color: ColoresAplicacion.textoSecundario,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filtro(String etiqueta, int? codigo, {bool todos = false}) {
    final seleccionado = todos
        ? estadoSeleccionado == null
        : codigo != null && estadoSeleccionado == codigo;
    return ChoiceChip(
      label: Text(etiqueta),
      selected: seleccionado,
      onSelected: todos || codigo != null ? (_) => alFiltrar(codigo) : null,
      showCheckmark: false,
      labelPadding: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      shape: const StadiumBorder(),
      side: BorderSide(
        color: seleccionado
            ? Colors.transparent
            : ColoresAplicacion.textoSecundario.withValues(alpha: .18),
      ),
      backgroundColor: ColoresAplicacion.superficie,
      selectedColor: ColoresAplicacion.principal,
      labelStyle: TextStyle(
        fontSize: 12.5,
        height: 1.2,
        fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w500,
        color: seleccionado ? ColoresAplicacion.fondo : ColoresAplicacion.texto,
      ),
    );
  }

  Widget _etiqueta(String? estado) {
    final color = _color(estado);
    final icono = switch (estado) {
      'Confirmada' => 'agenda_confirmada',
      'Cancelada' => 'agenda_cancelada',
      'Atendida' => 'agenda_atendida',
      _ => null,
    };
    return CustomPaint(
      foregroundPainter: estado == 'Cancelada'
          ? _BordeDiscontinuo(color.withValues(alpha: .7))
          : null,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: estado == 'Confirmada' ? .1 : .15),
          borderRadius: BorderRadius.circular(999),
          border: estado == 'Confirmada' || estado == 'Atendida'
              ? Border.all(
                  color: color.withValues(
                    alpha: estado == 'Confirmada' ? .55 : .7,
                  ),
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icono != null) ...[
              SizedBox(
                width: 11,
                height: 11,
                child: SvgPicture.asset('recursos/iconos/$icono.svg'),
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                estado ?? 'Sin identificar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjeta(Registro registro) {
    final estado = _estado(registro);
    final servicio = datosAnidados(registro, 'servicio');
    final profesional = datosAnidados(registro, 'profesional');
    final especialidad =
        datosAnidados(profesional, 'especialidad')['nombre'] ??
        datosAnidados(servicio, 'especialidad')['nombre'];
    final minutos = minutosDeHora(registro['horaInicio']);
    final hora = minutos == null
        ? 'Sin horario'
        : '${((minutos ~/ 60) % 12 == 0 ? 12 : (minutos ~/ 60) % 12).toString().padLeft(2, '0')}:${(minutos % 60).toString().padLeft(2, '0')} ${minutos < 720 ? 'am' : 'pm'}';
    final nombre = nombrePersona(registro['cliente']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: ColoresAplicacion.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: ColoresAplicacion.textoSecundario.withValues(alpha: .15),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => alAbrirReserva(registro),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        hora,
                        style: const TextStyle(
                          fontFamily: 'OpenSans',
                          fontSize: 15,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _etiqueta(estado),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _color(estado).withValues(alpha: .85),
                      foregroundColor: ColoresAplicacion.fondo,
                      child: Text(
                        iniciales(nombre),
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${servicio['nombre'] ?? 'Servicio'}  ·  ${nombrePersona(registro['profesional'])}',
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.2,
                              color: ColoresAplicacion.textoSecundario,
                            ),
                          ),
                          if (especialidad is String &&
                              especialidad.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              especialidad,
                              style: const TextStyle(
                                fontSize: 11,
                                height: 1.2,
                                color: ColoresAplicacion.principal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final delDia =
        registros
            .where(
              (registro) => DateUtils.isSameDay(
                DateTime.tryParse('${registro['fecha']}'),
                fecha,
              ),
            )
            .toList()
          ..sort(
            (a, b) => (minutosDeHora(a['horaInicio']) ?? 1440).compareTo(
              minutosDeHora(b['horaInicio']) ?? 1440,
            ),
          );
    final consulta = busqueda.trim().toLowerCase();
    final visibles = delDia
        .where(
          (registro) =>
              (estadoSeleccionado == null ||
                  registro['estado'] == estadoSeleccionado) &&
              '${nombrePersona(registro['cliente'])} ${datosAnidados(registro, 'servicio')['nombre']} ${nombrePersona(registro['profesional'])}'
                  .toLowerCase()
                  .contains(consulta),
        )
        .toList();
    String contar(int? estado) => estado == null
        ? '—'
        : '${delDia.where((registro) => registro['estado'] == estado).length}';
    final etiquetaFecha =
        '${DateUtils.isSameDay(fecha, DateTime.now()) ? 'HOY · ' : ''}${DateFormat("d 'de' MMMM", 'es').format(fecha).toUpperCase()}';
    return Column(
      children: [
        if (mostrarTitulo)
          const Padding(
            padding: EdgeInsets.fromLTRB(21, 24, 21, 18),
            child: Text(
              'Agenda',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 22,
                height: 1.36,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, medidas) => Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(21, 0, 21, 88),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    TextFormField(
                      initialValue: busqueda,
                      onChanged: alBuscar,
                      style: const TextStyle(fontSize: 14.5, height: 1.2),
                      decoration: InputDecoration(
                        hintText: 'Buscar cliente, servicio...',
                        isDense: true,
                        visualDensity: VisualDensity.standard,
                        constraints: const BoxConstraints(minHeight: 46),
                        hintStyle: const TextStyle(
                          fontSize: 14.5,
                          height: 1.2,
                          color: ColoresAplicacion.textoSecundario,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 10, 0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: SvgPicture.asset(
                              'recursos/iconos/agenda_buscar.svg',
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 42,
                          maxWidth: 42,
                          maxHeight: 16,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: ColoresAplicacion.textoSecundario.withValues(
                              alpha: .18,
                            ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: ColoresAplicacion.principal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _indicador('Reservas hoy', '${delDia.length}'),
                          const SizedBox(width: 10),
                          _indicador('Confirmadas', contar(estados.confirmada)),
                          const SizedBox(width: 10),
                          _indicador(
                            'Pendientes',
                            contar(estados.programada),
                            pendiente: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _filtro('Todas', null, todos: true),
                        _filtro('Programada', estados.programada),
                        _filtro('Confirmada', estados.confirmada),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _filtro('Atendida', estados.atendida),
                        _filtro('Cancelada', estados.cancelada),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Tooltip(
                        message: 'Elegir fecha',
                        child: InkWell(
                          onTap: alElegirFecha,
                          child: Padding(
                            padding: EdgeInsets.zero,
                            child: Text(
                              etiquetaFecha,
                              style: const TextStyle(
                                fontSize: 11,
                                height: 1.2,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .8,
                                color: ColoresAplicacion.textoAyuda,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (visibles.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 36),
                        child: Text(
                          'No hay citas que coincidan con los filtros seleccionados.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ColoresAplicacion.textoSecundario,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ...visibles.map(_tarjeta),
                  ],
                ),
                Positioned(
                  right: 21,
                  bottom: medidas.maxHeight >= 700 ? 134 : 20,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x73000000),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: FilledButton(
                      onPressed: alCrearReserva,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 0),
                        visualDensity: VisualDensity.standard,
                        padding: const EdgeInsets.fromLTRB(20, 14, 22, 14),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.5,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: SvgPicture.asset(
                              'recursos/iconos/agenda_reserva.svg',
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Reserva'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BordeDiscontinuo extends CustomPainter {
  const _BordeDiscontinuo(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final borde = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.5),
          Radius.circular(size.height / 2),
        ),
      );
    final pincel = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final tramo in borde.computeMetrics()) {
      for (double inicio = 0; inicio < tramo.length; inicio += 5) {
        final fin = inicio + 3 < tramo.length ? inicio + 3 : tramo.length;
        canvas.drawPath(tramo.extractPath(inicio, fin), pincel);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BordeDiscontinuo anterior) =>
      anterior.color != color;
}
