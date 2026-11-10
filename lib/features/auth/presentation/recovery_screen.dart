import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../management/presentation/shared.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({
    super.key,
    this.preview = false,
    this.initialStage = 0,
    this.showError = false,
  });
  final bool preview, showError;
  final int initialStage;
  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final _form = GlobalKey<FormState>();
  final _user = TextEditingController(),
      _code = TextEditingController(),
      _password = TextEditingController(),
      _repeat = TextEditingController();
  late int _stage;
  bool _obscure = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _stage = widget.initialStage;
    if (widget.preview && widget.showError) {
      _error = _stage == 1
          ? 'El código ingresado no es válido. Verifica e inténtalo nuevamente.'
          : 'Las contraseñas no coinciden.';
      if (_stage == 1) _code.text = '186742';
    }
  }

  @override
  void dispose() {
    _user.dispose();
    _code.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  void _next() {
    if (!_form.currentState!.validate()) return;
    if (!widget.preview) {
      setState(
        () => _error = 'La recuperación automática no está habilitada. Contacta al administrador del centro para restablecer el acceso.',
      );
      return;
    }
    if (_stage == 1 && _code.text != '123456') {
      setState(() => _error = 'El código de ejemplo no es válido. Usa 123456.');
      return;
    }
    setState(() {
      _stage++;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) => SectionShell(
    title: _stage == 0
        ? 'Recuperar acceso'
        : _stage == 1
        ? 'Verificación de seguridad'
        : _stage == 2
        ? 'Nueva contraseña'
        : 'Contraseña actualizada',
    preview: widget.preview,
    child: Form(
      key: _form,
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
              ][_stage.clamp(0, 3)],
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
            _stage == 0
                ? 'Ingresa el correo o nombre de usuario asociado a tu cuenta de REVELA.'
                : _stage == 1
                ? 'Introduce el código de seis dígitos.'
                : _stage == 2
                ? 'Crea una nueva contraseña y confírmala.'
                : 'El flujo de ejemplo terminó. No se modificó ninguna cuenta real.',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 32),
          if (_stage == 0)
            TextFormField(
              controller: _user,
              decoration: const InputDecoration(
                labelText: 'Correo o usuario',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Ingresa tu correo o usuario.'
                  : null,
            ),
          if (_stage == 1) ...[
            TextFormField(
              controller: _code,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Código de verificación',
              ),
              validator: (v) => !RegExp(r'^\d{6}$').hasMatch(v ?? '')
                  ? 'Introduce seis dígitos.'
                  : null,
            ),
            if (widget.preview) infoBox('Código de ejemplo: 123456'),
            TextButton(
              onPressed: () => setState(
                () => _error = widget.preview
                    ? 'Código de ejemplo: 123456'
                    : 'El reenvío de códigos no está habilitado.',
              ),
              child: const Text('Reenviar código'),
            ),
          ],
          if (_stage == 2) ...[
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña',
                suffixIcon: IconButton(
                  tooltip: 'Mostrar u ocultar contraseña',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
              validator: (v) =>
                  (v ?? '').length < 8 ? 'Usa al menos ocho caracteres.' : null,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _repeat,
              obscureText: _obscure,
              decoration: const InputDecoration(
                labelText: 'Confirmar contraseña',
              ),
              validator: (v) =>
                  v != _password.text ? 'Las contraseñas no coinciden.' : null,
            ),
          ],
          if (_error != null)
            Semantics(liveRegion: true, child: infoBox(_error!)),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _stage < 3 ? _next : () => Navigator.pop(context),
            child: Text(
              [
                'Enviar código de verificación',
                'Validar y continuar',
                'Actualizar contraseña',
                'Volver al inicio',
              ][_stage.clamp(0, 3)],
            ),
          ),
          const SizedBox(height: 24),
          infoBox(
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

class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.child});
  final Widget child;
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _ready = false;
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) => _ready
      ? widget.child
      : MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Image.asset(
                'assets/images/revela_logo.png',
                width: 240,
                height: 158,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
}
