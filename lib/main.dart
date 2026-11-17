import 'package:flutter/material.dart';

import 'package:revela/aplicacion.dart';
import 'package:revela/pantallas/autenticacion/pantalla_recuperacion.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PantallaCargaInicial(child: AplicacionRevela()));
}
