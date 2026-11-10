enum AccountRole { administrator, professional, unsupported }

abstract final class RolePolicy {
  // No se presupone el nombre de otros roles de la API.
  static const professionalRole = String.fromEnvironment('PROFESSIONAL_ROLE');
  static AccountRole resolve(
    String? role, {
    String professional = professionalRole,
  }) {
    final value = role?.trim().toLowerCase();
    if (value == 'gestor') return AccountRole.administrator;
    if (professional.trim().isNotEmpty &&
        value == professional.trim().toLowerCase()) {
      return AccountRole.professional;
    }
    return AccountRole.unsupported;
  }
}
