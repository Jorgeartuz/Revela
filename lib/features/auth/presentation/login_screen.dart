import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showPending({required bool recovery}) {
    if (!recovery && !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recovery ? 'Recuperar acceso' : 'Conexión pendiente'),
        content: Text(
          recovery
              ? 'La recuperación de contraseña estará disponible cuando se conecte el servicio de la API.'
              : 'La interfaz está lista. Falta configurar los endpoints de autenticación de la API para verificar tus credenciales.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
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
                            obscureText: _obscure,
                            enableSuggestions: false,
                            autocorrect: false,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) =>
                                _showPending(recovery: false),
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
                          const SizedBox(height: 29),
                          FilledButton(
                            onPressed: () => _showPending(recovery: false),
                            child: const Text('Iniciar Sesion'),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => _showPending(recovery: true),
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
