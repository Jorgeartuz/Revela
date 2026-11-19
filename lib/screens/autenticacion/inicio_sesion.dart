import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/services/remote/servicio_autenticacion.dart';
import 'package:revela/models/login/sesion_usuario.dart';
import 'package:revela/routes/rutas_aplicacion.dart';
import 'package:revela/widgets/botones/boton_principal.dart';
import 'package:revela/widgets/campos/campo_texto.dart';
import 'package:revela/widgets/campos/campo_contrasena.dart';

class PantallaInicioSesion extends StatefulWidget {
  const PantallaInicioSesion({
    super.key,
    required this.servicio,
    required this.alIniciarSesion,
    this.notice,
  });
  final ServicioAutenticacion servicio;
  final ValueChanged<SesionUsuario> alIniciarSesion;
  final String? notice;

  @override
  State<PantallaInicioSesion> createState() => _EstadoPantallaInicioSesion();
}

class _EstadoPantallaInicioSesion extends State<PantallaInicioSesion> {
  final _claveFormulario = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _usuario.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (_cargando || !_claveFormulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final sesion = await widget.servicio.iniciarSesion(
        usuario: _usuario.text,
        contrasena: _contrasena.text,
      );
      if (!mounted) return;
      _contrasena.clear();
      widget.alIniciarSesion(sesion);
    } on ErrorAutenticacion catch (error) {
      if (mounted) setState(() => _error = error.mensaje);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Ocurrió un error al iniciar sesión. Vuelve a intentar.',
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _abrirRecuperacion() {
    Navigator.push<void>(context, RutasAplicacion.recuperacion());
  }

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
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: ColoresAplicacion.fondo,
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
                      key: _claveFormulario,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Image.asset(
                              'recursos/imagenes/revela_logo.png',
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
                              color: ColoresAplicacion.texto,
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
                          CampoTexto(
                            claveCampo: const Key('username'),
                            controlador: _usuario,
                            habilitado: !_cargando,
                            autocompletar: const [AutofillHints.username],
                            pista: 'correo@correo.com',
                            icono: _icono('user', 19.5, 18.75),
                            validar: (valor) =>
                                valor == null || valor.trim().isEmpty
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
                          CampoContrasena(
                            claveCampo: const Key('password'),
                            controlador: _contrasena,
                            habilitado: !_cargando,
                            alEnviar: _iniciarSesion,
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
                                      : ColoresAplicacion.textoSecundario,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 29),
                          BotonPrincipal(
                            texto: 'Iniciar Sesion',
                            alPulsar: _iniciarSesion,
                            cargando: _cargando,
                            mensajeCarga: 'Iniciando sesión',
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: _cargando ? null : _abrirRecuperacion,
                            child: const Text(
                              'Olvidé la contraseña',
                              style: TextStyle(
                                color: ColoresAplicacion.textoSecundario,
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
