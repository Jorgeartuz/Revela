/// Datos que escribe la persona para iniciar sesión.
/// toJson conserva las claves que exige la API de Revela.
class SolicitudInicioSesion {
  const SolicitudInicioSesion({
    required this.usuario,
    required this.contrasena,
  });

  final String usuario;
  final String contrasena;

  Map<String, dynamic> toJson() => {
    'usuario': usuario.trim(),
    'clave': contrasena,
  };
}
