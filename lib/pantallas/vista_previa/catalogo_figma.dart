import 'package:revela/pantallas/gestion/pantalla_operacion_exitosa.dart';
import 'package:revela/pantallas/gestion/pantalla_revision_datos.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:revela/servicios/remoto/cliente_api.dart';
import 'package:revela/servicios/remoto/servicio_autenticacion.dart';
import 'package:revela/modelos/login/sesion_usuario.dart';
import 'package:revela/pantallas/autenticacion/pantalla_inicio_sesion.dart';
import 'package:revela/pantallas/autenticacion/pantalla_recuperacion.dart';
import 'package:revela/servicios/remoto/servicio_inicio.dart';
import 'package:revela/pantallas/inicio/pantalla_inicio.dart';
import 'package:revela/servicios/remoto/servicio_gestion.dart';
import 'package:revela/modelos/gestion/modulo_gestion.dart';
import 'package:revela/modelos/gestion/campos_formulario.dart';
import 'package:revela/pantallas/gestion/pantalla_listado.dart';
import 'package:revela/pantallas/gestion/pantalla_formulario.dart';
import 'package:revela/pantallas/gestion/pantalla_detalle.dart';
import 'package:revela/componentes/gestion/componentes_compartidos.dart';
import 'package:revela/pantallas/profesional/portal_profesional.dart';

class PantallaFigma {
  const PantallaFigma(this.id, this.name);
  final String id, name;
}

