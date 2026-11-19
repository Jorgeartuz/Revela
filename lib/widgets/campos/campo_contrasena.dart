import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:revela/config/tema_aplicacion.dart';

class CampoContrasena extends StatefulWidget {
  const CampoContrasena({
    super.key,
    this.claveCampo,
    required this.controlador,
    this.habilitado = true,
    this.alEnviar,
  });

  final Key? claveCampo;
  final TextEditingController controlador;
  final bool habilitado;
  final VoidCallback? alEnviar;

  @override
  State<CampoContrasena> createState() => _EstadoCampoContrasena();
}

class _EstadoCampoContrasena extends State<CampoContrasena> {
  bool _ocultarContrasena = true;
  Widget _icono(String name, double width, double height) => Center(
    widthFactor: 1,
    heightFactor: 1,
    child: SvgPicture.asset(
      'recursos/iconos/$name.svg',
      width: width,
      height: height,
    ),
  );

  @override
  Widget build(BuildContext context) => TextFormField(
    key: widget.claveCampo,
    controller: widget.controlador,
    enabled: widget.habilitado,
    obscureText: _ocultarContrasena,
    enableSuggestions: false,
    autocorrect: false,
    autofillHints: const [AutofillHints.password],
    textInputAction: TextInputAction.done,
    onFieldSubmitted: (_) => widget.alEnviar?.call(),
    decoration: InputDecoration(
      hintText: '**********',
      prefixIcon: _icono('lock', 18, 20.25),
      suffixIcon: IconButton(
        tooltip: _ocultarContrasena
            ? 'Mostrar contraseña'
            : 'Ocultar contraseña',
        onPressed: () =>
            setState(() => _ocultarContrasena = !_ocultarContrasena),
        icon: _ocultarContrasena
            ? _icono('visibility', 18.333, 12.5)
            : const Icon(
                Icons.visibility_off_outlined,
                size: 19,
                color: ColoresAplicacion.texto,
              ),
      ),
    ),
    validator: (value) =>
        value == null || value.isEmpty ? 'Ingresa tu contraseña' : null,
  );
}
