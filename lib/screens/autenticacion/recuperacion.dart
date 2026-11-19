import 'package:flutter/material.dart';
import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/widgets/gestion/componentes_compartidos.dart';

class PantallaRecuperacion extends StatelessWidget {
  const PantallaRecuperacion({super.key});

  @override
  Widget build(BuildContext context) => SectionShell(
    title: 'Recuperar acceso',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Image.asset('recursos/imagenes/revela_logo.png', height: 120),
        const SizedBox(height: 32),
        const Text(
          'RECUPERAR ACCESO',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Para restablecer tu contraseña, contacta al administrador del centro de belleza. La recuperación automática todavía no está disponible.',
          style: TextStyle(color: ColoresAplicacion.textoSecundario),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Volver al inicio de sesión'),
        ),
      ],
    ),
  );
}