const pantallasFigma = <PantallaFigma>[
  PantallaFigma("179:40", "Agenda"),
  PantallaFigma("77:148", "Splash"),
  PantallaFigma("7:9", "Inicio Sesión"),
  PantallaFigma("99:375", "Error de Acceso"),
  PantallaFigma("77:110", "Recuperación"),
  PantallaFigma("142:835", "Confirmación"),
  PantallaFigma("144:945", "Home"),
  PantallaFigma("179:198", "Cierres - Listado"),
  PantallaFigma("179:240", "Servicios"),
  PantallaFigma("179:277", "Especialidades"),
  PantallaFigma("179:314", "Clientes"),
  PantallaFigma("201:40", "Detalle de Reserva"),
  PantallaFigma("201:133", "Confirmación de Reserva"),
  PantallaFigma("201:226", "Reagendar Reserva"),
  PantallaFigma("201:472", "Dialogo - Cancelar Reserva"),
  PantallaFigma("201:623", "Dialogo - Confirmar Asistencia"),
  PantallaFigma("204:40", "Especialidades - Listado"),
  PantallaFigma("204:133", "Especialidad - Formulario"),
  PantallaFigma("204:226", "Especialidades - Sin resultados"),
  PantallaFigma("239:465", "Profesionales"),
  PantallaFigma("239:745", "Clientes"),
  PantallaFigma("239:951", "Crear Clientes"),
  PantallaFigma("239:1131", "Crear reserva"),
  PantallaFigma("239:1256", "Confirmacion Reserva"),
  PantallaFigma("262:24", "Home (Rediseño)"),
  PantallaFigma("276:24", "Reserva - Detalle (Modal: Confirmar Cancelación)"),
  PantallaFigma("277:24", "Reserva - Detalle"),
  PantallaFigma("288:24", "Comisiones - Detalle"),
  PantallaFigma("288:84", "Horario - Vista semanal"),
  PantallaFigma("294:24", "Crear Cliente (Error de Validación)"),
  PantallaFigma("294:103", "Estado de Carga - Home"),
  PantallaFigma("352:24", "Crear reserva (Error de Validación)"),
  PantallaFigma("359:61", "Detalle de Reserva (Cancelada)"),
  PantallaFigma("359:186", "Detalle de Reserva (Atendida)"),
  PantallaFigma("362:24", "Servicios - Listado"),
  PantallaFigma("362:88", "Servicios - Sin resultados"),
  PantallaFigma("362:152", "Crear Servicio"),
  PantallaFigma("362:216", "Crear Servicio (Error: obligatorios y rangos)"),
  PantallaFigma("362:280", "Crear Servicio (Error: formato)"),
  PantallaFigma("362:344", "Servicio Creado"),
  PantallaFigma("362:408", "Editar Servicio"),
  PantallaFigma("362:472", "Dialogo - Desactivar Servicio"),
  PantallaFigma("369:24", "Crear Profesional"),
  PantallaFigma("369:142", "Crear Profesional (Error: obligatorios)"),
  PantallaFigma("369:260", "Crear Profesional (Error: reglas)"),
  PantallaFigma("369:378", "Profesional Creado"),
  PantallaFigma("369:496", "Editar Profesional"),
  PantallaFigma("369:614", "Dialogo - Desactivar Profesional"),
  PantallaFigma("373:24", "Configurar horario"),
  PantallaFigma("373:248", "Configurar horario - Con almuerzo"),
  PantallaFigma("373:399", "Configurar horario - Error"),
  PantallaFigma("373:561", "Horario guardado"),
  PantallaFigma("376:24", "Registrar Inasistencia"),
  PantallaFigma("376:254", "Registrar Inasistencia - Rango"),
  PantallaFigma("376:398", "Registrar Inasistencia - Error (obligatorios)"),
  PantallaFigma("376:570", "Registrar Inasistencia - Error (rango)"),
  PantallaFigma("376:725", "Inasistencias - Listado"),
  PantallaFigma("376:934", "Inasistencia registrada"),
  PantallaFigma("377:59", "Crear Cierre"),
  PantallaFigma("377:177", "Crear Cierre - Resumen"),
  PantallaFigma("377:295", "Crear Cierre - Error"),
  PantallaFigma("377:413", "Cierre creado"),
  PantallaFigma("377:531", "Detalle de Cierre"),
  PantallaFigma("377:649", "Comisiones - Consolidado"),
  PantallaFigma("377:767", "Comisiones - Sin resultados"),
  PantallaFigma("382:102", "Crear Cliente - Error: formato"),
  PantallaFigma("382:235", "Editar Cliente"),
  PantallaFigma("382:350", "Detalle de Cliente"),
  PantallaFigma("382:502", "Clientes - Sin resultados"),
  PantallaFigma("382:682", "Cliente Creado"),
  PantallaFigma("383:129", "Especialidad Creada"),
  PantallaFigma("386:24", "Especialidad - Formulario (Error)"),
  PantallaFigma("390:24", "Código OTP - Inválido"),
  PantallaFigma("390:95", "Nueva contraseña"),
  PantallaFigma("390:143", "Nueva contraseña - Error"),
  PantallaFigma("390:193", "Contraseña actualizada"),
  PantallaFigma("404:33", "Más"),
  PantallaFigma("428:36", "Dialogo - Cerrar Sesión (Inicio)"),
  PantallaFigma("428:235", "Dialogo - Cerrar Sesión (Más)"),
  PantallaFigma("479:34", "Profesional — Home"),
  PantallaFigma("479:221", "Profesional — Agenda"),
  PantallaFigma("479:347", "Profesional — Agenda Vacía"),
  PantallaFigma("479:452", "Profesional — Detalle Reserva"),
  PantallaFigma("479:571", "Profesional — Detalle Reserva (Programada)"),
  PantallaFigma("479:690", "Profesional — Detalle Reserva (Cancelada)"),
  PantallaFigma("479:807", "Profesional — Detalle Reserva (Atendida)"),
  PantallaFigma("237:26", "Profesional — Mis Servicios"),
  PantallaFigma("479:926", "Profesional — Horario"),
  PantallaFigma("479:1081", "Profesional — Inasistencias"),
  PantallaFigma("479:1211", "Profesional — Inasistencias Vacío"),
  PantallaFigma("479:1341", "Profesional — Menú"),
  PantallaFigma("490:65", "Profesional — Cerrar Sesión"),
];

/// Relaciona cada marco del diseño con la pantalla de ejemplo que le corresponde.
class CatalogoFigma extends StatefulWidget {
  const CatalogoFigma({super.key});
  @override
  State<CatalogoFigma> createState() => _EstadoCatalogoFigma();
}

