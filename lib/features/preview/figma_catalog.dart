import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../auth/data/auth_repository.dart';
import '../auth/domain/auth_session.dart';
import '../auth/presentation/login_screen.dart';
import '../auth/presentation/recovery_screen.dart';
import '../home/data/dashboard_repository.dart';
import '../home/presentation/home_screen.dart';
import '../management/data/management_repository.dart';
import '../management/domain/module.dart';
import '../management/domain/form_spec.dart';
import '../management/presentation/module_list.dart';
import '../management/presentation/record_form.dart';
import '../management/presentation/record_detail.dart';
import '../management/presentation/shared.dart';
import '../professional/presentation/professional_portal.dart';

class FigmaFrame {
  const FigmaFrame(this.id, this.name);
  final String id, name;
}

const figmaFrames = <FigmaFrame>[
  FigmaFrame("179:40", "Agenda"),
  FigmaFrame("77:148", "Splash"),
  FigmaFrame("7:9", "Inicio Sesión"),
  FigmaFrame("99:375", "Error de Acceso"),
  FigmaFrame("77:110", "Recuperación"),
  FigmaFrame("142:835", "Confirmación"),
  FigmaFrame("144:945", "Home"),
  FigmaFrame("179:198", "Cierres - Listado"),
  FigmaFrame("179:240", "Servicios"),
  FigmaFrame("179:277", "Especialidades"),
  FigmaFrame("179:314", "Clientes"),
  FigmaFrame("201:40", "Detalle de Reserva"),
  FigmaFrame("201:133", "Confirmación de Reserva"),
  FigmaFrame("201:226", "Reagendar Reserva"),
  FigmaFrame("201:472", "Dialogo - Cancelar Reserva"),
  FigmaFrame("201:623", "Dialogo - Confirmar Asistencia"),
  FigmaFrame("204:40", "Especialidades - Listado"),
  FigmaFrame("204:133", "Especialidad - Formulario"),
  FigmaFrame("204:226", "Especialidades - Sin resultados"),
  FigmaFrame("239:465", "Profesionales"),
  FigmaFrame("239:745", "Clientes"),
  FigmaFrame("239:951", "Crear Clientes"),
  FigmaFrame("239:1131", "Crear reserva"),
  FigmaFrame("239:1256", "Confirmacion Reserva"),
  FigmaFrame("262:24", "Home (Rediseño)"),
  FigmaFrame("276:24", "Reserva - Detalle (Modal: Confirmar Cancelación)"),
  FigmaFrame("277:24", "Reserva - Detalle"),
  FigmaFrame("288:24", "Comisiones - Detalle"),
  FigmaFrame("288:84", "Horario - Vista semanal"),
  FigmaFrame("294:24", "Crear Cliente (Error de Validación)"),
  FigmaFrame("294:103", "Estado de Carga - Home"),
  FigmaFrame("352:24", "Crear reserva (Error de Validación)"),
  FigmaFrame("359:61", "Detalle de Reserva (Cancelada)"),
  FigmaFrame("359:186", "Detalle de Reserva (Atendida)"),
  FigmaFrame("362:24", "Servicios - Listado"),
  FigmaFrame("362:88", "Servicios - Sin resultados"),
  FigmaFrame("362:152", "Crear Servicio"),
  FigmaFrame("362:216", "Crear Servicio (Error: obligatorios y rangos)"),
  FigmaFrame("362:280", "Crear Servicio (Error: formato)"),
  FigmaFrame("362:344", "Servicio Creado"),
  FigmaFrame("362:408", "Editar Servicio"),
  FigmaFrame("362:472", "Dialogo - Desactivar Servicio"),
  FigmaFrame("369:24", "Crear Profesional"),
  FigmaFrame("369:142", "Crear Profesional (Error: obligatorios)"),
  FigmaFrame("369:260", "Crear Profesional (Error: reglas)"),
  FigmaFrame("369:378", "Profesional Creado"),
  FigmaFrame("369:496", "Editar Profesional"),
  FigmaFrame("369:614", "Dialogo - Desactivar Profesional"),
  FigmaFrame("373:24", "Configurar horario"),
  FigmaFrame("373:248", "Configurar horario - Con almuerzo"),
  FigmaFrame("373:399", "Configurar horario - Error"),
  FigmaFrame("373:561", "Horario guardado"),
  FigmaFrame("376:24", "Registrar Inasistencia"),
  FigmaFrame("376:254", "Registrar Inasistencia - Rango"),
  FigmaFrame("376:398", "Registrar Inasistencia - Error (obligatorios)"),
  FigmaFrame("376:570", "Registrar Inasistencia - Error (rango)"),
  FigmaFrame("376:725", "Inasistencias - Listado"),
  FigmaFrame("376:934", "Inasistencia registrada"),
  FigmaFrame("377:59", "Crear Cierre"),
  FigmaFrame("377:177", "Crear Cierre - Resumen"),
  FigmaFrame("377:295", "Crear Cierre - Error"),
  FigmaFrame("377:413", "Cierre creado"),
  FigmaFrame("377:531", "Detalle de Cierre"),
  FigmaFrame("377:649", "Comisiones - Consolidado"),
  FigmaFrame("377:767", "Comisiones - Sin resultados"),
  FigmaFrame("382:102", "Crear Cliente - Error: formato"),
  FigmaFrame("382:235", "Editar Cliente"),
  FigmaFrame("382:350", "Detalle de Cliente"),
  FigmaFrame("382:502", "Clientes - Sin resultados"),
  FigmaFrame("382:682", "Cliente Creado"),
  FigmaFrame("383:129", "Especialidad Creada"),
  FigmaFrame("386:24", "Especialidad - Formulario (Error)"),
  FigmaFrame("390:24", "Código OTP - Inválido"),
  FigmaFrame("390:95", "Nueva contraseña"),
  FigmaFrame("390:143", "Nueva contraseña - Error"),
  FigmaFrame("390:193", "Contraseña actualizada"),
  FigmaFrame("404:33", "Más"),
  FigmaFrame("428:36", "Dialogo - Cerrar Sesión (Inicio)"),
  FigmaFrame("428:235", "Dialogo - Cerrar Sesión (Más)"),
  FigmaFrame("479:34", "Profesional — Home"),
  FigmaFrame("479:221", "Profesional — Agenda"),
  FigmaFrame("479:347", "Profesional — Agenda Vacía"),
  FigmaFrame("479:452", "Profesional — Detalle Reserva"),
  FigmaFrame("479:571", "Profesional — Detalle Reserva (Programada)"),
  FigmaFrame("479:690", "Profesional — Detalle Reserva (Cancelada)"),
  FigmaFrame("479:807", "Profesional — Detalle Reserva (Atendida)"),
  FigmaFrame("237:26", "Profesional — Mis Servicios"),
  FigmaFrame("479:926", "Profesional — Horario"),
  FigmaFrame("479:1081", "Profesional — Inasistencias"),
  FigmaFrame("479:1211", "Profesional — Inasistencias Vacío"),
  FigmaFrame("479:1341", "Profesional — Menú"),
  FigmaFrame("490:65", "Profesional — Cerrar Sesión"),
];

