enum RolUsuario { administrador, profesional, noAdmitido }

abstract final class PoliticaRoles {
  static const nombreRolProfesional = String.fromEnvironment(
    'PROFESSIONAL_ROLE',
  );
  static RolUsuario resolver(
    String? rol, {
    String profesional = nombreRolProfesional,
  }) {
    final value = rol?.trim().toLowerCase();
    if (value == 'gestor') return RolUsuario.administrador;
    if (profesional.trim().isNotEmpty &&
        value == profesional.trim().toLowerCase()) {
      return RolUsuario.profesional;
    }
    return RolUsuario.noAdmitido;
  }
}
