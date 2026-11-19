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
