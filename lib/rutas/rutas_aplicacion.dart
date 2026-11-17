import 'package:flutter/material.dart';
import 'package:revela/pantallas/autenticacion/pantalla_recuperacion.dart';

/// Centraliza las rutas comunes, como app_routes.dart en el ejemplo del profesor.
/// Las pantallas de gestión reciben registros y servicios al construir su ruta.
class RutasAplicacion {
  RutasAplicacion._();

  static const recuperarContrasena = '/recuperar-contrasena';

  static Route<void>? generarRuta(RouteSettings ajustes) {
    switch (ajustes.name) {
      case recuperarContrasena:
        return recuperacion();
      default:
        return null;
    }
  }

  // Esta fábrica también permite abrir la pantalla desde una vista aislada.
  static MaterialPageRoute<void> recuperacion() => MaterialPageRoute<void>(
    settings: const RouteSettings(name: recuperarContrasena),
    builder: (context) => const PantallaRecuperacion(),
  );
}
