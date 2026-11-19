import 'package:revela/routes/rutas_aplicacion.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:revela/config/configuracion_api.dart';
import 'package:revela/services/remote/cliente_api.dart';
import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/services/remote/servicio_autenticacion.dart';
import 'package:revela/models/login/sesion_usuario.dart';
import 'package:revela/screens/autenticacion/inicio_sesion.dart';
import 'package:revela/screens/inicio/inicio.dart';
import 'package:revela/services/remote/servicio_inicio.dart';

class AplicacionRevela extends StatefulWidget {
  const AplicacionRevela({
    super.key,
    this.servicioAutenticacion,
    this.crearServicioInicio,
  });
  final ServicioAutenticacion? servicioAutenticacion;
  final ServicioInicio Function(SesionUsuario)? crearServicioInicio;
  @override
  State<AplicacionRevela> createState() => _EstadoAplicacionRevela();
}

class _EstadoAplicacionRevela extends State<AplicacionRevela>
    with WidgetsBindingObserver {
  ClienteApi? _clienteApiPropio;
  late final ServicioAutenticacion _autenticacion;
  SesionUsuario? _sesion;
  Timer? _temporizadorSesion;
  final _claveNavegacion = GlobalKey<NavigatorState>();
  String? _avisoAcceso;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _autenticacion =
        widget.servicioAutenticacion ??
        ServicioAutenticacion(
          _clienteApiPropio = ClienteApi(
            urlBase: Uri.parse(ConfiguracionApi.urlBase),
          ),
        );
  }

  void _sesionIniciada(SesionUsuario sesion) {
    if (!mounted) return;
    _temporizadorSesion?.cancel();
    if (sesion.estaVencida) {
      _cerrarSesion(expired: true);
      return;
    }
    setState(() {
      _sesion = sesion;
      _avisoAcceso = null;
    });
    _temporizadorSesion = Timer(
      sesion.fechaVencimiento.difference(DateTime.now()),
      () => _cerrarSesion(expired: true),
    );
  }

  void _cerrarSesion({bool expired = false}) {
    if (!mounted) return;
    _temporizadorSesion?.cancel();
    _claveNavegacion.currentState?.popUntil((route) => route.isFirst);
    setState(() {
      _sesion = null;
      _avisoAcceso = expired
          ? 'Tu sesión ha vencido. Inicia sesión nuevamente.'
          : null;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed &&
        (_sesion?.estaVencida ?? false)) {
      _cerrarSesion(expired: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _temporizadorSesion?.cancel();
    _clienteApiPropio?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Revela',
    onGenerateRoute: RutasAplicacion.generarRuta,
    navigatorKey: _claveNavegacion,
    debugShowCheckedModeBanner: false,
    theme: TemaAplicacion.oscuro,
    scrollBehavior: const DesplazamientoRevela(),
    locale: const Locale('es'),
    supportedLocales: const [Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: _sesion == null
        ? PantallaInicioSesion(
            servicio: _autenticacion,
            alIniciarSesion: _sesionIniciada,
            notice: _avisoAcceso,
          )
        : PantallaInicio(
            sesion: _sesion!,
            servicio: widget.crearServicioInicio?.call(_sesion!),
            alCerrarSesion: _cerrarSesion,
            alVencerSesion: () => _cerrarSesion(expired: true),
          ),
  );
}
