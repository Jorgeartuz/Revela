import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';

class MenuAdministrativo extends StatelessWidget {
  const MenuAdministrativo({
    super.key,
    required this.alAbrirModulo,
    required this.alCerrarSesion,
  });

  final ValueChanged<ModuloGestion> alAbrirModulo;
  final VoidCallback? alCerrarSesion;

  Widget _seccion(String titulo) => Text(
    titulo,
    style: const TextStyle(
      fontSize: 11,
      height: 1.2,
      letterSpacing: .8,
      fontWeight: FontWeight.w600,
      color: ColoresAplicacion.textoAyuda,
    ),
  );

  Widget _opcion(
    ModuloGestion modulo,
    String titulo,
    String descripcion,
    String icono,
  ) {
    return Material(
      color: ColoresAplicacion.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: ColoresAplicacion.textoSecundario.withValues(alpha: .15),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          onTap: () => alAbrirModulo(modulo),
          visualDensity: VisualDensity.standard,
          minTileHeight: 64,
          minVerticalPadding: 12,
          minLeadingWidth: 40,
          horizontalTitleGap: 14,
          contentPadding: const EdgeInsets.fromLTRB(14, 0, 16, 0),
          titleAlignment: ListTileTitleAlignment.center,
          leading: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ColoresAplicacion.textoAyuda.withValues(alpha: .25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox(
              width: 18,
              height: 18,
              child: SvgPicture.asset('recursos/iconos/$icono.svg'),
            ),
          ),
          title: Text(
            titulo,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.2,
              letterSpacing: 0,
              fontWeight: FontWeight.w600,
              color: ColoresAplicacion.texto,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              descripcion,
              style: const TextStyle(
                fontSize: 12,
                height: 1.2,
                letterSpacing: 0,
                color: ColoresAplicacion.textoSecundario,
              ),
            ),
          ),
          trailing: SizedBox(
            width: 9,
            height: 15,
            child: SvgPicture.asset('recursos/iconos/mas_flecha.svg'),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(21, 32, 21, 24),
      children: [
        const Text(
          'Más',
          style: TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 22,
            height: 1.36,
            fontWeight: FontWeight.w600,
            color: ColoresAplicacion.texto,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Módulos de administración de REVELA',
          style: TextStyle(
            fontSize: 13,
            height: 1.2,
            letterSpacing: 0,
            color: ColoresAplicacion.textoSecundario,
          ),
        ),
        const SizedBox(height: 14),
        _seccion('CATÁLOGOS'),
        const SizedBox(height: 14),
        _opcion(
          ModuloGestion.especialidades,
          'Especialidades',
          'Crear, editar y activar especialidades',
          'mas_especialidades',
        ),
        const SizedBox(height: 10),
        _opcion(
          ModuloGestion.servicios,
          'Servicios',
          'Precios, duración y estado de servicios',
          'mas_servicios',
        ),
        const SizedBox(height: 14),
        _seccion('PROFESIONALES'),
        const SizedBox(height: 14),
        _opcion(
          ModuloGestion.horarios,
          'Horarios',
          'Jornada laboral y almuerzo por profesional',
          'mas_horarios',
        ),
        const SizedBox(height: 10),
        _opcion(
          ModuloGestion.inasistencias,
          'Inasistencias',
          'Registrar días o rangos no disponibles',
          'mas_inasistencias',
        ),
        const SizedBox(height: 14),
        _seccion('CIERRES Y COMISIONES'),
        const SizedBox(height: 14),
        _opcion(
          ModuloGestion.cierres,
          'Cierres',
          'Crear y consultar cierres por periodo',
          'mas_cierres',
        ),
        const SizedBox(height: 10),
        _opcion(
          ModuloGestion.comisiones,
          'Comisiones',
          'Consolidado y detalle por profesional',
          'mas_comisiones',
        ),
        const SizedBox(height: 14),
        _seccion('CUENTA'),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: alCerrarSesion,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            visualDensity: VisualDensity.standard,
            foregroundColor: ColoresAplicacion.texto,
            side: const BorderSide(color: ColoresAplicacion.textoAyuda),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              height: 1.2,
              letterSpacing: 0,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}