/// Each canvas frame has an explicit entry; repeated historical frames reuse the current flow.
class FigmaCatalog extends StatefulWidget {
  const FigmaCatalog({super.key});
  @override
  State<FigmaCatalog> createState() => _FigmaCatalogState();
}

class _FigmaCatalogState extends State<FigmaCatalog> {
  String _search = '';
  @override
  Widget build(BuildContext context) => SectionShell(
    title: '92 marcos de Figma',
    preview: true,
    child: ListView(
      padding: const EdgeInsets.all(21),
      children: [
        infoBox(
          'Inventario del archivo Proyecto_Revela. Incluye pantallas, estados, diálogos y versiones anteriores. Cada entrada abre su flujo equivalente con datos de ejemplo.',
        ),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Buscar pantalla de Figma',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _search = v),
        ),
        for (final frame in figmaFrames.where(
          (f) => f.name.toLowerCase().contains(_search.toLowerCase()),
        ))
          ListTile(
            title: Text(frame.name),
            subtitle: Text('Figma ${frame.id}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => FigmaPreview(frame: frame)),
            ),
          ),
      ],
    ),
  );
}

class FigmaPreview extends StatefulWidget {
  const FigmaPreview({super.key, required this.frame});
  final FigmaFrame frame;
  @override
  State<FigmaPreview> createState() => _FigmaPreviewState();
}

