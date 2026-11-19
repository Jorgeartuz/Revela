import 'package:flutter/material.dart';

class CampoTexto extends StatelessWidget {
  const CampoTexto({
    super.key,
    this.claveCampo,
    required this.controlador,
    required this.pista,
    this.icono,
    this.habilitado = true,
    this.validar,
    this.autocompletar,
    this.accionTeclado = TextInputAction.next,
  });

  final Key? claveCampo;
  final TextEditingController controlador;
  final String pista;
  final Widget? icono;
  final bool habilitado;
  final FormFieldValidator<String>? validar;
  final Iterable<String>? autocompletar;
  final TextInputAction accionTeclado;

  @override
  Widget build(BuildContext context) => TextFormField(
    key: claveCampo,
    controller: controlador,
    enabled: habilitado,
    autofillHints: autocompletar,
    autocorrect: false,
    textInputAction: accionTeclado,
    decoration: InputDecoration(hintText: pista, prefixIcon: icono),
    validator: validar,
  );
}
