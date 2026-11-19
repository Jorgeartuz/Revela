import 'package:flutter/material.dart';
import 'package:revela/widgets/estructura/barra_aplicacion.dart';

class PantallaRutaNoDisponible extends StatelessWidget {
  const PantallaRutaNoDisponible({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BarraAplicacion(titulo: 'Pantalla no disponible'),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No se pudo abrir esta pantalla. Regresa y vuelve a intentarlo.',
          ),
        ),
      ),
    );
  }
}
