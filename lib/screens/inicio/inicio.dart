import 'package:revela/models/inicio/catalogo_inicio.dart';
import 'package:revela/routes/rutas_aplicacion.dart';
import 'package:revela/models/navegacion/argumentos_gestion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:revela/config/configuracion_api.dart';
import 'package:revela/services/remote/cliente_api.dart';
import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/models/login/sesion_usuario.dart';
import 'package:revela/models/login/rol_usuario.dart';
import 'package:revela/services/remote/servicio_inicio.dart';
import 'package:revela/models/inicio/reserva.dart';
import 'package:revela/services/remote/servicio_gestion.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/screens/gestion/listado.dart';
import 'package:revela/screens/profesional/portal_profesional.dart';
import 'package:revela/widgets/menu/menu_administrativo.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({
    super.key,
    required this.sesion,
    required this.alCerrarSesion,
    required this.alVencerSesion,
    this.servicio,
    this.repositorioGestion,
  });
  final SesionUsuario sesion;
  final VoidCallback alCerrarSesion, alVencerSesion;
  final ServicioInicio? servicio;
  final ServicioGestion? repositorioGestion;
  @override
  State<PantallaInicio> createState() => _EstadoPantallaInicio();
}

class _EstadoPantallaInicio extends State<PantallaInicio> {
  ClienteApi? _clienteApiPropio;
  ClienteApi? _clienteGestionPropio;
  late final ServicioGestion _gestion;
  late final ServicioInicio _repositorio;
  Future<ResumenDiario>? _resumenDiario;
  int _pestana = 0;
  bool get _esAdministrador =>
      PoliticaRoles.resolver(widget.sesion.rol) == RolUsuario.administrador;
  bool get _esProfesional =>
      PoliticaRoles.resolver(widget.sesion.rol) == RolUsuario.profesional;

  @override
  void initState() {
    super.initState();
    _repositorio =
        widget.servicio ??
        ServicioInicio(
          _clienteApiPropio = ClienteApi(
            urlBase: Uri.parse(ConfiguracionApi.urlBase),
          ),
          widget.sesion,
          alNoEstarAutorizado: widget.alVencerSesion,
        );
    _gestion =
        widget.repositorioGestion ??
        ServicioGestion(
          api: _clienteGestionPropio = ClienteApi(
            urlBase: Uri.parse(ConfiguracionApi.urlBase),
          ),
          sesion: widget.sesion,
          alNoEstarAutorizado: widget.alVencerSesion,
        );
    _gestion.alIrAlInicio = () {
      if (mounted) setState(() => _pestana = 0);
    };
    _gestion.alCerrarSesion = _cerrarSesion;
    if (_esAdministrador) {
      _resumenDiario = _repositorio.cargarDia(DateTime.now());
    }
  }

  @override
  void dispose() {
    if (_gestion.alCerrarSesion == _cerrarSesion) {
      _gestion.alCerrarSesion = null;
    }
    _clienteApiPropio?.close();
    _clienteGestionPropio?.close();
    super.dispose();
  }

  Future<void> _actualizar() async {
    if (!mounted || !_esAdministrador) return;
    final future = _repositorio.cargarDia(DateTime.now());
    setState(() {
      _resumenDiario = future;
    });
    try {
      await future;
    } catch (_) {}
  }

