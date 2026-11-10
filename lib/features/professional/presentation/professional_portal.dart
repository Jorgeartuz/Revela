import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/domain/reservation.dart';
import '../../management/data/management_repository.dart';
import '../../management/domain/module.dart';
import '../../management/domain/record_values.dart';
import '../../management/presentation/module_list.dart';
import '../../management/presentation/record_detail.dart';
import '../../management/presentation/shared.dart';
import '../../management/presentation/operational_views.dart';

class ProfessionalPortal extends StatefulWidget {
  const ProfessionalPortal({
    super.key,
    required this.repository,
    required this.onLogout,
    this.professionalId,
    this.username,
    this.initialTab = 0,
  });
  final ManagementRepository repository;
  final VoidCallback onLogout;
  final int? professionalId;
  final String? username;
  final int initialTab;
  @override
  State<ProfessionalPortal> createState() => _ProfessionalPortalState();
}

class _ProfessionalPortalState extends State<ProfessionalPortal> {
  int _tab = 0;
  Future<(Map<String, dynamic>?, List<Map<String, dynamic>>)>? _home;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    widget.repository.onProfessionalTab = _navigateTab;
    if (widget.professionalId != null) {
      _home = _loadHome();
    }
  }

  Future<(Map<String, dynamic>?, List<Map<String, dynamic>>)>
  _loadHome() async {
    final profile = await widget.repository.professional(
      widget.professionalId!,
    );
    final appointments = await widget.repository.list(
      Module.reservations,
      filters: {'profesionalId': '${widget.professionalId}'},
    );
    return (profile, appointments);
  }

  Future<void> _refreshHome() async {
    if (widget.professionalId == null) return;
    setState(() => _home = _loadHome());
    try {
      await _home;
    } catch (_) {
      /* Presented by FutureBuilder. */
    }
  }

  void _navigateTab(int tab) {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    Navigator.popUntil(context, (r) => r == route);
    setState(() {
      _tab = tab;
      if (tab == 0 && widget.professionalId != null) _home = _loadHome();
    });
  }

  @override
  void dispose() {
    if (widget.repository.onProfessionalTab == _navigateTab) {
      widget.repository.onProfessionalTab = null;
    }
    super.dispose();
  }

  Widget _icon(String name, double size, {Color? color}) => SvgPicture.asset(
    'assets/icons/$name.svg',
    width: size,
    height: size,
    colorFilter: color == null
        ? null
        : ColorFilter.mode(color, BlendMode.srcIn),
  );
  void _open(Module module) => Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (context) => ModuleListPage(
        module: module,
        repository: widget.repository,
        professionalId: widget.professionalId,
        readOnly: true,
      ),
    ),
  );
  Future<void> _logout() async {
    if (await confirmAction(
          context,
          title: '¿Cerrar sesión?',
          description: 'Para volver a entrar deberás iniciar sesión con tu usuario y contraseña.',
          action: 'Cerrar sesión',
        ) &&
        mounted) {
      widget.onLogout();
    }
  }

  Widget _stat(String icon, String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _icon(icon, 24),
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
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: _tab == 0
        ? null
        : AppBar(
            title: Text(
              [
                'Inicio',
                'Mi agenda',
                'Mis servicios',
                'Mi horario',
                'Más',
              ][_tab],
            ),
            actions: [
              IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: _logout,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          if (widget.repository.preview)
            const MaterialBanner(
              content: Text('Vista de diseño · datos de ejemplo'),
              actions: [SizedBox.shrink()],
            ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _body(),
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Row(
            children: List.generate(
              5,
              (i) => Expanded(
                child: InkWell(
                  onTap: () => _navigateTab(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 54,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _tab == i
                              ? const Color(0x2EC8A2B7)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: _icon(
                          [
                            'nav_home',
                            'nav_agenda',
                            'nav_my_services',
                            'nav_schedule',
                            'nav_more',
                          ][i],
                          22,
                          color: _tab == i
                              ? AppColors.primary
                              : AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ['Inicio', 'Agenda', 'Servicios', 'Horario', 'Más'][i],
                        style: TextStyle(
                          fontSize: 10.5,
                          color: _tab == i
                              ? AppColors.primary
                              : AppColors.muted,
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
  Widget _body() {
    if (widget.professionalId == null) {
      return ListView(
        padding: const EdgeInsets.all(21),
        children: [
          section('MI PERFIL'),
          Text(
            widget.username ?? 'Profesional',
            style: const TextStyle(fontSize: 22),
          ),
          infoBox(
            'Tu perfil necesita completar la vinculación con el centro para consultar citas, servicios y horarios. Contacta al administrador.',
          ),
          TextButton(onPressed: _logout, child: const Text('Cerrar sesión')),
        ],
      );
    }
    if (_tab == 4) {
      return ListView(
        padding: const EdgeInsets.all(21),
        children: [
          Text(
            'Tu espacio en REVELA · ${widget.username ?? 'Profesional'}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          section('MI TRABAJO'),
          ListTile(
            leading: _icon('professional_services', 22),
            title: const Text('Mis servicios'),
            subtitle: const Text('Servicios y comisiones del período'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => setState(() => _tab = 2),
          ),
          ListTile(
            leading: _icon('professional_schedule', 22),
            subtitle: const Text('Días y horas de trabajo de la semana'),
            title: const Text('Mi horario'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => setState(() => _tab = 3),
          ),
          ListTile(
            leading: _icon('professional_absences', 22),
            subtitle: const Text('Días no disponibles registrados'),
            title: const Text('Mis inasistencias'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(Module.absences),
          ),
          section('CUENTA'),
          ListTile(
            title: const Text('Cerrar sesión'),
            leading: const Icon(Icons.logout),
            onTap: _logout,
          ),
        ],
      );
    }
    if (_tab == 2) {
      return ProfessionalServicesView(
        repository: widget.repository,
        professionalId: widget.professionalId!,
      );
    }
    if (_tab > 0) {
      return ModuleListPage(
        key: ValueKey(_tab),
        module: [
          Module.reservations,
          Module.reservations,
          Module.commissions,
          Module.schedules,
        ][_tab],
        repository: widget.repository,
        professionalId: widget.professionalId,
        readOnly: true,
        embedded: true,
      );
    }
    return RefreshIndicator(
      onRefresh: _refreshHome,
      child: FutureBuilder<(Map<String, dynamic>?, List<Map<String, dynamic>>)>(
        future: _home,
        builder: (context, snapshot) {
          final now = DateTime.now();
          final rows = (snapshot.data?.$2 ?? []).where((r) {
            final d = DateTime.tryParse(r['fecha']?.toString() ?? '');
            return d != null &&
                d.year == now.year &&
                d.month == now.month &&
                d.day == now.day;
          }).toList();
          final states = widget.repository.preview
              ? const ReservationStates(
                  scheduled: 0,
                  confirmed: 1,
                  attended: 2,
                  cancelled: 3,
                )
              : ReservationStates.configured;
          String count(int? code) => !snapshot.hasData || code == null
              ? '—'
              : '${rows.where((r) => r['estado'] == code).length}';
          final profile = snapshot.data?.$1;
          final upcoming =
              rows.where((r) {
                  final start = recordStart(r);
                  return start != null &&
                      start.isAfter(now) &&
                      ((states.scheduled != null &&
                              r['estado'] == states.scheduled) ||
                          (states.confirmed != null &&
                              r['estado'] == states.confirmed));
                }).toList()
                ..sort((a, b) => recordStart(a)!.compareTo(recordStart(b)!));
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
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${now.hour < 12
                              ? 'Buenos días'
                              : now.hour < 18
                              ? 'Buenas tardes'
                              : 'Buenas noches'}, ${widget.username ?? 'Profesional'}',
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
                    onPressed: _logout,
                    icon: SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        children: [
                          _icon('avatar_circle', 40),
                          Positioned(
                            left: 12.88,
                            top: 12.88,
                            child: Image.asset(
                              'assets/icons/avatar_mark.png',
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
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      child: Text(
                        initials(
                          profile == null
                              ? widget.username ?? 'Profesional'
                              : recordName(profile),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile == null
                                ? widget.username ?? 'Profesional'
                                : recordName(profile),
                          ),
                          if (profile != null)
                            Text(
                              '${nested(profile, 'especialidad')['nombre'] ?? 'Especialidad sin informar'} · Comisión ${profile['porcentaje'] ?? '—'}%',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
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
                  _stat(
                    'stat_calendar',
                    snapshot.hasData ? '${rows.length}' : '—',
                    'Citas hoy',
                  ),
                  const SizedBox(width: 12),
                  _stat('stat_people', count(states.scheduled), 'Pendientes'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _stat(
                    'stat_clock',
                    upcoming.isEmpty
                        ? '—'
                        : clockLabel(upcoming.first['horaInicio']),
                    'Próxima cita',
                  ),
                  const SizedBox(width: 12),
                  _stat(
                    'stat_scissors',
                    count(states.attended),
                    'Atendidas hoy',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              section('ACCESOS RÁPIDOS'),
              FilledButton(
                onPressed: () => setState(() => _tab = 1),
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
                      _icon('professional_agenda', 26),
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
                          color: AppColors.placeholder,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () => i == 2
                                ? _open(Module.absences)
                                : setState(() => _tab = i == 0 ? 2 : 3),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  _icon(
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
                    onPressed: () => setState(() => _tab = 1),
                    child: const Text('Ver todas'),
                  ),
                ],
              ),
              if (snapshot.hasError) ...[
                infoBox(errorMessage(snapshot.error)),
                TextButton(
                  onPressed: _refreshHome,
                  child: const Text('Reintentar'),
                ),
              ] else if (!snapshot.hasData)
                const Center(child: CircularProgressIndicator())
              else if (upcoming.isEmpty)
                infoBox('No hay próximas citas para mostrar hoy.')
              else
                ...upcoming
                    .take(3)
                    .map(
                      (r) => RecordCard(
                        module: Module.reservations,
                        row: r,
                        preview: widget.repository.preview,
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecordDetailPage(
                              module: Module.reservations,
                              row: r,
                              repository: widget.repository,
                              readOnly: true,
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