class _EstadoCatalogoFigma extends State<CatalogoFigma> {
  String _controladorBusqueda = '';
  @override
  Widget build(BuildContext context) => SectionShell(
    title: '92 marcos de Figma',
    vistaPrevia: true,
    child: ListView(
      padding: const EdgeInsets.all(21),
      children: [
        cuadroInformacion(
          'Inventario del archivo Proyecto_Revela. Incluye pantallas, estados, diálogos y versiones anteriores. Cada entrada abre su flujo equivalente con datos de ejemplo.',
        ),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Buscar pantalla de Figma',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _controladorBusqueda = v),
        ),
        for (final frame in pantallasFigma.where(
          (f) =>
              f.name.toLowerCase().contains(_controladorBusqueda.toLowerCase()),
        ))
          ListTile(
            title: Text(frame.name),
            subtitle: Text('Figma ${frame.id}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => VistaPreviaFigma(frame: frame)),
            ),
          ),
      ],
    ),
  );
}

class VistaPreviaFigma extends StatefulWidget {
  const VistaPreviaFigma({super.key, required this.frame});
  final PantallaFigma frame;
  @override
  State<VistaPreviaFigma> createState() => _EstadoVistaPreviaFigma();
}

class _EstadoVistaPreviaFigma extends State<VistaPreviaFigma> {
  final repo = ServicioGestion.vistaPrevia();
  late final _ApiSinConexion api;
  late final SesionUsuario sesion;
  @override
  void initState() {
    super.initState();
    sesion = SesionUsuario(
      tokenAcceso: 'preview-offline',
      fechaVencimiento: DateTime.now().add(const Duration(hours: 1)),
      nombreEmpresa: 'REVELA · ejemplo',
      idEmpresa: 1,
      usuario: 'Administrador',
      rol: 'Gestor',
    );
    final original = repo.memoria[ModuloGestion.reservas]!.first;
    repo.memoria[ModuloGestion.reservas]!.addAll([
      for (var i = 0; i < 3; i++)
        {
          ...original,
          'id': i + 2,
          'estado': [0, 2, 3][i],
          'horaInicio': ['14:00:00', '08:30:00', '11:00:00'][i],
          'cliente': {
            ...(original['cliente'] as Map),
            'nombres': ['Luisa', 'Juliana', 'Carmelo'][i],
            'apellidos': ['Cárdenas', 'Cruz', 'Paz'][i],
          },
        },
    ]);
    repo.alCambiarPestanaProfesional = (tab) {
      if (!mounted) return;
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => PortalProfesional(
            servicio: repo,
            idProfesional: 1,
            usuario: 'Camilo',
            pestanaInicial: tab,
            alCerrarSesion: () => Navigator.pop(context),
          ),
        ),
      );
    };
    api = _ApiSinConexion(repo, sesion);
  }

  @override
  void dispose() {
    api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = widget.frame, name = frame.name.toLowerCase(), id = frame.id;
    void back() => Navigator.pop(context);
    if (id == '77:148') {
      return PantallaCargaInicial(
        child: SectionShell(
          title: 'Splash',
          child: Center(
            child: TextButton(onPressed: back, child: const Text('Volver')),
          ),
        ),
      );
    }
    if (['7:9', '99:375'].contains(id)) {
      return PantallaInicioSesion(
        servicio: _AccesoSinConexion(api, sesion),
        alIniciarSesion: (_) => Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute(builder: (_) => _datosInicio(back)),
        ),
        notice: id == '99:375'
            ? 'El usuario o la contraseña no son correctos.'
            : null,
      );
    }
    final recovery = {
      '77:110': 0,
      '142:835': 1,
      '390:24': 1,
      '390:95': 2,
      '390:143': 2,
      '390:193': 3,
    };
    if (recovery.containsKey(id)) {
      return PantallaRecuperacion(
        vistaPrevia: true,
        pasoInicial: recovery[id]!,
        mostrarError: ['390:24', '390:143'].contains(id),
      );
    }
    if (name.contains('profesional —')) {
      if (name.contains('detalle')) {
        return PantallaDetalle(
          modulo: ModuloGestion.reservas,
          servicio: repo,
          registro: {
            ...repo.memoria[ModuloGestion.reservas]!.first,
            'estado': name.contains('programada')
                ? 0
                : name.contains('cancelada')
                ? 3
                : name.contains('atendida')
                ? 2
                : 1,
          },
          soloLectura: true,
        );
      }
      if (name.contains('inasistencias')) {
        return PantallaListado(
          modulo: ModuloGestion.inasistencias,
          servicio: repo,
          idProfesional: 1,
          soloLectura: true,
          filtrosIniciales: name.contains('vacío')
              ? const {'previewEmpty': '1'}
              : const {},
        );
      }
      if (name.contains('vacía')) repo.memoria[ModuloGestion.reservas]!.clear();
      final tab = name.contains('agenda')
          ? 1
          : name.contains('servicios')
          ? 2
          : name.contains('horario')
          ? 3
          : name.contains('menú') || name.contains('cerrar')
          ? 4
          : 0;
      return _DialogoEjemplo(
        title: name.contains('cerrar') ? '¿Cerrar sesión?' : null,
        description: 'Saldrás de tu cuenta de profesional de REVELA.',
        child: PortalProfesional(
          servicio: repo,
          idProfesional: 1,
          usuario: 'Camilo',
          pestanaInicial: tab,
          alCerrarSesion: back,
        ),
      );
    }
    if (id == '294:103') {
      return const SectionShell(
        title: 'Inicio',
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (['144:945', '262:24', '428:36'].contains(id)) {
      return _DialogoEjemplo(
        title: id == '428:36' ? '¿Cerrar sesión?' : null,
        description: 'Para volver a entrar deberás iniciar sesión.',
        child: _datosInicio(back),
      );
    }
    if (['404:33', '428:235'].contains(id)) {
      return _DialogoEjemplo(
        title: id == '428:235' ? '¿Cerrar sesión?' : null,
        description: 'Para volver a entrar deberás iniciar sesión.',
        child: PantallaMenuGestion(servicio: repo),
      );
    }
    ModuloGestion modulo = name.contains('especialidad')
        ? ModuloGestion.especialidades
        : name.contains('cliente')
        ? ModuloGestion.clientes
        : name.contains('profesional')
        ? ModuloGestion.profesionales
        : name.contains('servicio')
        ? ModuloGestion.servicios
        : name.contains('inasistencia')
        ? ModuloGestion.inasistencias
        : name.contains('horario')
        ? ModuloGestion.horarios
        : name.contains('comision') || name.contains('comisión')
        ? ModuloGestion.comisiones
        : name.contains('cierre')
        ? ModuloGestion.cierres
        : ModuloGestion.reservas;
    final registro = Map<String, dynamic>.from(repo.memoria[modulo]!.first);
    final error = name.contains('error') || name.contains('validación');
    final format = name.contains('formato') || name.contains('reglas');
    if (name.contains('creado') ||
        name.contains('creada') ||
        name.contains('guardado') ||
        name.contains('registrada') ||
        id == '239:1256') {
      return PantallaOperacionExitosa(
        title: id == '239:1256' ? '¡Reserva Confirmada!' : frame.name,
        message:
            'El registro se guardó correctamente en esta vista de ejemplo.',
      );
    }
    if (name.contains('sin resultados')) {
      return PantallaListado(
        modulo: modulo,
        servicio: repo,
        filtrosIniciales: const {'previewEmpty': '1'},
      );
    }
    if (name.contains('detalle') ||
        name.contains('dialogo - cancelar') ||
        name.contains('dialogo - confirmar')) {
      return PantallaDetalle(
        modulo: modulo,
        servicio: repo,
        registro: {
          ...registro,
          if (name.contains('cancelada')) 'estado': 3,
          if (name.contains('atendida')) 'estado': 2,
        },
        accionInicial: name.contains('cancelar') || name.contains('cancelación')
            ? 'cancel'
            : name.contains('asistencia')
            ? 'attendance'
            : null,
      );
    }
    if (id == '201:133' || id == '377:177') {
      return PantallaRevisionDatos(
        modulo: modulo,
        servicio: repo,
        values: modulo == ModuloGestion.reservas
            ? {
                'clienteId': 1,
                'servicioId': 1,
                'fechaDia': DateTime.now()
                    .add(const Duration(days: 1))
                    .toIso8601String()
                    .split('T')
                    .first,
                'hora': '10:00:00',
              }
            : {
                'fechaInicio': registro['fechaInicio'],
                'fechaFin': registro['fechaFin'],
              },
        campos: camposFormulario(modulo),
        opciones: {
          'clienteId': repo.memoria[ModuloGestion.clientes]!,
          'servicioId': repo.memoria[ModuloGestion.servicios]!,
        },
      );
    }
    final form =
        name.contains('crear') ||
        name.contains('formulario') ||
        name.contains('editar') ||
        name.contains('configurar') ||
        name.contains('registrar') ||
        name.contains('reagendar') ||
        name.contains('desactivar');
    if (form) {
      final edit =
          name.contains('editar') ||
          name.contains('desactivar') ||
          name.contains('reagendar');
      final datosIniciales = <String, dynamic>{
        if (edit) ...registro,
        if (modulo == ModuloGestion.horarios) ...registro,
        if (modulo == ModuloGestion.horarios) 'dia': 'sabado',
        if (modulo == ModuloGestion.horarios)
          'tieneAlmuerzo': name.contains('almuerzo'),
        if (modulo == ModuloGestion.inasistencias)
          'tipoFecha': name.contains('rango') ? 'rango' : 'dia',
        if (format && modulo == ModuloGestion.clientes) ...{
          'documento': '100000009',
          'nombres': 'Mariana',
          'apellidos': 'Gómez',
          'correo': 'correo-invalido',
          'celular': 'abc',
        },
        if (format && modulo == ModuloGestion.servicios) ...{
          'nombre': 'Corte',
          'precio': 'abc',
          'duracion': '-5',
        },
        if (format && modulo == ModuloGestion.profesionales) ...{
          'documento': '100000009',
          'nombres': 'Camilo',
          'porcentaje': 150,
          'fechaNacimiento': '2099-01-01',
        },
      };
      return PantallaFormulario(
        modulo: modulo,
        servicio: repo,
        datosIniciales: datosIniciales.isEmpty ? null : datosIniciales,
        esEdicion: edit,
        mostrarErrores: error,
        errorInicial: error && name.contains('rango')
            ? 'La fecha final debe ser igual o posterior a la inicial.'
            : null,
        accionInicial: name.contains('desactivar') ? 'deactivate' : null,
      );
    }
    return PantallaListado(
      modulo: modulo,
      servicio: repo,
      idProfesional: modulo == ModuloGestion.horarios ? 1 : null,
    );
  }

  Widget _datosInicio(VoidCallback back) => PantallaInicio(
    sesion: sesion,
    alCerrarSesion: back,
    alVencerSesion: back,
    repositorioGestion: repo,
    servicio: ServicioInicio(api, sesion),
  );
}

