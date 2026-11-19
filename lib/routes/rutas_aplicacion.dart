import 'package:flutter/material.dart';
import 'package:revela/models/navegacion/argumentos_gestion.dart';
import 'package:revela/screens/autenticacion/recuperacion.dart';
import 'package:revela/screens/gestion/listado.dart';
import 'package:revela/screens/gestion/formulario.dart';
import 'package:revela/screens/gestion/detalle.dart';
import 'package:revela/screens/ruta_no_disponible.dart';

class RutasAplicacion {
  RutasAplicacion._();

  static const recuperarContrasena = '/recuperar-contrasena';
  static const listadoGestion = '/gestion/listado';
  static const formularioGestion = '/gestion/formulario';
  static const detalleGestion = '/gestion/detalle';

  static Route<dynamic>? generarRuta(RouteSettings ajustes) {
    final argumentos = ajustes.arguments;
    switch (ajustes.name) {
      case recuperarContrasena:
        return recuperacion(ajustes: ajustes);
      case listadoGestion:
        if (argumentos is ArgumentosListado) {
          return listado(argumentos, ajustes: ajustes);
        }
        break;
      case formularioGestion:
        if (argumentos is ArgumentosFormulario) {
          return formulario(argumentos, ajustes: ajustes);
        }
        break;
      case detalleGestion:
        if (argumentos is ArgumentosDetalle) {
          return detalle(argumentos, ajustes: ajustes);
        }
        break;
    }
    return MaterialPageRoute<void>(
      settings: ajustes,
      builder: (context) => const PantallaRutaNoDisponible(),
    );
  }

  static MaterialPageRoute<void> recuperacion({RouteSettings? ajustes}) {
    return MaterialPageRoute<void>(
      settings: ajustes ?? const RouteSettings(name: recuperarContrasena),
      builder: (context) => const PantallaRecuperacion(),
    );
  }

  static MaterialPageRoute<void> listado(
    ArgumentosListado datos, {
    RouteSettings? ajustes,
  }) {
    return MaterialPageRoute<void>(
      settings:
          ajustes ?? RouteSettings(name: listadoGestion, arguments: datos),
      builder: (context) => PantallaListado(
        modulo: datos.modulo,
        servicio: datos.servicio,
        integrado: datos.integrado,
        soloLectura: datos.soloLectura,
        idProfesional: datos.idProfesional,
        filtrosIniciales: datos.filtrosIniciales,
      ),
    );
  }

  static MaterialPageRoute<bool> formulario(
    ArgumentosFormulario datos, {
    RouteSettings? ajustes,
  }) {
    return MaterialPageRoute<bool>(
      settings:
          ajustes ?? RouteSettings(name: formularioGestion, arguments: datos),
      builder: (context) => PantallaFormulario(
        modulo: datos.modulo,
        servicio: datos.servicio,
        datosIniciales: datos.datosIniciales,
        esEdicion: datos.esEdicion,
      ),
    );
  }

  static MaterialPageRoute<bool> detalle(
    ArgumentosDetalle datos, {
    RouteSettings? ajustes,
  }) {
    return MaterialPageRoute<bool>(
      settings:
          ajustes ?? RouteSettings(name: detalleGestion, arguments: datos),
      builder: (context) => PantallaDetalle(
        modulo: datos.modulo,
        servicio: datos.servicio,
        registro: datos.registro,
        soloLectura: datos.soloLectura,
      ),
    );
  }
}
