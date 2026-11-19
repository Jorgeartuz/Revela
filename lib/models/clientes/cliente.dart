class Cliente {
  const Cliente({
    this.id,
    required this.documento,
    required this.nombres,
    required this.apellidos,
    this.fechaNacimiento,
    this.celular,
    this.correo,
  });

  final int? id;
  final String documento;
  final String nombres;
  final String apellidos;
  final String? fechaNacimiento;
  final String? celular;
  final String? correo;

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as int?,
      documento: json['documento'] as String? ?? '',
      nombres: json['nombres'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
      fechaNacimiento: json['fechaNacimiento'] as String?,
      celular: json['celular'] as String?,
      correo: json['correo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documento': documento,
      'nombres': nombres,
      'apellidos': apellidos,
      'fechaNacimiento': fechaNacimiento,
      'celular': celular,
      'correo': correo,
    };
  }
}