class _FigmaPreviewState extends State<FigmaPreview> {
  final repo = ManagementRepository.preview();
  late final _OfflineApi api;
  late final AuthSession session;
  @override
  void initState() {
    super.initState();
    session = AuthSession(
      accessToken: 'preview-offline',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      companyName: 'REVELA · ejemplo',
      companyId: 1,
      username: 'Administrador',
      role: 'Gestor',
    );
    final original = repo.memory[Module.reservations]!.first;
    repo.memory[Module.reservations]!.addAll([
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
    repo.onProfessionalTab = (tab) {
      if (!mounted) return;
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => ProfessionalPortal(
            repository: repo,
            professionalId: 1,
            username: 'Camilo',
            initialTab: tab,
            onLogout: () => Navigator.pop(context),
          ),
        ),
      );
    };
    api = _OfflineApi(repo, session);
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
      return SplashGate(
        child: SectionShell(
          title: 'Splash',
          child: Center(
            child: TextButton(onPressed: back, child: const Text('Volver')),
          ),
        ),
      );
    }
    if (['7:9', '99:375'].contains(id)) {
      return LoginScreen(
        repository: _OfflineAuth(api, session),
        onSignedIn: (_) => Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute(builder: (_) => _home(back)),
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
      return RecoveryScreen(
        preview: true,
        initialStage: recovery[id]!,
        showError: ['390:24', '390:143'].contains(id),
      );
    }
    if (name.contains('profesional —')) {
      if (name.contains('detalle')) {
        return RecordDetailPage(
          module: Module.reservations,
          repository: repo,
          row: {
            ...repo.memory[Module.reservations]!.first,
            'estado': name.contains('programada')
                ? 0
                : name.contains('cancelada')
                ? 3
                : name.contains('atendida')
                ? 2
                : 1,
          },
          readOnly: true,
        );
      }
      if (name.contains('inasistencias')) {
        return ModuleListPage(
          module: Module.absences,
          repository: repo,
          professionalId: 1,
          readOnly: true,
          initialFilters: name.contains('vacío')
              ? const {'previewEmpty': '1'}
              : const {},
        );
      }
      if (name.contains('vacía')) repo.memory[Module.reservations]!.clear();
      final tab = name.contains('agenda')
          ? 1
          : name.contains('servicios')
          ? 2
          : name.contains('horario')
          ? 3
          : name.contains('menú') || name.contains('cerrar')
          ? 4
          : 0;
      return _DialogPreview(
        title: name.contains('cerrar') ? '¿Cerrar sesión?' : null,
        description: 'Saldrás de tu cuenta de profesional de REVELA.',
        child: ProfessionalPortal(
          repository: repo,
          professionalId: 1,
          username: 'Camilo',
          initialTab: tab,
          onLogout: back,
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
      return _DialogPreview(
        title: id == '428:36' ? '¿Cerrar sesión?' : null,
        description: 'Para volver a entrar deberás iniciar sesión.',
        child: _home(back),
      );
    }
    if (['404:33', '428:235'].contains(id)) {
      return _DialogPreview(
        title: id == '428:235' ? '¿Cerrar sesión?' : null,
        description: 'Para volver a entrar deberás iniciar sesión.',
        child: ManagementMenuPage(repository: repo),
      );
    }
    Module module = name.contains('especialidad')
        ? Module.specialties
        : name.contains('cliente')
        ? Module.customers
        : name.contains('profesional')
        ? Module.professionals
        : name.contains('servicio')
        ? Module.services
        : name.contains('inasistencia')
        ? Module.absences
        : name.contains('horario')
        ? Module.schedules
        : name.contains('comision') || name.contains('comisión')
        ? Module.commissions
        : name.contains('cierre')
        ? Module.closures
        : Module.reservations;
    final row = Map<String, dynamic>.from(repo.memory[module]!.first);
    final error = name.contains('error') || name.contains('validación');
    final format = name.contains('formato') || name.contains('reglas');
    if (name.contains('creado') ||
        name.contains('creada') ||
        name.contains('guardado') ||
        name.contains('registrada') ||
        id == '239:1256') {
      return OperationSuccessPage(
        title: id == '239:1256' ? '¡Reserva Confirmada!' : frame.name,
        message:
            'El registro se guardó correctamente en esta vista de ejemplo.',
      );
    }
    if (name.contains('sin resultados')) {
      return ModuleListPage(
        module: module,
        repository: repo,
        initialFilters: const {'previewEmpty': '1'},
      );
    }
    if (name.contains('detalle') ||
        name.contains('dialogo - cancelar') ||
        name.contains('dialogo - confirmar')) {
      return RecordDetailPage(
        module: module,
        repository: repo,
        row: {
          ...row,
          if (name.contains('cancelada')) 'estado': 3,
          if (name.contains('atendida')) 'estado': 2,
        },
        initialAction: name.contains('cancelar') || name.contains('cancelación')
            ? 'cancel'
            : name.contains('asistencia')
            ? 'attendance'
            : null,
      );
    }
    if (id == '201:133' || id == '377:177') {
      return RecordReviewPage(
        module: module,
        repository: repo,
        values: module == Module.reservations
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
            : {'fechaInicio': row['fechaInicio'], 'fechaFin': row['fechaFin']},
        fields: formFields(module),
        options: {
          'clienteId': repo.memory[Module.customers]!,
          'servicioId': repo.memory[Module.services]!,
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
      final initial = <String, dynamic>{
        if (edit) ...row,
        if (module == Module.schedules) ...row,
        if (module == Module.schedules) 'dia': 'sabado',
        if (module == Module.schedules)
          'tieneAlmuerzo': name.contains('almuerzo'),
        if (module == Module.absences)
          'tipoFecha': name.contains('rango') ? 'rango' : 'dia',
        if (format && module == Module.customers) ...{
          'documento': '100000009',
          'nombres': 'Mariana',
          'apellidos': 'Gómez',
          'correo': 'correo-invalido',
          'celular': 'abc',
        },
        if (format && module == Module.services) ...{
          'nombre': 'Corte',
          'precio': 'abc',
          'duracion': '-5',
        },
        if (format && module == Module.professionals) ...{
          'documento': '100000009',
          'nombres': 'Camilo',
          'porcentaje': 150,
          'fechaNacimiento': '2099-01-01',
        },
      };
      return RecordFormPage(
        module: module,
        repository: repo,
        initial: initial.isEmpty ? null : initial,
        editing: edit,
        showErrors: error,
        initialError: error && name.contains('rango')
            ? 'La fecha final debe ser igual o posterior a la inicial.'
            : null,
        initialAction: name.contains('desactivar') ? 'deactivate' : null,
      );
    }
    return ModuleListPage(
      module: module,
      repository: repo,
      professionalId: module == Module.schedules ? 1 : null,
    );
  }

  Widget _home(VoidCallback back) => HomeScreen(
    session: session,
    onLogout: back,
    onSessionExpired: back,
    managementRepository: repo,
    repository: DashboardRepository(api, session),
  );
}

class _OfflineApi extends ApiClient {
  _OfflineApi(this.repo, this.session)
    : super(baseUrl: Uri.parse('https://preview.revela.invalid/'));
  final ManagementRepository repo;
  final AuthSession session;
  @override
  Future<Object?> get(String path, {String? token}) async {
    final uri = Uri.parse(path);
    final module = Module.values
        .where((m) => m.path.toLowerCase() == uri.path.toLowerCase())
        .firstOrNull;
    return {
      'success': true,
      'data': module == null ? <Object>[] : repo.memory[module]!,
    };
  }

  @override
  Future<Object?> post(String path, {Object? body, String? token}) async =>
      throw StateError('La vista de diseño no envía solicitudes al servidor.');
}

class _OfflineAuth extends AuthRepository {
  _OfflineAuth(super.api, this.session);
  final AuthSession session;
  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async => session;
}

class _DialogPreview extends StatefulWidget {
  const _DialogPreview({
    required this.child,
    this.title,
    required this.description,
  });
  final Widget child;
  final String? title;
  final String description;
  @override
  State<_DialogPreview> createState() => _DialogPreviewState();
}

class _DialogPreviewState extends State<_DialogPreview> {
  @override
  void initState() {
    super.initState();
    if (widget.title != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          confirmAction(
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
