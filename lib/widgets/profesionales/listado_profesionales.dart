import 'package:revela/widgets/catalogos/controles_catalogo.dart';
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
                          InsigniaEstado(
                            activo: activo,
                            prefijoIconos: 'profesionales',
                          ),
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
        ControlesCatalogo(
          titulo: 'Profesionales',
          tooltipCrear: 'Crear profesional',
          hintBusqueda: 'Buscar por nombre o documento...',
          prefijoIconos: 'profesionales',
          separacion: 20,
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
