import 'package:flutter/material.dart';

class BotonPrincipal extends StatelessWidget {
  const BotonPrincipal({
    super.key,
    required this.texto,
    required this.alPulsar,
    this.cargando = false,
    this.mensajeCarga = 'Guardando',
  });

  final String texto;
  final VoidCallback? alPulsar;
  final bool cargando;
  final String mensajeCarga;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: cargando ? null : alPulsar,
    child: cargando
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              semanticsLabel: mensajeCarga,
            ),
          )
        : Text(texto),
  );
}
