import 'package:flutter/material.dart';

import 'package:revela/configuracion/tema_aplicacion.dart';
import 'package:revela/componentes/gestion/componentes_compartidos.dart';

class PantallaRecuperacion extends StatefulWidget {
  const PantallaRecuperacion({
    super.key,
    this.vistaPrevia = false,
    this.pasoInicial = 0,
    this.mostrarError = false,
  });
  final bool vistaPrevia, mostrarError;
  final int pasoInicial;
  @override
  State<PantallaRecuperacion> createState() => _EstadoPantallaRecuperacion();
}

class _EstadoPantallaRecuperacion extends State<PantallaRecuperacion> {
  final _formulario = GlobalKey<FormState>();
  final _usuario = TextEditingController(),
      _codigo = TextEditingController(),
      _contrasena = TextEditingController(),
      _confirmacionContrasena = TextEditingController();
  late int _paso;
  bool _ocultarContrasena = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _paso = widget.pasoInicial;
    if (widget.vistaPrevia && widget.mostrarError) {
      _error = _paso == 1
          ? 'El código ingresado no es válido. Verifica e inténtalo nuevamente.'
          : 'Las contraseñas no coinciden.';
      if (_paso == 1) _codigo.text = '186742';
    }
  }

  @override
  void dispose() {
    _usuario.dispose();
    _codigo.dispose();
    _contrasena.dispose();
    _confirmacionContrasena.dispose();
    super.dispose();
  }

  void _siguientePaso() {
    if (!_formulario.currentState!.validate()) return;
    if (!widget.vistaPrevia) {
      setState(
        () => _error = 'La recuperación automática no está habilitada. Contacta al administrador del centro para restablecer el acceso.',
      );
      return;
    }
    if (_paso == 1 && _codigo.text != '123456') {
      setState(() => _error = 'El código de ejemplo no es válido. Usa 123456.');
      return;
    }
    setState(() {
      _paso++;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) => SectionShell(
    title: _paso == 0
        ? 'Recuperar acceso'
        : _paso == 1
        ? 'Verificación de seguridad'
        : _paso == 2
        ? 'Nueva contraseña'
        : 'Contraseña actualizada',
    vistaPrevia: widget.vistaPrevia,
    child: Form(
      key: _formulario,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              [
                'RECUPERAR\nACCESO',
                'VERIFICACIÓN\nDE SEGURIDAD',
                'NUEVA\nCONTRASEÑA',
                'CONTRASEÑA\nACTUALIZADA',
              ][_paso.clamp(0, 3)],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 36,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            _paso == 0
                ? 'Ingresa el correo o nombre de usuario asociado a tu cuenta de REVELA.'
                : _paso == 1
                ? 'Introduce el código de seis dígitos.'
                : _paso == 2
                ? 'Crea una nueva contraseña y confírmala.'
                : 'El flujo de ejemplo terminó. No se modificó ninguna cuenta real.',
            style: const TextStyle(color: ColoresAplicacion.textoSecundario),
          ),
          const SizedBox(height: 32),
          if (_paso == 0)
            TextFormField(
              controller: _usuario,
              decoration: const InputDecoration(
                labelText: 'Correo o usuario',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Ingresa tu correo o usuario.'
                  : null,
            ),
          if (_paso == 1) ...[
            TextFormField(
              controller: _codigo,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Código de verificación',
              ),
              validator: (v) => !RegExp(r'^\d{6}$').hasMatch(v ?? '')
                  ? 'Introduce seis dígitos.'
                  : null,
            ),
            if (widget.vistaPrevia)
              cuadroInformacion('Código de ejemplo: 123456'),
            TextButton(
              onPressed: () => setState(
                () => _error = widget.vistaPrevia
                    ? 'Código de ejemplo: 123456'
                    : 'El reenvío de códigos no está habilitado.',
              ),
              child: const Text('Reenviar código'),
            ),
          ],
          if (_paso == 2) ...[
            TextFormField(
              controller: _contrasena,
              obscureText: _ocultarContrasena,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña',
                suffixIcon: IconButton(
                  tooltip: 'Mostrar u ocultar contraseña',
                  onPressed: () =>
                      setState(() => _ocultarContrasena = !_ocultarContrasena),
                  icon: Icon(
                    _ocultarContrasena
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
              ),
              validator: (v) =>
                  (v ?? '').length < 8 ? 'Usa al menos ocho caracteres.' : null,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _confirmacionContrasena,
              obscureText: _ocultarContrasena,
              decoration: const InputDecoration(
                labelText: 'Confirmar contraseña',
              ),
              validator: (v) => v != _contrasena.text
                  ? 'Las contraseñas no coinciden.'
                  : null,
            ),
          ],
          if (_error != null)
            Semantics(liveRegion: true, child: cuadroInformacion(_error!)),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _paso < 3
                ? _siguientePaso
                : () => Navigator.pop(context),
            child: Text(
              [
                'Enviar código de verificación',
                'Validar y continuar',
                'Actualizar contraseña',
                'Volver al inicio',
              ][_paso.clamp(0, 3)],
            ),
          ),
          const SizedBox(height: 24),
          cuadroInformacion(
            'Si necesitas ayuda, contacta al administrador del centro de belleza.',
          ),
          TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Soporte técnico'),
                content: const Text(
                  'Solicita asistencia al administrador del centro de belleza.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            ),
            child: const Text('¿Necesitas soporte técnico?'),
          ),
        ],
      ),
    ),
  );
}

class PantallaCargaInicial extends StatefulWidget {
  const PantallaCargaInicial({super.key, required this.child});
  final Widget child;
  @override
  State<PantallaCargaInicial> createState() => _EstadoPantallaCargaInicial();
}

class _EstadoPantallaCargaInicial extends State<PantallaCargaInicial> {
  bool _listo = false;
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _listo = true);
    });
  }

  @override
  Widget build(BuildContext context) => _listo
      ? widget.child
      : MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: ColoresAplicacion.fondo,
            body: Center(
              child: Image.asset(
                'recursos/imagenes/revela_logo.png',
                width: 240,
                height: 158,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
}
