import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';

class ControlesCatalogo extends StatelessWidget {
  const ControlesCatalogo({
    super.key,
    required this.titulo,
    required this.tooltipCrear,
    required this.hintBusqueda,
    required this.prefijoIconos,
    required this.separacion,
    required this.especialidades,
    required this.controladorBusqueda,
    required this.filtroEstado,
    required this.especialidadSeleccionada,
    required this.alBuscar,
    required this.alFiltrarEstado,
    required this.alFiltrarEspecialidad,
    this.alCrear,
  });
  final String titulo, tooltipCrear, hintBusqueda, prefijoIconos, filtroEstado;
  final double separacion;
  final List<Map<String, dynamic>> especialidades;
  final TextEditingController controladorBusqueda;
  final String? especialidadSeleccionada;
  final ValueChanged<String> alBuscar, alFiltrarEstado;
  final ValueChanged<String?> alFiltrarEspecialidad;
  final VoidCallback? alCrear;
  Widget _chip(String valor, String etiqueta) {
    final seleccionado = filtroEstado == valor;
    return ChoiceChip(
      label: Text(etiqueta),
      selected: seleccionado,
      showCheckmark: false,
      onSelected: (_) => alFiltrarEstado(valor),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      labelPadding: EdgeInsets.zero,
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
        letterSpacing: 0,
        color: seleccionado ? ColoresAplicacion.fondo : ColoresAplicacion.texto,
        fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 22,
                height: 1.36,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (alCrear != null)
            SizedBox(
              width: 36,
              height: 36,
              child: IconButton.filled(
                tooltip: tooltipCrear,
                onPressed: alCrear,
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.standard,
                  backgroundColor: ColoresAplicacion.principal,
                ),
                icon: SizedBox(
                  width: 16,
                  height: 16,
                  child: SvgPicture.asset(
                    'recursos/iconos/${prefijoIconos}_agregar.svg',
                  ),
                ),
              ),
            ),
        ],
      ),
      SizedBox(height: separacion),
      TextField(
        controller: controladorBusqueda,
        onChanged: alBuscar,
        style: const TextStyle(fontSize: 14.5, height: 1.2, letterSpacing: 0),
        decoration: InputDecoration(
          hintText: hintBusqueda,
          hintStyle: const TextStyle(
            fontSize: 14.5,
            height: 1.2,
            letterSpacing: 0,
            color: ColoresAplicacion.textoSecundario,
          ),
          isDense: true,
          visualDensity: VisualDensity.standard,
          constraints: const BoxConstraints(minHeight: 46),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 10, 0),
            child: SizedBox(
              width: 16,
              height: 16,
              child: SvgPicture.asset(
                'recursos/iconos/${prefijoIconos}_buscar.svg',
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 42,
            maxWidth: 42,
            maxHeight: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: ColoresAplicacion.textoSecundario.withValues(alpha: .18),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: ColoresAplicacion.principal),
          ),
        ),
      ),
      SizedBox(height: separacion),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: ColoresAplicacion.superficie,
          border: Border.all(
            color: ColoresAplicacion.textoSecundario.withValues(alpha: .18),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Text(
              'Especialidad:',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.2,
                letterSpacing: 0,
                color: ColoresAplicacion.textoSecundario,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value:
                      especialidades.any(
                        (item) => '${item['id']}' == especialidadSeleccionada,
                      )
                      ? especialidadSeleccionada
                      : null,
                  hint: const Text('Todas'),
                  isDense: true,
                  isExpanded: true,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    height: 1.2,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w500,
                    color: ColoresAplicacion.texto,
                  ),
                  icon: SizedBox(
                    width: 12,
                    height: 8,
                    child: SvgPicture.asset(
                      'recursos/iconos/${prefijoIconos}_especialidad.svg',
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    for (final especialidad in especialidades)
                      DropdownMenuItem(
                        value: '${especialidad['id']}',
                        child: Text(
                          nombreRegistro(especialidad),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: alFiltrarEspecialidad,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Estado:',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.2,
              letterSpacing: 0,
              color: ColoresAplicacion.textoSecundario,
            ),
          ),
          _chip('todos', 'Todos'),
          _chip('activos', 'Activos'),
          _chip('inactivos', 'Inactivos'),
        ],
      ),
      SizedBox(height: separacion),
    ],
  );
}

class InsigniaEstado extends StatelessWidget {
  const InsigniaEstado({
    super.key,
    required this.activo,
    required this.prefijoIconos,
  });
  final bool? activo;
  final String prefijoIconos;
  @override
  Widget build(BuildContext context) {
    final color = activo == true
        ? ColoresAplicacion.texto
        : ColoresAplicacion.textoSecundario;
    return CustomPaint(
      foregroundPainter: activo == false
          ? _BordeInactivo(color.withValues(alpha: .7))
          : null,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: activo == true ? .1 : .12),
          borderRadius: BorderRadius.circular(999),
          border: activo == true
              ? Border.all(color: color.withValues(alpha: .55))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (activo != null) ...[
              SizedBox(
                width: 11,
                height: 11,
                child: SvgPicture.asset(
                  'recursos/iconos/${prefijoIconos}_${activo == true ? 'activo' : 'inactivo'}.svg',
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              activo == null
                  ? 'Sin estado'
                  : activo == true
                  ? 'Activo'
                  : 'Inactivo',
              style: TextStyle(
                fontSize: 11,
                height: 1.2,
                letterSpacing: 0,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BordeInactivo extends CustomPainter {
  const _BordeInactivo(this.color);
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
        canvas.drawPath(
          tramo.extractPath(
            inicio,
            inicio + 3 < tramo.length ? inicio + 3 : tramo.length,
          ),
          pincel,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BordeInactivo anterior) =>
      anterior.color != color;
}
