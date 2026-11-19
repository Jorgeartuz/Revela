import 'package:revela/widgets/estructura/barra_aplicacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/models/gestion/valores_registro.dart';

String formatoMoneda(Object? value) => value is num
    ? r'$' + NumberFormat.decimalPattern('es_CO').format(value.round())
    : '—';
String formatoFecha(Object? value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  return date == null
      ? 'Sin fecha'
      : DateFormat('dd/MM/yyyy', 'es').format(date);
}

String mensajeError(Object? error) =>
    error?.toString() ?? 'No se pudo completar la operación.';

Widget tituloSeccion(String title) => Padding(
  padding: const EdgeInsets.only(top: 12, bottom: 16),
  child: Text(
    title,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1,
      color: ColoresAplicacion.textoAyuda,
    ),
  ),
);
Widget cuadroInformacion(String message) => Container(
  margin: const EdgeInsets.symmetric(vertical: 12),
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: ColoresAplicacion.superficie,
    border: Border.all(color: ColoresAplicacion.borde),
    borderRadius: BorderRadius.circular(14),
  ),
  child: Text(
    message,
    style: const TextStyle(
      color: ColoresAplicacion.textoSecundario,
      fontSize: 13,
    ),
  ),
);

class SectionShell extends StatelessWidget {
  const SectionShell({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.bottom,
    this.centrarTitulo = false,
  });
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? bottom;
  final bool centrarTitulo;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BarraAplicacion(
      titulo: title,
      acciones: actions,
      centrarTitulo: centrarTitulo,
    ),
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ScrollConfiguration(
                  behavior: const DesplazamientoRevela(),
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
    required this.modulo,
    required this.registro,
    required this.onTap,
  });
  final ModuloGestion modulo;
  final Map<String, dynamic> registro;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final person =
        modulo == ModuloGestion.clientes ||
        modulo == ModuloGestion.profesionales;
    final name = switch (modulo) {
      ModuloGestion.reservas => nombrePersona(registro['cliente']),
      ModuloGestion.horarios => nombreDia(registro['diaSemana']),
      ModuloGestion.inasistencias =>
        '${formatoFecha(registro['fechaInicio'])} → ${formatoFecha(registro['fechaFin'])}',
      ModuloGestion.cierres => 'Cierre #${registro['id']}',
      ModuloGestion.comisiones => nombrePersona(registro['profesional']),
      _ => nombreRegistro(registro),
    };
    final subtitle = switch (modulo) {
      ModuloGestion.clientes =>
        'CC ${registro['documento'] ?? '—'} · Cel. ${registro['celular'] ?? '—'}',
      ModuloGestion.profesionales =>
        'CC ${registro['documento'] ?? '—'} · Comisión ${registro['porcentaje'] ?? '—'}%',
      ModuloGestion.servicios =>
        '${formatoMoneda(registro['precio'])} · ${registro['duracion'] ?? '—'} min',
      ModuloGestion.especialidades =>
        registro['activa'] == true ? 'Activa' : 'Inactiva',
      ModuloGestion.reservas =>
        '${formatoFecha(registro['fecha'])} · ${registro['horaInicio'] ?? ''} · ${registro['servicio'] is Map ? (registro['servicio'] as Map)['nombre'] ?? 'Servicio' : 'Servicio'}',
      ModuloGestion.horarios =>
        '${registro['horaInicio'] ?? ''} – ${registro['horaFin'] ?? ''}',
      ModuloGestion.inasistencias =>
        registro['observacion']?.toString() ?? 'Inasistencia registrada',
      ModuloGestion.cierres =>
        '${formatoFecha(registro['fechaInicio'])} — ${formatoFecha(registro['fechaFin'])}',
      ModuloGestion.comisiones =>
        'Comisión: ${formatoMoneda(registro['valorComision'])}',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: ColoresAplicacion.superficie,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: ColoresAplicacion.borde),
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
                  backgroundColor: ColoresAplicacion.principal,
                  foregroundColor: ColoresAplicacion.fondo,
                  child: Text(iniciales(name)),
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
              style: const TextStyle(
                fontSize: 12,
                color: ColoresAplicacion.textoSecundario,
              ),
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            size: 20,
            color: ColoresAplicacion.textoSecundario,
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
    required this.modulo,
    required this.onSelect,
    this.seleccionCuadrada = false,
  });
  final ModuloGestion modulo;
  final ValueChanged<ModuloGestion?> onSelect;
  final bool seleccionCuadrada;
  @override
  Widget build(BuildContext context) {
    final entries = <ModuloGestion?>[
      null,
      ModuloGestion.reservas,
      ModuloGestion.profesionales,
      ModuloGestion.clientes,
      ModuloGestion.especialidades,
    ];
    final selected = modulo == ModuloGestion.reservas
        ? 1
        : modulo == ModuloGestion.profesionales ||
              modulo == ModuloGestion.horarios ||
              modulo == ModuloGestion.inasistencias
        ? 2
        : modulo == ModuloGestion.clientes
        ? 3
        : 4;
    return ColoredBox(
      color: ColoresAplicacion.superficie,
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
                          borderRadius: BorderRadius.circular(
                            seleccionCuadrada && i == selected ? 0 : 99,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          'recursos/iconos/${['nav_home', 'nav_agenda', 'nav_professionals', 'nav_clients', 'nav_more'][i]}.svg',
                          width: 22,
                          height: 22,
                          colorFilter: ColorFilter.mode(
                            i == selected
                                ? ColoresAplicacion.principal
                                : ColoresAplicacion.textoSecundario,
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
                                ? ColoresAplicacion.principal
                                : ColoresAplicacion.textoSecundario,
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

Future<bool> confirmarAccion(
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

String nombreDia(Object? value) {
  const labels = {
    'domingo': 'Domingo',
    'lunes': 'Lunes',
    'martes': 'Martes',
    'miercoles': 'Miércoles',
    'jueves': 'Jueves',
    'viernes': 'Viernes',
    'sabado': 'Sábado',
  };
  final codes = codigosDiasSemana();
  for (final entry in codes.entries) {
    if ('${entry.value}' == '$value') {
      return labels[entry.key] ?? 'Jornada laboral';
    }
  }
  return 'Jornada laboral';
}
