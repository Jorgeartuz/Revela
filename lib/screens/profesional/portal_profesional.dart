import 'package:revela/routes/rutas_aplicacion.dart';
import 'package:revela/models/navegacion/argumentos_gestion.dart';
import 'package:revela/models/profesional/datos_profesional.dart';

import 'package:revela/screens/profesional/servicios_profesional.dart';
import 'package:revela/widgets/gestion/componentes_operativos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/services/remote/servicio_gestion.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/models/gestion/valores_registro.dart';
import 'package:revela/screens/gestion/listado.dart';
import 'package:revela/widgets/gestion/componentes_compartidos.dart';

class PortalProfesional extends StatefulWidget {
  const PortalProfesional({
    super.key,
    required this.servicio,
    required this.alCerrarSesion,
    this.idProfesional,
    this.usuario,
    this.pestanaInicial = 0,
  });
  final ServicioGestion servicio;
  final VoidCallback alCerrarSesion;
  final int? idProfesional;
  final String? usuario;
  final int pestanaInicial;
  @override
  State<PortalProfesional> createState() => _EstadoPortalProfesional();
}

class _EstadoPortalProfesional extends State<PortalProfesional> {
  int _pestana = 0;
  Future<DatosProfesional>? _datosInicio;

  @override
  void initState() {
    super.initState();
    _pestana = widget.pestanaInicial;
    widget.servicio.alCambiarPestanaProfesional = _cambiarPestana;
    if (widget.idProfesional != null) {
      _datosInicio = _cargarInicio();
    }
  }

  Future<DatosProfesional> _cargarInicio() async {
    final perfil = await widget.servicio.obtenerProfesional(
      widget.idProfesional!,
    );
    final reservas = await widget.servicio.listar(
      ModuloGestion.reservas,
      filtros: {'profesionalId': '${widget.idProfesional}'},
    );
    return DatosProfesional(perfil: perfil, reservas: reservas);
  }

  Future<void> _actualizarInicio() async {
    if (!mounted || widget.idProfesional == null) return;
    final consulta = _cargarInicio();
    setState(() {
      _datosInicio = consulta;
    });
    try {
      await consulta;
    } catch (_) {}
  }

  void _cambiarPestana(int pestana) {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    Navigator.popUntil(context, (r) => r == route);
    setState(() {
      _pestana = pestana;
      if (pestana == 0 && widget.idProfesional != null) {
        _datosInicio = _cargarInicio();
      }
    });
  }

  @override
  void dispose() {
    if (widget.servicio.alCambiarPestanaProfesional == _cambiarPestana) {
      widget.servicio.alCambiarPestanaProfesional = null;
    }
    super.dispose();
  }

  Widget _icono(String name, double size, {Color? color}) => SvgPicture.asset(
    'recursos/iconos/$name.svg',
    width: size,
    height: size,
    colorFilter: color == null
        ? null
        : ColorFilter.mode(color, BlendMode.srcIn),
  );
  void _abrir(ModuloGestion modulo) => Navigator.push<void>(
    context,
    RutasAplicacion.listado(
      ArgumentosListado(
        modulo: modulo,
        servicio: widget.servicio,
        idProfesional: widget.idProfesional,
        soloLectura: true,
      ),
    ),
  );
  Future<void> _cerrarSesion() async {
    if (await confirmarAccion(
          context,
          title: '¿Cerrar sesión?',
          description: 'Para volver a entrar deberás iniciar sesión con tu usuario y contraseña.',
          action: 'Cerrar sesión',
        ) &&
        mounted) {
      widget.alCerrarSesion();
    }
  }

