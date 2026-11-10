import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';
import '../domain/auth_session.dart';
import 'recovery_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.repository,
    required this.onSignedIn,
    this.notice,
  });
  final AuthRepository repository;
  final ValueChanged<AuthSession> onSignedIn;
  final String? notice;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await widget.repository.login(
        username: _user.text,
        password: _password.text,
      );
      if (!mounted) return;
      _password.clear();
      widget.onSignedIn(session);
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Ocurrió un error al iniciar sesión. Vuelve a intentar.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showRecovery() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => const RecoveryScreen()),
    );
  }

  Widget _icon(String name, double width, double height) => Center(
    widthFactor: 1,
    heightFactor: 1,
    child: SvgPicture.asset(
      'assets/icons/$name.svg',
      width: width,
      height: height,
    ),
  );

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: AppColors.background,
    ),
    child: Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    constraints.maxHeight > 680 ? 85 : 28,
                    24,
                    32,
                  ),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Image.asset(
                              'assets/images/revela_logo.png',
                              width: 191,
                              height: 126,
                              fit: BoxFit.cover,
                              semanticLabel: 'Revela, barbería y belleza',
                            ),
                          ),
                          const SizedBox(height: 38),
                          const Text(
                            'Ingresa ahora mismo',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'OpenSans',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 34),
                          const Text(
                            'Correo o usuario',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: const Key('username'),
                            controller: _user,
                            enabled: !_loading,
                            autofillHints: const [AutofillHints.username],
                            autocorrect: false,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: 'correo@correo.com',
                              prefixIcon: _icon('user', 19.5, 18.75),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Ingresa tu correo o usuario'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Contraseña',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: const Key('password'),
                            controller: _password,
                            enabled: !_loading,
                            obscureText: _obscure,
                            enableSuggestions: false,
                            autocorrect: false,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              hintText: '**********',
                              prefixIcon: _icon('lock', 18, 20.25),
                              suffixIcon: IconButton(
                                tooltip: _obscure
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: _obscure
                                    ? _icon('visibility', 18.333, 12.5)
                                    : const Icon(
                                        Icons.visibility_off_outlined,
                                        size: 19,
                                        color: AppColors.text,
                                      ),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Ingresa tu contraseña'
                                : null,
                          ),
                          if (_error != null || widget.notice != null) ...[
                            const SizedBox(height: 16),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                _error ?? widget.notice!,
                                key: const Key('login-error'),
                                style: TextStyle(
                                  color: _error != null
                                      ? Theme.of(context).colorScheme.error
                                      : AppColors.muted,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 29),
                          FilledButton(
                            onPressed: _loading ? null : _login,
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      semanticsLabel: 'Iniciando sesión',
                                    ),
                                  )
                                : const Text('Iniciar Sesion'),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: _loading ? null : _showRecovery,
                            child: const Text(
                              'Olvidé la contraseña',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
