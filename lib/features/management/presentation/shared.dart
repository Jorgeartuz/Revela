import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/module.dart';
import '../domain/record_values.dart';

String money(Object? value) => value is num
    ? r'$' + NumberFormat.decimalPattern('es_CO').format(value.round())
    : '—';
String dateLabel(Object? value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  return date == null
      ? 'Sin fecha'
      : DateFormat('dd/MM/yyyy', 'es').format(date);
}

String errorMessage(Object? error) =>
    error?.toString() ?? 'No se pudo completar la operación.';

Widget section(String title) => Padding(
  padding: const EdgeInsets.only(top: 12, bottom: 16),
  child: Text(
    title,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1,
      color: AppColors.placeholder,
    ),
  ),
);
Widget infoBox(String message) => Container(
  margin: const EdgeInsets.symmetric(vertical: 12),
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: AppColors.surface,
    border: Border.all(color: AppColors.border),
    borderRadius: BorderRadius.circular(14),
  ),
  child: Text(
    message,
    style: const TextStyle(color: AppColors.muted, fontSize: 13),
  ),
);

class SectionShell extends StatelessWidget {
  const SectionShell({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.bottom,
    this.preview = false,
  });
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? bottom;
  final bool preview;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'OpenSans',
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: actions,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
    ),
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          if (preview)
            const MaterialBanner(
              content: Text(
                'Vista de diseño · datos de ejemplo',
                style: TextStyle(fontSize: 12),
              ),
              actions: [SizedBox.shrink()],
            ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ScrollConfiguration(
                  behavior: const RevelaScrollBehavior(),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: bottom,
  );
}

class RecordCard extends StatelessWidget {
  const RecordCard({
    super.key,
    required this.module,
    required this.row,
    required this.onTap,
    this.preview = false,
  });
  final Module module;
  final Map<String, dynamic> row;
  final VoidCallback onTap;
  final bool preview;
  @override
  Widget build(BuildContext context) {
    final person = module == Module.customers || module == Module.professionals;
    final name = switch (module) {
      Module.reservations => personName(row['cliente']),
      Module.schedules => dayLabel(row['diaSemana'], preview: preview),
      Module.absences =>
        '${dateLabel(row['fechaInicio'])} → ${dateLabel(row['fechaFin'])}',
      Module.closures => 'Cierre #${row['id']}',
      Module.commissions => personName(row['profesional']),
      _ => recordName(row),
    };
    final subtitle = switch (module) {
      Module.customers =>
        'CC ${row['documento'] ?? '—'} · Cel. ${row['celular'] ?? '—'}',
      Module.professionals =>
        'CC ${row['documento'] ?? '—'} · Comisión ${row['porcentaje'] ?? '—'}%',
      Module.services =>
        '${money(row['precio'])} · ${row['duracion'] ?? '—'} min',
      Module.specialties => row['activa'] == true ? 'Activa' : 'Inactiva',
      Module.reservations =>
        '${dateLabel(row['fecha'])} · ${row['horaInicio'] ?? ''} · ${row['servicio'] is Map ? (row['servicio'] as Map)['nombre'] ?? 'Servicio' : 'Servicio'}',
      Module.schedules =>
        '${row['horaInicio'] ?? ''} – ${row['horaFin'] ?? ''}',
      Module.absences =>
        row['observacion']?.toString() ?? 'Inasistencia registrada',
      Module.closures =>
        '${dateLabel(row['fechaInicio'])} — ${dateLabel(row['fechaFin'])}',
      Module.commissions => 'Comisión: ${money(row['valorComision'])}',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          leading: person
              ? CircleAvatar(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  child: Text(initials(name)),
                )
              : null,
          title: Text(
            name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.muted,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class SectionNavigation extends StatelessWidget {
  const SectionNavigation({
    super.key,
    required this.module,
    required this.onSelect,
  });
  final Module module;
  final ValueChanged<Module?> onSelect;
  @override
  Widget build(BuildContext context) {
    final entries = <Module?>[
      null,
      Module.reservations,
      Module.professionals,
      Module.customers,
      Module.specialties,
    ];
    final selected = module == Module.reservations
        ? 1
        : module == Module.professionals ||
              module == Module.schedules ||
              module == Module.absences
        ? 2
        : module == Module.customers
        ? 3
        : 4;
    return ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 78,
          child: Row(
            children: List.generate(
              5,
              (i) => Expanded(
                child: InkWell(
                  onTap: () => onSelect(entries[i]),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 54,
                        height: 30,
                        decoration: BoxDecoration(
                          color: i == selected
                              ? const Color(0x2EC8A2B7)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          'assets/icons/${['nav_home', 'nav_agenda', 'nav_professionals', 'nav_clients', 'nav_more'][i]}.svg',
                          width: 22,
                          height: 22,
                          colorFilter: ColorFilter.mode(
                            i == selected ? AppColors.primary : AppColors.muted,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        child: Text(
                          [
                            'Inicio',
                            'Agenda',
                            'Profesionales',
                            'Clientes',
                            'Más',
                          ][i],
                          style: TextStyle(
                            fontSize: 10.5,
                            color: i == selected
                                ? AppColors.primary
                                : AppColors.muted,
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
    );
  }
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String description,
  required String action,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

String dayLabel(Object? value, {bool preview = false}) {
  const labels = {
    'domingo': 'Domingo',
    'lunes': 'Lunes',
    'martes': 'Martes',
    'miercoles': 'Miércoles',
    'jueves': 'Jueves',
    'viernes': 'Viernes',
    'sabado': 'Sábado',
  };
  final codes = weekdayCodes(preview: preview);
  for (final entry in codes.entries) {
    if ('${entry.value}' == '$value') {
      return labels[entry.key] ?? 'Jornada laboral';
    }
  }
  return 'Jornada laboral';
}
