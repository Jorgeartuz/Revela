import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/domain/account_role.dart';
import '../data/dashboard_repository.dart';
import '../domain/reservation.dart';
import '../../management/data/management_repository.dart';
import '../../management/domain/module.dart';
import '../../management/presentation/module_list.dart';
import '../../management/presentation/record_form.dart';
import '../../management/presentation/record_detail.dart';
import '../../professional/presentation/professional_portal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.session,
    required this.onLogout,
    required this.onSessionExpired,
    this.repository,
    this.managementRepository,
  });
  final AuthSession session;
  final VoidCallback onLogout, onSessionExpired;
  final DashboardRepository? repository;
  final ManagementRepository? managementRepository;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ApiClient? _ownedApi;
  ApiClient? _ownedManagementApi;
  late final ManagementRepository _management;
  late final DashboardRepository _repository;
  Future<DashboardSnapshot>? _dashboard;
  int _tab = 0;
  bool get _admin =>
      RolePolicy.resolve(widget.session.role) == AccountRole.administrator;
  bool get _professional =>
      RolePolicy.resolve(widget.session.role) == AccountRole.professional;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        DashboardRepository(
          _ownedApi = ApiClient(baseUrl: Uri.parse(ApiConfig.baseUrl)),
          widget.session,
          onUnauthorized: widget.onSessionExpired,
        );
    _management =
        widget.managementRepository ??
        ManagementRepository(
          api: _ownedManagementApi = ApiClient(
            baseUrl: Uri.parse(ApiConfig.baseUrl),
          ),
          session: widget.session,
          onUnauthorized: widget.onSessionExpired,
        );
    _management.onHome = () {
      if (mounted) setState(() => _tab = 0);
    };
    if (_admin) _dashboard = _repository.loadDay(DateTime.now());
  }

  @override
  void dispose() {
    _ownedApi?.close();
    _ownedManagementApi?.close();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!_admin) return;
    final future = _repository.loadDay(DateTime.now());
    setState(() => _dashboard = future);
    try {
      await future;
    } catch (_) {
      /* FutureBuilder presenta el error. */
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
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
    if (confirmed == true && mounted) widget.onLogout();
  }

  Module _module(Catalog catalog) => switch (catalog) {
    Catalog.customers => Module.customers,
    Catalog.professionals => Module.professionals,
    Catalog.services => Module.services,
    Catalog.specialties => Module.specialties,
    Catalog.closures => Module.closures,
  };
  Future<void> _openModule(Module module) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ModuleListPage(module: module, repository: _management),
      ),
    );
    if (mounted) await _refresh();
  }

  void _openCatalog(Catalog catalog) => _openModule(_module(catalog));
  Future<void> _newAppointment() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RecordFormPage(
          module: Module.reservations,
          repository: _management,
        ),
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  Future<void> _openReservation(Reservation reservation) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RecordDetailPage(
          module: Module.reservations,
          row: reservation.source,
          repository: _management,
        ),
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (_professional) {
      return ProfessionalPortal(
        repository: _management,
        onLogout: _logout,
        professionalId: widget.session.professionalId,
        username: widget.session.username,
      );
    }
    if (!_admin && !_professional) {
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
                  onPressed: widget.onLogout,
                  child: const Text('Volver al inicio de sesión'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final labels = _admin
        ? ['Inicio', 'Agenda', 'Profesionales', 'Clientes', 'Más']
        : ['Inicio', 'Agenda', 'Servicios', 'Horario', 'Más'];
    final icons = _admin
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
            child: _body(),
          ),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
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
                        selected: _tab == i,
                        button: true,
                        child: InkWell(
                          onTap: () => setState(() => _tab = i),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 10),
                            child: Column(
                              children: [
                                Container(
                                  width: 54,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: _tab == i
                                        ? const Color(0x2EC8A2B7)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(
                                      _admin && i == 0 ? 0 : 99,
                                    ),
                                  ),
                                  child: Center(
                                    child: _asset(
                                      icons[i],
                                      22,
                                      color: _tab == i
                                          ? AppColors.primary
                                          : AppColors.muted,
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
                                        color: _tab == i
                                            ? AppColors.primary
                                            : AppColors.muted,
                                        fontWeight: _tab == i
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

  Widget _body() {
    if (_tab == 4) return _menu();
    if (_tab == 1) {
      return ModuleListPage(
        module: Module.reservations,
        repository: _management,
        embedded: true,
      );
    }
    if (_professional && _tab > 0) {
      return _profilePending(
        title: ['Inicio', 'Mi agenda', 'Mis servicios', 'Mi horario'][_tab],
      );
    }
    if (_tab == 2 || _tab == 3) {
      final catalog = _tab == 2 ? Catalog.professionals : Catalog.customers;
      return Column(
        children: [
          _pageTitle(catalog.title),
          Expanded(
            child: ModuleListPage(
              key: ValueKey(catalog),
              module: _module(catalog),
              repository: _management,
              embedded: true,
            ),
          ),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<DashboardSnapshot>(
        future: _dashboard,
        builder: (context, snapshot) {
          final day = snapshot.data;
          return ListView(
            padding: const EdgeInsets.fromLTRB(21, 22, 21, 32),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (_tab == 0) ...[
                _header(),
                const SizedBox(height: 28),
                if (_professional) ...[
                  _professionalInfo(),
                  const SizedBox(height: 28),
                ],
                _stats(day),
                const SizedBox(height: 28),
                _quickLinks(day),
                const SizedBox(height: 28),
              ] else ...[
                _pageTitle('Agenda'),
                const SizedBox(height: 12),
                Text(
                  DateFormat('EEEE, d MMMM', 'es').format(DateTime.now()),
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 20),
              ],
              if (_professional)
                _profilePending(title: 'Próximas citas')
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text('Reservas de hoy', style: _sectionStyle),
                    ),
                    if (_tab == 0)
                      TextButton(
                        onPressed: () => setState(() => _tab = 1),
                        child: const Text(
                          'Ver todas',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.placeholder,
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
                  _ErrorView(
                    message: _errorText(snapshot.error),
                    onRetry: _refresh,
                  )
                else if (day == null || day.reservations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No hay reservas para hoy.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                else
                  ...(_tab == 0 ? day.reservations.take(3) : day.reservations)
                      .map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _ReservationCard(
                            reservation: r,
                            onOpen: () => _openReservation(r),
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

  Widget _header() {
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
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$greeting, ${_admin ? 'ADMIN' : widget.session.username ?? 'Profesional'}',
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
          onPressed: _logout,
          padding: EdgeInsets.zero,
          icon: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              children: [
                _asset('avatar_circle', 40),
                Positioned(
                  left: 12.88,
                  top: 12.88,
                  child: Image.asset(
                    'assets/icons/avatar_mark.png',
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

  Widget _stats(DashboardSnapshot? day) {
    final states = ReservationStates.configured;
    final now = DateTime.now();
    final next = day?.next(states, now);
    String count(int? value) => value?.toString() ?? '—';
    final values = [
      count(day?.reservations.length),
      count(day?.pending(states)),
      next == null ? '—' : '${next.startsAt.difference(now).inMinutes} min',
      _admin ? count(day?.inProgress(states, now)) : '—',
    ];
    final titles = [
      _admin ? 'Reservas hoy' : 'Citas hoy',
      'Pendientes',
      _admin ? 'Próximo turno' : 'Próxima cita',
      _admin ? 'En turno' : 'Atendidas hoy',
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _asset(icons[index], 24),
            const SizedBox(height: 8),
            Text(
              values[index],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              titles[index],
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
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

  Widget _quickLinks(DashboardSnapshot? day) {
    final labels = _admin
        ? ['Especialidades', 'Servicios', 'Cierres']
        : ['Mis servicios', 'Horario', 'Inasistencias'];
    final icons = _admin
        ? ['specialties', 'services', 'closures']
        : [
            'professional_services',
            'professional_schedule',
            'professional_absences',
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Accesos rápidos', style: _sectionStyle),
        const SizedBox(height: 14),
        Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _admin ? _newAppointment : () => setState(() => _tab = 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _admin ? 'Nueva Cita' : 'Mi agenda',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.background,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _admin
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
                  _asset(
                    _admin ? 'action_add' : 'professional_agenda',
                    _admin ? 30 : 26,
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
                  color: AppColors.placeholder,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _admin
                        ? _openCatalog(
                            [
                              Catalog.specialties,
                              Catalog.services,
                              Catalog.closures,
                            ][i],
                          )
                        : _showProfilePending(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(3, 16, 3, 14),
                      child: Column(
                        children: [
                          _asset(icons[i], 22),
                          const SizedBox(height: 8),
                          Text(
                            labels[i],
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: i == 0 ? 10 : 11,
                              color: AppColors.text,
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

  Widget _menu() => ListView(
    padding: const EdgeInsets.all(21),
    children: [
      _pageTitle('Más'),
      const SizedBox(height: 16),
      Text(
        widget.session.companyName,
        style: const TextStyle(color: AppColors.primary, fontSize: 18),
      ),
      const SizedBox(height: 8),
      Text(
        _admin ? 'Administración' : 'Profesional',
        style: const TextStyle(color: AppColors.muted),
      ),
      const SizedBox(height: 24),
      if (_admin)
        ...Catalog.values.map(
          (c) => ListTile(
            title: Text(c.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openCatalog(c),
          ),
        ),
      for (final module in [
        Module.schedules,
        Module.absences,
        Module.commissions,
      ])
        ListTile(
          title: Text(module.title),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openModule(module),
        ),
      const SizedBox(height: 24),
      ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Cerrar sesión'),
        onTap: _logout,
      ),
    ],
  );
  Widget _professionalInfo() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: const Color(0x2E9CA3AF)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(Icons.person_outline, color: AppColors.background),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.session.username ?? 'Profesional',
            style: const TextStyle(fontSize: 14.5),
          ),
        ),
      ],
    ),
  );
  Widget _profilePending({required String title}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 21),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: _sectionStyle),
        const SizedBox(height: 12),
        const Text(
          'Tu perfil necesita completar la vinculación con el centro para consultar esta información. Contacta al administrador.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
  void _showProfilePending() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Mi perfil'),
      content: const Text(
        'Contacta al administrador para completar la vinculación de tu perfil.',
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

const _sectionStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
Widget _pageTitle(String title) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
  child: Text(
    title,
    style: const TextStyle(
      fontFamily: 'OpenSans',
      fontSize: 24,
      fontWeight: FontWeight.w600,
    ),
  ),
);
Widget _asset(String name, double size, {Color? color}) => SvgPicture.asset(
  'assets/icons/$name.svg',
  width: size,
  height: size,
  colorFilter: color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
);
String _errorText(Object? error) => error is DashboardException
    ? error.message
    : 'No se pudo cargar la información. Vuelve a intentar.';

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
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
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({required this.reservation, required this.onOpen});
  final VoidCallback onOpen;
  final Reservation reservation;
  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final label = ReservationStates.configured.label(r.state);
    final pink = label == 'CONFIRMADA';
    return Material(
      color: AppColors.surface,
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
                color: pink ? AppColors.primary : AppColors.placeholder,
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
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  DateFormat('hh:mm').format(r.startsAt),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  DateFormat('a').format(r.startsAt),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.muted,
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
                                  r.customer,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  r.professional,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
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
                                      ? AppColors.primary
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: pink
                                        ? AppColors.background
                                        : AppColors.muted,
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
                            r.service,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '•  ${r.durationMinutes} min · ${NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(r.price)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
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
