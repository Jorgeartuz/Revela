import 'package:flutter/material.dart';

import 'package:revela/aplicacion.dart';
import 'package:revela/screens/autenticacion/carga_inicial.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PantallaCargaInicial(child: AplicacionRevela()));
}
