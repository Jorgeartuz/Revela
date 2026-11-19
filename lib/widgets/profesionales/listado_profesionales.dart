import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';

class ListadoProfesionales extends StatelessWidget {
  const ListadoProfesionales({
    super.key,
    required this.registros,
    required this.especialidades,
    required this.controladorBusqueda,
    required this.busqueda,
    required this.filtroEstado,
    required this.especialidadSeleccionada,
    required this.alBuscar,
    required this.alFiltrarEstado,
    required this.alFiltrarEspecialidad,
    required this.alAbrir,
    required this.alActualizar,
    required this.alCrear,
    this.cargando = false,
    this.error,
  });

  final List<Map<String, dynamic>> registros, especialidades;
  final TextEditingController controladorBusqueda;
  final String busqueda, filtroEstado;
  final String? especialidadSeleccionada, error;
  final bool cargando;
  final ValueChanged<String> alBuscar, alFiltrarEstado;
  final ValueChanged<String?> alFiltrarEspecialidad;
  final ValueChanged<Map<String, dynamic>> alAbrir;
  final VoidCallback alActualizar;
  final VoidCallback? alCrear;

  bool? _activo(Map<String, dynamic> registro) {
    final estado = registro['estado'] ?? registro['activo'];
    return estado is bool ? estado : null;
  }

  String? _idEspecialidad(Map<String, dynamic> registro) {
    final dato = registro['especialidadId'] ?? registro['especialidad'];
    return dato is Map ? dato['id']?.toString() : dato?.toString();
  }

  String _nombreEspecialidad(Map<String, dynamic> registro) {
    final dato = registro['especialidad'];
    if (dato is Map && dato['nombre'] is String) {
      return dato['nombre'] as String;
    }
    final id = _idEspecialidad(registro);
    final especialidad = especialidades
        .where((item) => '${item['id']}' == id)
        .firstOrNull;
    if (especialidad != null) return nombreRegistro(especialidad);
    if (dato is String && int.tryParse(dato) == null && dato.isNotEmpty) {
      return dato;
    }
    return 'Sin especialidad';
  }

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

  Widget _insignia(bool? activo) {
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
                  'recursos/iconos/profesionales_${activo ? 'activo' : 'inactivo'}.svg',
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              activo == null
                  ? 'Sin estado'
                  : activo
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

  Widget _tarjeta(Map<String, dynamic> registro) {
    final activo = _activo(registro);
    final nombre = nombreRegistro(registro);
    final porcentaje = '${registro['porcentaje'] ?? '—'}'.replaceFirst(
      RegExp(r'\.0$'),
      '',
    );
    final colorAvatar = registros.indexOf(registro).isEven
        ? ColoresAplicacion.principal
        : ColoresAplicacion.textoAyuda;
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
          onTap: () => alAbrir(registro),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Opacity(
                  opacity: activo == false ? .55 : 1,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: colorAvatar.withValues(alpha: .85),
                    foregroundColor: ColoresAplicacion.fondo,
                    child: Text(
                      iniciales(nombre),
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.2,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Tooltip(
                              message: nombre,
                              child: Text(
                                nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.2,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w600,
                                  color: activo == false
                                      ? ColoresAplicacion.textoSecundario
                                      : ColoresAplicacion.texto,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _insignia(activo),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CC ${registro['documento'] ?? '—'}  ·  Comisión $porcentaje%',
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.2,
                          letterSpacing: 0,
                          color: ColoresAplicacion.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _nombreEspecialidad(registro),
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.2,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w600,
                          color: ColoresAplicacion.principal.withValues(
                            alpha: activo == false ? .6 : 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 9,
                  height: 15,
                  child: SvgPicture.asset(
                    'recursos/iconos/profesionales_flecha.svg',
                  ),
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
    final consulta = busqueda.trim().toLowerCase();
    final visibles = registros.where((registro) {
      if (!'${nombreRegistro(registro)} ${registro['documento'] ?? ''}'
          .toLowerCase()
          .contains(consulta)) {
        return false;
      }
      if (filtroEstado != 'todos' &&
          _activo(registro) != (filtroEstado == 'activos')) {
        return false;
      }
      return especialidadSeleccionada == null ||
          _idEspecialidad(registro) == especialidadSeleccionada;
    }).toList();
    final activos = visibles
        .where((registro) => _activo(registro) == true)
        .length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(21, 41, 21, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Profesionales',
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
                  tooltip: 'Crear profesional',
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
                      'recursos/iconos/profesionales_agregar.svg',
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: controladorBusqueda,
          onChanged: alBuscar,
          style: const TextStyle(fontSize: 14.5, height: 1.2, letterSpacing: 0),
          decoration: InputDecoration(
            hintText: 'Buscar por nombre o documento...',
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
                  'recursos/iconos/profesionales_buscar.svg',
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
        const SizedBox(height: 20),
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
                        'recursos/iconos/profesionales_especialidad.svg',
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
        const SizedBox(height: 20),
        if (cargando)
          const Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error != null) ...[
          Text(
            error!,
            style: const TextStyle(color: ColoresAplicacion.textoSecundario),
          ),
          TextButton(onPressed: alActualizar, child: const Text('Reintentar')),
        ] else ...[
          Text(
            '${visibles.length} ${visibles.length == 1 ? 'PROFESIONAL' : 'PROFESIONALES'}  ·  $activos ${activos == 1 ? 'ACTIVO' : 'ACTIVOS'}',
            style: const TextStyle(
              fontSize: 11,
              height: 1.2,
              letterSpacing: .8,
              color: ColoresAplicacion.textoAyuda,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          if (visibles.isEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No hay resultados para mostrar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ColoresAplicacion.textoSecundario),
              ),
            ),
            TextButton(
              onPressed: () {
                controladorBusqueda.clear();
                alBuscar('');
                alFiltrarEstado('todos');
                alFiltrarEspecialidad(null);
              },
              child: const Text('Limpiar filtros'),
            ),
          ],
          ...visibles.map(_tarjeta),
        ],
      ],
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
