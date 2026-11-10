import 'dart:convert';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.expiresAt,
    required this.companyName,
    required this.companyId,
    this.username,
    this.role,
    this.professionalId,
  });

  final String accessToken;
  final DateTime expiresAt;
  final String companyName;
  final int companyId;
  final String? username;
  final String? role;
  final int? professionalId;

  bool get isExpired => !DateTime.now().isBefore(expiresAt);

  factory AuthSession.fromJson(Map<String, dynamic> json, {DateTime? now}) {
    final token = json['accessToken'];
    final type = json['tokenType'];
    final ttl = json['expiresIn'];
    final company = json['empresaNombre'];
    final companyId = json['empresaId'];
    if (token is! String ||
        token.trim().isEmpty ||
        type is! String ||
        type.toLowerCase() != 'bearer' ||
        ttl is! int ||
        ttl <= 0 ||
        company is! String ||
        companyId is! int) {
      throw const FormatException('Respuesta de sesión incompleta.');
    }
    final current = now ?? DateTime.now();
    var expiry = current.add(Duration(seconds: ttl));
    String? username;
    String? role;
    int? professionalId;
    // Los claims sirven únicamente para presentar la interfaz.
    // Los permisos siempre los valida el servidor con el token original.
    final parts = token.split('.');
    if (parts.length == 3) {
      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Token de sesión inválido.');
      }
      const professionalClaim = String.fromEnvironment('PROFESSIONAL_ID_CLAIM');
      if (professionalClaim.isNotEmpty) {
        professionalId = int.tryParse(
          decoded[professionalClaim]?.toString() ?? '',
        );
      }
      final userClaim = decoded['usuario'];
      final roleClaim =
          decoded['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
      username = userClaim is String ? userClaim : null;
      role = roleClaim is String ? roleClaim : null;
      final exp = decoded['exp'];
      if (exp is int) {
        final jwtExpiry = DateTime.fromMillisecondsSinceEpoch(
          exp * 1000,
          isUtc: true,
        );
        if (jwtExpiry.isBefore(expiry)) expiry = jwtExpiry;
      }
    }
    if (!expiry.isAfter(current)) {
      throw const FormatException('La API devolvió una sesión vencida.');
    }
    return AuthSession(
      accessToken: token,
      expiresAt: expiry,
      companyName: company,
      companyId: companyId,
      username: username,
      role: role,
      professionalId: professionalId,
    );
  }
}