class _ApiSinConexion extends ClienteApi {
  _ApiSinConexion(this.repo, this.sesion)
    : super(urlBase: Uri.parse('https://preview.revela.invalid/'));
  final ServicioGestion repo;
  final SesionUsuario sesion;
  @override
  Future<Object?> get(String path, {String? token}) async {
    final uri = Uri.parse(path);
    final modulo = ModuloGestion.values
        .where((m) => m.path.toLowerCase() == uri.path.toLowerCase())
        .firstOrNull;
    return {
      'success': true,
      'data': modulo == null ? <Object>[] : repo.memoria[modulo]!,
    };
  }

  @override
  Future<Object?> post(String path, {Object? body, String? token}) async =>
      throw StateError('La vista de diseño no envía solicitudes al servidor.');
}

class _AccesoSinConexion extends ServicioAutenticacion {
  _AccesoSinConexion(super.api, this.sesion);
  final SesionUsuario sesion;
  @override
  Future<SesionUsuario> iniciarSesion({
    required String usuario,
    required String contrasena,
  }) async => sesion;
}

class _DialogoEjemplo extends StatefulWidget {
  const _DialogoEjemplo({
    required this.child,
    this.title,
    required this.description,
  });
  final Widget child;
  final String? title;
  final String description;
  @override
  State<_DialogoEjemplo> createState() => _EstadoDialogoEjemplo();
}

class _EstadoDialogoEjemplo extends State<_DialogoEjemplo> {
  @override
  void initState() {
    super.initState();
    if (widget.title != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          confirmarAccion(
            context,
            title: widget.title!,
            description: widget.description,
            action: 'Sí, cerrar sesión',
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
