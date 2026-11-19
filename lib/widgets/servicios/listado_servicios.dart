import 'package:revela/widgets/catalogos/controles_catalogo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';

class ListadoServicios extends StatelessWidget {
  const ListadoServicios({
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
    required this.alEditar,
    required this.alCambiarEstado,
    required this.procesando,
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
  final ValueChanged<Map<String, dynamic>>? alEditar, alCambiarEstado;
  final Set<int> procesando;
  final VoidCallback alActualizar;
  final VoidCallback? alCrear;

  bool? _activo(Map<String, dynamic> registro) {
    final estado = registro['activo'] ?? registro['estado'];
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

  Widget _icono(String nombre, double ancho, double alto) => SizedBox(
    width: ancho,
    height: alto,
    child: SvgPicture.asset('recursos/iconos/servicios_$nombre.svg'),
  );

  Widget _tarjeta(Map<String, dynamic> registro) {
    final activo = _activo(registro);
    final id = registro['id'];
    final ocupado = id is int && procesando.contains(id);
    final color = activo == false
        ? ColoresAplicacion.textoSecundario
        : ColoresAplicacion.texto;
    final precio = registro['precio'];
    final acciones = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (activo != null)
          Tooltip(
            message: activo ? 'Desactivar servicio' : 'Activar servicio',
            child: Semantics(
              label:
                  '${activo ? 'Desactivar' : 'Activar'} ${nombreRegistro(registro)}',
              toggled: activo,
              enabled: alCambiarEstado != null && !ocupado,
              child: InkWell(
                key: ValueKey('estado-servicio-$id'),
                borderRadius: BorderRadius.circular(999),
                onTap: alCambiarEstado == null || ocupado
                    ? null
                    : () => alCambiarEstado!(registro),
                child: ocupado
                    ? const SizedBox(
                        width: 36,
                        height: 20,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : _icono(activo ? 'encendido' : 'apagado', 36, 20),
              ),
            ),
          ),
        if (alEditar != null) ...[
          const SizedBox(width: 12),
          OutlinedButton(
            key: ValueKey('editar-servicio-$id'),
            onPressed: ocupado ? null : () => alEditar!(registro),
            style: OutlinedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.fromLTRB(10, 5, 12, 5),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.standard,
              side: const BorderSide(color: ColoresAplicacion.textoAyuda),
              shape: const StadiumBorder(),
              foregroundColor: ColoresAplicacion.texto,
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                height: 1.2,
                letterSpacing: 0,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _icono('editar', 12, 12),
                const SizedBox(width: 5),
                const Text('Editar'),
              ],
            ),
          ),
        ],
      ],
    );
    final especialidad = Text(
      _nombreEspecialidad(registro),
      style: const TextStyle(
        fontSize: 11.5,
        height: 1.2,
        letterSpacing: 0,
        fontWeight: FontWeight.w600,
        color: ColoresAplicacion.principal,
      ),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ColoresAplicacion.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ColoresAplicacion.textoSecundario.withValues(alpha: .15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  id == null
                      ? 'Sin código'
                      : '#SV-${id.toString().padLeft(3, '0')}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.2,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w500,
                    color: ColoresAplicacion.textoSecundario,
                  ),
                ),
              ),
              InsigniaEstado(activo: activo, prefijoIconos: 'servicios'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            nombreRegistro(registro),
            style: TextStyle(
              fontSize: 15.5,
              height: 1.2,
              letterSpacing: 0,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                precio is num
                    ? '${r'$'}${NumberFormat.decimalPattern('es_CO').format(precio)}'
                    : 'Precio no disponible',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Text(
                '·',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  color: ColoresAplicacion.textoSecundario,
                ),
              ),
              Text(
                registro['duracion'] == null
                    ? 'Duración no disponible'
                    : '${registro['duracion']} min',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.2,
                  letterSpacing: 0,
                  color: ColoresAplicacion.textoSecundario,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, limites) {
              if (limites.maxWidth < 290 ||
                  MediaQuery.textScalerOf(context).scale(12) > 14) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    especialidad,
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerRight, child: acciones),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: especialidad),
                  const SizedBox(width: 12),
                  acciones,
                ],
              );
            },
          ),
        ],
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(21, 32, 21, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ControlesCatalogo(
          titulo: 'Servicios',
          tooltipCrear: 'Crear servicio',
          hintBusqueda: 'Buscar por nombre...',
          prefijoIconos: 'servicios',
          separacion: 16,
          especialidades: especialidades,
          controladorBusqueda: controladorBusqueda,
          filtroEstado: filtroEstado,
          especialidadSeleccionada: especialidadSeleccionada,
          alBuscar: alBuscar,
          alFiltrarEstado: alFiltrarEstado,
          alFiltrarEspecialidad: alFiltrarEspecialidad,
          alCrear: alCrear,
        ),
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
            '${visibles.length} ${visibles.length == 1 ? 'SERVICIO' : 'SERVICIOS'}',
            style: const TextStyle(
              fontSize: 11,
              height: 1.2,
              letterSpacing: .8,
              color: ColoresAplicacion.textoAyuda,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
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
