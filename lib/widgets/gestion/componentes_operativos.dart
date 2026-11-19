import 'package:flutter/material.dart';
import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/services/remote/servicio_gestion.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/models/gestion/valores_registro.dart';
import 'package:revela/models/inicio/reserva.dart';

typedef Registro = Map<String, dynamic>;
EstadosReserva estadosDelServicio(ServicioGestion repo) => repo.estadosReserva;
String textoHora(Object? value) {
  final time = minutosDeHora(value);
  if (time == null) return '—';
  final hour = time ~/ 60;
  return '${hour % 12 == 0 ? 12 : hour % 12}:${(time % 60).toString().padLeft(2, '0')} ${hour < 12 ? 'AM' : 'PM'}';
}

Registro datosAnidados(Registro registro, String key) =>
    registro[key] is Map ? Map<String, dynamic>.from(registro[key] as Map) : {};
Widget tarjeta(Widget child, {bool accent = false}) => Container(
  margin: const EdgeInsets.only(bottom: 12),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: accent
        ? ColoresAplicacion.principal.withValues(alpha: .12)
        : ColoresAplicacion.superficie,
    border: Border.all(
      color: accent ? ColoresAplicacion.principal : ColoresAplicacion.borde,
    ),
    borderRadius: BorderRadius.circular(14),
  ),
  child: child,
);
Widget filaDato(String label, Object? value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 5),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
            color: ColoresAplicacion.textoSecundario,
            fontSize: 12,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          '${value ?? '—'}',
          textAlign: TextAlign.end,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    ],
  ),
);
Widget tarjetaProfesional(Registro? profile) => tarjeta(
  Row(
    children: [
      CircleAvatar(
        backgroundColor: ColoresAplicacion.principal,
        foregroundColor: ColoresAplicacion.fondo,
        child: Text(
          iniciales(profile == null ? 'Profesional' : nombreRegistro(profile)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(profile == null ? 'Profesional' : nombreRegistro(profile)),
            const SizedBox(height: 3),
            Text(
              'CC ${profile?['documento'] ?? '—'} · ${datosAnidados(profile ?? {}, 'especialidad')['nombre'] ?? 'Especialidad sin informar'}',
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
);
Widget resumenTotales(List<(String, String)> items) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    for (final item in items)
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.$2,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              if (!item.$1.contains(' '))
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.$1,
                      style: const TextStyle(
                        fontSize: 10,
                        color: ColoresAplicacion.textoSecundario,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  item.$1,
                  style: const TextStyle(
                    fontSize: 10,
                    color: ColoresAplicacion.textoSecundario,
                  ),
                ),
            ],
          ),
        ),
      ),
  ],
);
