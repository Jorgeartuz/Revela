import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/services/remote/servicio_gestion.dart';

class ArgumentosListado {
  const ArgumentosListado({
    required this.modulo,
    required this.servicio,
    this.integrado = false,
    this.soloLectura = false,
    this.idProfesional,
    this.filtrosIniciales = const {},
  });
  final ModuloGestion modulo;
  final ServicioGestion servicio;
  final bool integrado, soloLectura;
  final int? idProfesional;
  final Map<String, String> filtrosIniciales;
}

class ArgumentosFormulario {
  const ArgumentosFormulario({
    required this.modulo,
    required this.servicio,
    this.datosIniciales,
    this.esEdicion = false,
  });
  final ModuloGestion modulo;
  final ServicioGestion servicio;
  final Map<String, dynamic>? datosIniciales;
  final bool esEdicion;
}

class ArgumentosDetalle {
  const ArgumentosDetalle({
    required this.modulo,
    required this.servicio,
    required this.registro,
    this.soloLectura = false,
  });
  final ModuloGestion modulo;
  final ServicioGestion servicio;
  final Map<String, dynamic> registro;
  final bool soloLectura;
}
