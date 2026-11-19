import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/services/remote/servicio_gestion.dart';

class NavegacionProfesional extends StatelessWidget {
  const NavegacionProfesional({
    super.key,
    required this.servicio,
    this.selected = 1,
  });
  final ServicioGestion servicio;
  final int selected;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: ColoresAplicacion.superficie,
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 80,
        child: Row(
          children: [
            for (var i = 0; i < 5; i++)
              Expanded(
                child: InkWell(
                  onTap: servicio.alCambiarPestanaProfesional == null
                      ? null
                      : () => servicio.alCambiarPestanaProfesional!(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 54,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i == selected
                              ? ColoresAplicacion.principal.withValues(
                                  alpha: .18,
                                )
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: SvgPicture.asset(
                          'recursos/iconos/${['nav_home', 'nav_agenda', 'nav_my_services', 'nav_schedule', 'nav_more'][i]}.svg',
                          width: 22,
                          height: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ['Inicio', 'Agenda', 'Servicios', 'Horario', 'Más'][i],
                        style: TextStyle(
                          fontSize: 10.5,
                          color: i == selected
                              ? ColoresAplicacion.principal
                              : ColoresAplicacion.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
