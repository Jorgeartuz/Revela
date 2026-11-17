import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:revela/configuracion/tema_aplicacion.dart';
import 'package:revela/pantallas/vista_previa/galeria_pantallas.dart';

/// Entrada separada de diseño. No inicia sesión ni accede a la API.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'Revela · Vista de diseño',
      debugShowCheckedModeBanner: false,
      theme: TemaAplicacion.oscuro,
      scrollBehavior: const DesplazamientoRevela(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => Banner(
        message: 'VISTA PREVIA',
        location: BannerLocation.topEnd,
        child: child!,
      ),
      home: const GaleriaPantallas(),
    ),
  );
}
