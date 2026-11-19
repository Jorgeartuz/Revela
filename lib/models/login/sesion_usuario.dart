import 'dart:convert';

class SesionUsuario {
  const SesionUsuario({
    required this.tokenAcceso,
    required this.fechaVencimiento,
    required this.nombreEmpresa,
    required this.idEmpresa,
    this.usuario,
    this.rol,
    this.idProfesional,
  });

  final String tokenAcceso;
  final DateTime fechaVencimiento;
  final String nombreEmpresa;
  final int idEmpresa;
  final String? usuario;
  final String? rol;
  final int? idProfesional;

  bool get estaVencida => !DateTime.now().isBefore(fechaVencimiento);

  factory SesionUsuario.fromJson(
    Map<String, dynamic> datosJson, {
    DateTime? now,
  }) {
    final tokenRecibido = datosJson['accessToken'];
    final tipoToken = datosJson['tokenType'];
    final duracionSegundos = datosJson['expiresIn'];
    final empresa = datosJson['empresaNombre'];
    final idEmpresa = datosJson['empresaId'];
    if (tokenRecibido is! String ||
        tokenRecibido.trim().isEmpty ||
        tipoToken is! String ||
        tipoToken.toLowerCase() != 'bearer' ||
        duracionSegundos is! int ||
        duracionSegundos <= 0 ||
        empresa is! String ||
        idEmpresa is! int) {
      throw const FormatException('Respuesta de sesión incompleta.');
    }
    final ahora = now ?? DateTime.now();
    var vencimientoCalculado = ahora.add(Duration(seconds: duracionSegundos));
    String? usuario;
    String? rol;
    int? idProfesional;

    final partesToken = tokenRecibido.split('.');
    if (partesToken.length == 3) {
      final contenidoToken = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(partesToken[1]))),
      );
      if (contenidoToken is! Map<String, dynamic>) {
        throw const FormatException('Token de sesión inválido.');
      }
      const campoIdProfesional = String.fromEnvironment(
        'PROFESSIONAL_ID_CLAIM',
      );
      if (campoIdProfesional.isNotEmpty) {
        idProfesional = int.tryParse(
          contenidoToken[campoIdProfesional]?.toString() ?? '',
        );
      }
      final datoUsuario = contenidoToken['usuario'];
      final datoRol =
          contenidoToken['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
      usuario = datoUsuario is String ? datoUsuario : null;
      rol = datoRol is String ? datoRol : null;
      final vencimientoUnix = contenidoToken['exp'];
      if (vencimientoUnix is int) {
        final vencimientoToken = DateTime.fromMillisecondsSinceEpoch(
          vencimientoUnix * 1000,
          isUtc: true,
        );
        if (vencimientoToken.isBefore(vencimientoCalculado)) {
          vencimientoCalculado = vencimientoToken;
        }
      }
    }
    if (!vencimientoCalculado.isAfter(ahora)) {
      throw const FormatException('La API devolvió una sesión vencida.');
    }
    return SesionUsuario(
      tokenAcceso: tokenRecibido,
      fechaVencimiento: vencimientoCalculado,
      nombreEmpresa: empresa,
      idEmpresa: idEmpresa,
      usuario: usuario,
      rol: rol,
      idProfesional: idProfesional,
    );
  }
}
