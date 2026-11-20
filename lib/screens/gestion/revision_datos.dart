import 'package:flutter/material.dart';
import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/widgets/gestion/componentes_compartidos.dart';
import 'package:revela/models/gestion/campos_formulario.dart';

class PantallaRevisionDatos extends StatelessWidget {
  const PantallaRevisionDatos({
    super.key,
    required this.modulo,
    required this.values,
    required this.campos,
    required this.opciones,
    this.esEdicion = false,
  });
  final ModuloGestion modulo;
  final Map<String, dynamic> values;
  final List<CampoFormulario> campos;
  final Map<String, List<Map<String, dynamic>>> opciones;
  final bool esEdicion;
  @override
  Widget build(BuildContext context) => SectionShell(
    title: modulo == ModuloGestion.reservas
        ? esEdicion
              ? 'Revisar cambios de reserva'
              : 'Revisar reserva'
        : 'Resumen del Cierre',
    child: ListView(
      padding: const EdgeInsets.all(21),
      children: [
        tituloSeccion('REVISA LOS DATOS'),
        for (final f in campos)
          if (values[f.key] != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                f.label,
                style: const TextStyle(
                  color: ColoresAplicacion.textoSecundario,
                  fontSize: 12,
                ),
              ),
              subtitle: Text(
                f.origen != null
                    ? (opciones[f.key] ?? <Map<String, dynamic>>[])
                              .where((r) => r['id'] == values[f.key])
                              .map(nombreRegistro)
                              .firstOrNull ??
                          'Sin seleccionar'
                    : f.kind == TipoCampo.fecha
                    ? formatoFecha(values[f.key])
                    : values[f.key].toString(),
                style: const TextStyle(
                  color: ColoresAplicacion.texto,
                  fontSize: 16,
                ),
              ),
            ),
        if (modulo == ModuloGestion.reservas) ...[
          for (final servicio
              in opciones['servicioId'] ?? <Map<String, dynamic>>[])
            if (servicio['id'] == values['servicioId']) ...[
              ListTile(
                title: const Text('Precio'),
                trailing: Text(formatoMoneda(servicio['precio'])),
              ),
              ListTile(
                title: const Text('Duración'),
                trailing: Text('${servicio['duracion']} min'),
              ),
            ],
        ],
        if (modulo == ModuloGestion.cierres) ...[
          tituloSeccion('RESUMEN DEL PERÍODO'),
          cuadroInformacion(
            'El sistema calculará el total y las comisiones al crear el cierre. El período no se modificará después de confirmar.',
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            modulo == ModuloGestion.reservas
                ? esEdicion
                      ? 'Guardar cambios'
                      : 'Crear reserva'
                : 'Confirmar y crear cierre',
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Volver a editar'),
        ),
      ],
    ),
  );
}
