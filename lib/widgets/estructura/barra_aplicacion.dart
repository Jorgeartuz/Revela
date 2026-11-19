import 'package:flutter/material.dart';
import 'package:revela/config/tema_aplicacion.dart';

class BarraAplicacion extends StatelessWidget implements PreferredSizeWidget {
  const BarraAplicacion({
    super.key,
    required this.titulo,
    this.acciones,
    this.centrarTitulo = false,
  });

  final String titulo;
  final List<Widget>? acciones;
  final bool centrarTitulo;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: centrarTitulo,
      title: Text(
        titulo,
        style: TextStyle(
          fontFamily: 'OpenSans',
          fontSize: centrarTitulo ? 22 : 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: acciones,
      backgroundColor: ColoresAplicacion.fondo,
      surfaceTintColor: Colors.transparent,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
