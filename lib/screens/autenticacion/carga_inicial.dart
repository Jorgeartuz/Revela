import 'package:flutter/material.dart';
import 'package:revela/config/tema_aplicacion.dart';

class PantallaCargaInicial extends StatefulWidget {
  const PantallaCargaInicial({super.key, required this.child});
  final Widget child;
  @override
  State<PantallaCargaInicial> createState() => _EstadoPantallaCargaInicial();
}

class _EstadoPantallaCargaInicial extends State<PantallaCargaInicial> {
  bool _listo = false;
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _listo = true);
    });
  }

  @override
  Widget build(BuildContext context) => _listo
      ? widget.child
      : MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: ColoresAplicacion.fondo,
            body: Center(
              child: Image.asset(
                'recursos/imagenes/revela_logo.png',
                width: 240,
                height: 158,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
}