  Future<void> _cerrarSesion() async {
    final confirmada = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Para volver a entrar deberás iniciar sesión con tu usuario y contraseña.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmada == true && mounted) widget.alCerrarSesion();
  }

  ModuloGestion _moduloDeCatalogo(CatalogoInicio catalogo) =>
      switch (catalogo) {
        CatalogoInicio.clientes => ModuloGestion.clientes,
        CatalogoInicio.profesionales => ModuloGestion.profesionales,
        CatalogoInicio.servicios => ModuloGestion.servicios,
        CatalogoInicio.especialidades => ModuloGestion.especialidades,
        CatalogoInicio.cierres => ModuloGestion.cierres,
      };
  Future<void> _abrirModulo(ModuloGestion modulo) async {
    await Navigator.push<void>(
      context,
      RutasAplicacion.listado(
        ArgumentosListado(modulo: modulo, servicio: _gestion),
      ),
    );
    if (mounted) await _actualizar();
  }

  void _abrirCatalogo(CatalogoInicio catalogo) =>
      _abrirModulo(_moduloDeCatalogo(catalogo));
  Future<void> _crearReserva() async {
    final changed = await Navigator.push<bool>(
      context,
      RutasAplicacion.formulario(
        ArgumentosFormulario(
          modulo: ModuloGestion.reservas,
          servicio: _gestion,
        ),
      ),
    );
    if (changed == true && mounted) await _actualizar();
  }

  Future<void> _abrirReserva(Reserva reservation) async {
    final changed = await Navigator.push<bool>(
      context,
      RutasAplicacion.detalle(
        ArgumentosDetalle(
          modulo: ModuloGestion.reservas,
          registro: reservation.origen,
          servicio: _gestion,
        ),
      ),
    );
    if (changed == true && mounted) await _actualizar();
  }

  @override
  Widget build(BuildContext context) {
    if (_esProfesional) {
      return PortalProfesional(
        servicio: _gestion,
        alCerrarSesion: _cerrarSesion,
        idProfesional: widget.sesion.idProfesional,
        usuario: widget.sesion.usuario,
      );
    }
    if (!_esAdministrador && !_esProfesional) {
      return Scaffold(
        appBar: AppBar(title: const Text('Revela')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tu cuenta no tiene un perfil habilitado en la aplicación.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Contacta al administrador para revisar tu acceso.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: widget.alCerrarSesion,
                  child: const Text('Volver al inicio de sesión'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final labels = _esAdministrador
        ? ['Inicio', 'Agenda', 'Profesionales', 'Clientes', 'Más']
        : ['Inicio', 'Agenda', 'Servicios', 'Horario', 'Más'];
    final icons = _esAdministrador
        ? [
            'nav_home',
            'nav_agenda',
            'nav_professionals',
            'nav_clients',
            'nav_more',
          ]
        : [
            'nav_home',
            'nav_agenda',
            'nav_my_services',
            'nav_schedule',
            'nav_more',
          ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _contenidoPrincipal(),
          ),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: ColoresAplicacion.superficie,
          border: Border(top: BorderSide(color: Color(0x269CA3AF))),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SizedBox(
                height: 80,
                child: Row(
                  children: List.generate(5, (i) {
                    return Expanded(
                      child: Semantics(
                        selected: _pestana == i,
                        button: true,
                        child: InkWell(
                          onTap: () => setState(() => _pestana = i),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 10),
                            child: Column(
                              children: [
                                Container(
                                  width: 54,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: _pestana == i
                                        ? const Color(0x2EC8A2B7)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(
                                      _esAdministrador &&
                                              (i == 0 ||
                                                  i == 1 ||
                                                  i == 2 ||
                                                  i == 4)
                                          ? 0
                                          : 99,
                                    ),
                                  ),
                                  child: Center(
                                    child: _recurso(
                                      icons[i],
                                      22,
                                      color: _pestana == i
                                          ? ColoresAplicacion.principal
                                          : ColoresAplicacion.textoSecundario,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Flexible(
                                  child: FittedBox(
                                    child: Text(
                                      labels[i],
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: _pestana == i
                                            ? ColoresAplicacion.principal
                                            : ColoresAplicacion.textoSecundario,
                                        fontWeight: _pestana == i
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenidoPrincipal() {
    if (_pestana == 4) return _menu();
    if (_pestana == 1) {
      return PantallaListado(
        modulo: ModuloGestion.reservas,
        servicio: _gestion,
        integrado: true,
      );
    }
    if (_pestana == 2 || _pestana == 3) {
      final catalogo = _pestana == 2
          ? CatalogoInicio.profesionales
          : CatalogoInicio.clientes;
      return Column(
        children: [
          Expanded(
            child: PantallaListado(
              key: ValueKey(catalogo),
              modulo: _moduloDeCatalogo(catalogo),
              servicio: _gestion,
              integrado: true,
            ),
          ),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: _actualizar,
      child: FutureBuilder<ResumenDiario>(
        future: _resumenDiario,
        builder: (context, snapshot) {
          final day = snapshot.data;
          return ListView(
            padding: const EdgeInsets.fromLTRB(21, 22, 21, 32),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (_pestana == 0) ...[
                _encabezado(),
                const SizedBox(height: 28),
                _indicadores(day),
                const SizedBox(height: 28),
                _accesosRapidos(day),
                const SizedBox(height: 28),
              ],
              ...[
                Row(
                  children: [
                    Expanded(
                      child: Text('Reservas de hoy', style: _estiloSeccion),
                    ),
                    if (_pestana == 0)
                      TextButton(
                        onPressed: () => setState(() => _pestana = 1),
                        child: const Text(
                          'Ver todas',
                          style: TextStyle(
                            fontSize: 12,
                            color: ColoresAplicacion.textoAyuda,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (snapshot.hasError)
                  _VistaError(
                    message: _textoError(snapshot.error),
                    onRetry: _actualizar,
                  )
                else if (day == null || day.reservas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No hay reservas para hoy.',
                      style: TextStyle(
                        color: ColoresAplicacion.textoSecundario,
                      ),
                    ),
                  )
                else
                  ...day.reservas
                      .take(3)
                      .map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _TarjetaReserva(
                            reservation: r,
                            onOpen: () => _abrirReserva(r),
                          ),
                        ),
                      ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _encabezado() {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Buenos días'
        : now.hour < 18
        ? 'Buenas tardes'
        : 'Buenas noches';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat(
                  'EEEE, d \'DE\' MMMM',
                  'es',
                ).format(now).toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: ColoresAplicacion.textoSecundario,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$greeting, ${_esAdministrador ? 'ADMIN' : widget.sesion.usuario ?? 'Profesional'}',
                style: const TextStyle(
                  fontFamily: 'OpenSans',
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          tooltip: 'Cerrar sesión',
          onPressed: _cerrarSesion,
          padding: EdgeInsets.zero,
          icon: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              children: [
                _recurso('avatar_circle', 40),
                Positioned(
                  left: 12.88,
                  top: 12.88,
                  child: Image.asset(
                    'recursos/iconos/avatar_mark.png',
                    width: 16.949,
                    height: 16.949,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _indicadores(ResumenDiario? day) {
    final states = EstadosReserva.configurados;
    final now = DateTime.now();
    final next = day?.next(states, now);
    String count(int? value) => value?.toString() ?? '—';
    final values = [
      count(day?.reservas.length),
      count(day?.pendientes(states)),
      next == null ? '—' : '${next.inicio.difference(now).inMinutes} min',
      _esAdministrador ? count(day?.enCurso(states, now)) : '—',
    ];
    final titles = [
      _esAdministrador ? 'Reservas hoy' : 'Citas hoy',
      'Pendientes',
      _esAdministrador ? 'Próximo turno' : 'Próxima cita',
      _esAdministrador ? 'En turno' : 'Atendidas hoy',
    ];
    final icons = [
      'stat_calendar',
      'stat_people',
      'stat_clock',
      'stat_scissors',
    ];
    Widget item(int index) => Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 18, 8, 16),
        decoration: BoxDecoration(
          color: ColoresAplicacion.superficie,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _recurso(icons[index], 24),
            const SizedBox(height: 8),
            Text(
              values[index],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              titles[index],
              style: const TextStyle(
                fontSize: 11,
                color: ColoresAplicacion.textoSecundario,
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      children: [
        Row(children: [item(0), const SizedBox(width: 12), item(1)]),
        const SizedBox(height: 12),
        Row(children: [item(2), const SizedBox(width: 12), item(3)]),
      ],
    );
  }

  Widget _accesosRapidos(ResumenDiario? day) {
    final labels = _esAdministrador
        ? ['Especialidades', 'Servicios', 'Cierres']
        : ['Mis servicios', 'Horario', 'Inasistencias'];
    final icons = _esAdministrador
        ? ['specialties', 'services', 'closures']
        : [
            'professional_services',
            'professional_schedule',
            'professional_absences',
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Accesos rápidos', style: _estiloSeccion),
        const SizedBox(height: 14),
        Material(
          color: ColoresAplicacion.principal,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _esAdministrador
                ? _crearReserva
                : () => setState(() => _pestana = 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _esAdministrador ? 'Nueva Cita' : 'Mi agenda',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ColoresAplicacion.fondo,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _esAdministrador
                              ? 'Crear una reserva para un cliente'
                              : 'Consulta tus citas del día',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF33262E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _recurso(
                    _esAdministrador ? 'action_add' : 'professional_agenda',
                    _esAdministrador ? 30 : 26,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(
            3,
            (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                child: Material(
                  color: ColoresAplicacion.textoAyuda,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _esAdministrador
                        ? _abrirCatalogo(
                            [
                              CatalogoInicio.especialidades,
                              CatalogoInicio.servicios,
                              CatalogoInicio.cierres,
                            ][i],
                          )
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(3, 16, 3, 14),
                      child: Column(
                        children: [
                          _recurso(icons[i], 22),
                          const SizedBox(height: 8),
                          Text(
                            labels[i],
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: i == 0 ? 10 : 11,
                              color: ColoresAplicacion.texto,
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
      ],
    );
  }

  Widget _menu() => MenuAdministrativo(
    alAbrirModulo: _abrirModulo,
    alCerrarSesion: _cerrarSesion,
  );
}

const _estiloSeccion = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

Widget _recurso(String name, double size, {Color? color}) => SvgPicture.asset(
  'recursos/iconos/$name.svg',
  width: size,
  height: size,
  colorFilter: color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
);
String _textoError(Object? error) => error is ErrorInicio
    ? error.message
    : 'No se pudo cargar la información. Vuelve a intentar.';

class _VistaError extends StatelessWidget {
  const _VistaError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: ColoresAplicacion.textoSecundario),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );
}

class _TarjetaReserva extends StatelessWidget {
  const _TarjetaReserva({required this.reservation, required this.onOpen});
  final VoidCallback onOpen;
  final Reserva reservation;
  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final label = EstadosReserva.configurados.label(r.estado);
    final pink = label == 'CONFIRMADA';
    return Material(
      color: ColoresAplicacion.superficie,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: pink
                    ? ColoresAplicacion.principal
                    : ColoresAplicacion.textoAyuda,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: ColoresAplicacion.fondo,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  DateFormat('hh:mm').format(r.inicio),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  DateFormat('a').format(r.inicio),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: ColoresAplicacion.textoSecundario,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.cliente,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  r.profesional,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: ColoresAplicacion.textoSecundario,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (label != null)
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: pink
                                      ? ColoresAplicacion.principal
                                      : ColoresAplicacion.fondo,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: pink
                                        ? ColoresAplicacion.fondo
                                        : ColoresAplicacion.textoSecundario,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            r.servicio,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '•  ${r.duracionMinutos} min · ${NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(r.precio)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: ColoresAplicacion.textoSecundario,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
