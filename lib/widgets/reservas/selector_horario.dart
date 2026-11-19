import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:revela/models/reservas/horario_disponible.dart';

class SelectorHorario extends StatelessWidget {
  const SelectorHorario({super.key, required this.horarios});

  final List<HorarioDisponible> horarios;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Horarios disponibles',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (horarios.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No hay horarios disponibles para el servicio y la fecha seleccionados.',
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: horarios.length,
                itemBuilder: (context, indice) {
                  final horario = horarios[indice];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule),
                    title: Text(
                      DateFormat('h:mm a', 'es').format(horario.fecha),
                    ),
                    subtitle: Text(
                      DateFormat('EEEE, d MMMM', 'es').format(horario.fecha),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(context, horario),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    ),
  );
}