  Widget _indicador(String icon, String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 16),
      decoration: BoxDecoration(
        color: ColoresAplicacion.superficie,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _icono(icon, 24),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: ColoresAplicacion.textoSecundario,
            ),
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: _pestana == 0
        ? null
        : AppBar(
            title: Text(
              [
                'Inicio',
                'Mi agenda',
                'Mis servicios',
                'Mi horario',
                'Más',
              ][_pestana],
            ),
            actions: [
              IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: _cerrarSesion,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _contenidoPrincipal(),
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: ColoredBox(
      color: ColoresAplicacion.superficie,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Row(
            children: List.generate(
              5,
              (i) => Expanded(
                child: InkWell(
                  onTap: () => _cambiarPestana(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 54,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _pestana == i
                              ? const Color(0x2EC8A2B7)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: _icono(
                          [
                            'nav_home',
                            'nav_agenda',
                            'nav_my_services',
                            'nav_schedule',
                            'nav_more',
                          ][i],
                          22,
                          color: _pestana == i
                              ? ColoresAplicacion.principal
                              : ColoresAplicacion.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ['Inicio', 'Agenda', 'Servicios', 'Horario', 'Más'][i],
                        style: TextStyle(
                          fontSize: 10.5,
                          color: _pestana == i
                              ? ColoresAplicacion.principal
                              : ColoresAplicacion.textoSecundario,
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
  );
  Widget _contenidoPrincipal() {
    if (widget.idProfesional == null) {
      return ListView(
        padding: const EdgeInsets.all(21),
        children: [
          tituloSeccion('MI PERFIL'),
          Text(
            widget.usuario ?? 'Profesional',
            style: const TextStyle(fontSize: 22),
          ),
          cuadroInformacion(
            'Tu perfil necesita completar la vinculación con el centro para consultar citas, servicios y horarios. Contacta al administrador.',
          ),
          TextButton(
            onPressed: _cerrarSesion,
            child: const Text('Cerrar sesión'),
          ),
        ],
      );
    }
    if (_pestana == 4) {
      return ListView(
        padding: const EdgeInsets.all(21),
        children: [
          Text(
            'Tu espacio en REVELA · ${widget.usuario ?? 'Profesional'}',
            style: const TextStyle(
              color: ColoresAplicacion.textoSecundario,
              fontSize: 12,
            ),
          ),
          tituloSeccion('MI TRABAJO'),
          ListTile(
            leading: _icono('professional_services', 22),
            title: const Text('Mis servicios'),
            subtitle: const Text('Servicios y comisiones del período'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => setState(() => _pestana = 2),
          ),
          ListTile(
            leading: _icono('professional_schedule', 22),
            subtitle: const Text('Días y horas de trabajo de la semana'),
            title: const Text('Mi horario'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => setState(() => _pestana = 3),
          ),
          ListTile(
            leading: _icono('professional_absences', 22),
            subtitle: const Text('Días no disponibles registrados'),
            title: const Text('Mis inasistencias'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _abrir(ModuloGestion.inasistencias),
          ),
          tituloSeccion('CUENTA'),
          ListTile(
            title: const Text('Cerrar sesión'),
            leading: const Icon(Icons.logout),
            onTap: _cerrarSesion,
          ),
        ],
      );
    }
    if (_pestana == 2) {
      return ServiciosProfesional(
        servicio: widget.servicio,
        idProfesional: widget.idProfesional!,
      );
    }
    if (_pestana > 0) {
      return PantallaListado(
        key: ValueKey(_pestana),
        modulo: [
          ModuloGestion.reservas,
          ModuloGestion.reservas,
          ModuloGestion.comisiones,
          ModuloGestion.horarios,
        ][_pestana],
        servicio: widget.servicio,
        idProfesional: widget.idProfesional,
        soloLectura: true,
        integrado: true,
      );
    }
    return RefreshIndicator(
      onRefresh: _actualizarInicio,
      child: FutureBuilder<DatosProfesional>(
        future: _datosInicio,
        builder: (context, resultado) {
          final now = DateTime.now();
          final registros = (resultado.data?.reservas ?? []).where((r) {
            final d = DateTime.tryParse(r['fecha']?.toString() ?? '');
            return d != null &&
                d.year == now.year &&
                d.month == now.month &&
                d.day == now.day;
          }).toList();
          final states = widget.servicio.estadosReserva;
          String cantidad(int? code) => !resultado.hasData || code == null
              ? '—'
              : '${registros.where((r) => r['estado'] == code).length}';
          final perfil = resultado.data?.perfil;
          final proximasCitas =
              registros.where((r) {
                final start = inicioReserva(r);
                return start != null &&
                    start.isAfter(now) &&
                    ((states.programada != null &&
                            r['estado'] == states.programada) ||
                        (states.confirmada != null &&
                            r['estado'] == states.confirmada));
              }).toList()..sort(
                (a, b) => inicioReserva(a)!.compareTo(inicioReserva(b)!),
              );
          return ListView(
            padding: const EdgeInsets.fromLTRB(21, 22, 21, 32),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat(
                            'EEEE, d MMMM',
                            'es',
                          ).format(now).toUpperCase(),
                          style: const TextStyle(
                            color: ColoresAplicacion.textoSecundario,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${now.hour < 12
                              ? 'Buenos días'
                              : now.hour < 18
                              ? 'Buenas tardes'
                              : 'Buenas noches'}, ${widget.usuario ?? 'Profesional'}',
                          style: const TextStyle(
                            fontFamily: 'OpenSans',
                            fontWeight: FontWeight.w600,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar sesión',
                    onPressed: _cerrarSesion,
                    icon: SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        children: [
                          _icono('avatar_circle', 40),
                          Positioned(
                            left: 12.88,
                            top: 12.88,
                            child: Image.asset(
                              'recursos/iconos/avatar_mark.png',
                              width: 16.949,
                              height: 16.949,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ColoresAplicacion.superficie,
                  border: Border.all(color: ColoresAplicacion.borde),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: ColoresAplicacion.principal,
                      foregroundColor: ColoresAplicacion.fondo,
                      child: Text(
                        iniciales(
                          perfil == null
                              ? widget.usuario ?? 'Profesional'
                              : nombreRegistro(perfil),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            perfil == null
                                ? widget.usuario ?? 'Profesional'
                                : nombreRegistro(perfil),
                          ),
                          if (perfil != null)
                            Text(
                              '${datosAnidados(perfil, 'especialidad')['nombre'] ?? 'Especialidad sin informar'} · Comisión ${perfil['porcentaje'] ?? '—'}%',
                              style: const TextStyle(
                                fontSize: 11,
                                color: ColoresAplicacion.textoSecundario,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  _indicador(
                    'stat_calendar',
                    resultado.hasData ? '${registros.length}' : '—',
                    'Citas hoy',
                  ),
                  const SizedBox(width: 12),
                  _indicador(
                    'stat_people',
                    cantidad(states.programada),
                    'Pendientes',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _indicador(
                    'stat_clock',
                    proximasCitas.isEmpty
                        ? '—'
                        : textoHora(proximasCitas.first['horaInicio']),
                    'Próxima cita',
                  ),
                  const SizedBox(width: 12),
                  _indicador(
                    'stat_scissors',
                    cantidad(states.atendida),
                    'Atendidas hoy',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              tituloSeccion('ACCESOS RÁPIDOS'),
              FilledButton(
                onPressed: () => setState(() => _pestana = 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Mi agenda',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      _icono('professional_agenda', 26),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final i in [0, 1, 2])
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                        child: Material(
                          color: ColoresAplicacion.textoAyuda,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () => i == 2
                                ? _abrir(ModuloGestion.inasistencias)
                                : setState(() => _pestana = i == 0 ? 2 : 3),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  _icono(
                                    [
                                      'professional_services',
                                      'professional_schedule',
                                      'professional_absences',
                                    ][i],
                                    22,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    [
                                      'Mis servicios',
                                      'Horario',
                                      'Inasistencias',
                                    ][i],
                                    style: const TextStyle(fontSize: 10.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Próximas citas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _pestana = 1),
                    child: const Text('Ver todas'),
                  ),
                ],
              ),
              if (resultado.hasError) ...[
                cuadroInformacion(mensajeError(resultado.error)),
                TextButton(
                  onPressed: _actualizarInicio,
                  child: const Text('Reintentar'),
                ),
              ] else if (!resultado.hasData)
                const Center(child: CircularProgressIndicator())
              else if (proximasCitas.isEmpty)
                cuadroInformacion('No hay próximas citas para mostrar hoy.')
              else
                ...proximasCitas
                    .take(3)
                    .map(
                      (r) => RecordCard(
                        modulo: ModuloGestion.reservas,
                        registro: r,

                        onTap: () => Navigator.push<void>(
                          context,
                          RutasAplicacion.detalle(
                            ArgumentosDetalle(
                              modulo: ModuloGestion.reservas,
                              registro: r,
                              servicio: widget.servicio,
                              soloLectura: true,
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}
