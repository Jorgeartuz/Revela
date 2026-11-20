import 'package:revela/widgets/gestion/componentes_operativos.dart';
import 'package:flutter/material.dart';
import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/services/remote/servicio_gestion.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/widgets/gestion/componentes_compartidos.dart';

class SeccionesReserva extends StatelessWidget {
  const SeccionesReserva({
    super.key,
    required this.registro,
    required this.servicio,
  });
  final Registro registro;
  final ServicioGestion servicio;
  @override
  Widget build(BuildContext context) {
    final client = datosAnidados(registro, 'cliente'),
        datosServicio = datosAnidados(registro, 'servicio');
    final status = estadosDelServicio(servicio)
        .label(registro['estado'] as int?);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Chip(label: Text(status ?? 'Estado sin identificar')),
        ),
        tituloSeccion('CLIENTE'),
        tarjeta(
          Column(
            children: [
              filaDato('Nombre', nombrePersona(registro['cliente'])),
              filaDato('Documento', client['documento']),
              filaDato('Celular', client['celular']),
              filaDato('Correo', client['correo']),
            ],
          ),
        ),
        tituloSeccion('SERVICIO'),
        tarjeta(
          Column(
            children: [
              filaDato('Servicio', datosServicio['nombre']),
              filaDato('Precio', formatoMoneda(datosServicio['precio'])),
              filaDato('Duración', '${datosServicio['duracion'] ?? '—'} min'),
              filaDato('Profesional', nombrePersona(registro['profesional'])),
            ],
          ),
        ),
        tituloSeccion('DATOS DE LA RESERVA'),
        tarjeta(
          Column(
            children: [
              filaDato('ID', '#RV-${registro['id']}'),
              filaDato('Fecha', formatoFecha(registro['fecha'])),
              filaDato(
                'Hora',
                '${textoHora(registro['horaInicio'])} – ${textoHora(registro['horaFin'])}',
              ),
              if (registro['fechaCreacion'] != null)
                filaDato('Creada el', formatoFecha(registro['fechaCreacion'])),
            ],
          ),
        ),
        if (status == 'CANCELADA')
          cuadroInformacion('Esta reserva figura como cancelada.'),
        if (status == 'ATENDIDA')
          cuadroInformacion('Esta reserva figura como atendida.'),
      ],
    );
  }
}

class SeccionesLiquidacion extends StatefulWidget {
  const SeccionesLiquidacion({
    super.key,
    required this.registro,
    required this.servicio,
    required this.commission,
  });
  final Registro registro;
  final ServicioGestion servicio;
  final bool commission;
  @override
  State<SeccionesLiquidacion> createState() => _EstadoSeccionesLiquidacion();
}

class _EstadoSeccionesLiquidacion extends State<SeccionesLiquidacion> {
  late Future<List<Registro>> _consulta;
  @override
  void initState() {
    super.initState();
    _consulta = widget.commission
        ? widget.servicio.serviciosDeComision(widget.registro['id'] as int)
        : widget.servicio.listar(
            ModuloGestion.comisiones,
            filtros: {'liquidacionComisionId': '${widget.registro['id']}'},
          );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.registro;
    return FutureBuilder<List<Registro>>(
      future: _consulta,
      builder: (c, s) {
        final registros = s.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.commission) ...[
              tarjeta(
                Column(
                  children: [
                    filaDato('Profesional', nombrePersona(r['profesional'])),
                    filaDato(
                      'Cierre',
                      '#CIE-${r['liquidacionComisionId'] ?? r['liquidacionId'] ?? '—'}',
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: ColoresAplicacion.principal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DefaultTextStyle(
                  style: const TextStyle(color: ColoresAplicacion.fondo),
                  child: Column(
                    children: [
                      const Text('VALOR DE COMISIÓN'),
                      const SizedBox(height: 10),
                      Text(
                        formatoMoneda(r['valorComision']),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          for (final item in [
                            ('Servicios', '${r['cantidadServicios'] ?? '—'}'),
                            ('Comisión', '${r['porcentaje'] ?? '—'}%'),
                            ('Base/total', formatoMoneda(r['base'])),
                          ])
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    item.$2,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    item.$1,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              tituloSeccion('SERVICIOS REALIZADOS EN EL CIERRE'),
              for (final servicio in registros)
                tarjeta(
                  Column(
                    children: [
                      filaDato(
                        nombrePersona(servicio['cliente']),
                        '+${formatoMoneda(servicio['valorComision'] ?? servicio['comision'])}',
                      ),
                      filaDato(
                        '${datosAnidados(servicio, 'servicio')['nombre'] ?? servicio['nombreServicio'] ?? 'Servicio'} · ${formatoFecha(servicio['fecha'])}',
                        formatoMoneda(
                          datosAnidados(servicio, 'servicio')['precio'] ??
                              servicio['precio'],
                        ),
                      ),
                    ],
                  ),
                ),
            ] else ...[
              tituloSeccion('#CIE-${r['id']}'),
              tarjeta(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'TOTAL DEL CIERRE',
                      style: TextStyle(
                        fontSize: 11,
                        color: ColoresAplicacion.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      formatoMoneda(r['totalFacturado']),
                      style: const TextStyle(
                        fontSize: 28,
                        color: ColoresAplicacion.principal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    filaDato(
                      'Comisión del negocio',
                      formatoMoneda(r['subtotalComisionNegocio']),
                    ),
                    filaDato(
                      'Comisión de profesionales',
                      formatoMoneda(r['subtotalComisionProfesionales']),
                    ),
                    resumenTotales([
                      (
                        'Servicios',
                        !s.hasData ||
                                registros.any(
                                  (registro) =>
                                      registro['cantidadServicios'] is! int,
                                )
                            ? '—'
                            : '${registros.fold<int>(0, (total, registro) => total + (registro['cantidadServicios'] as int))}',
                      ),
                      (
                        'Profesionales',
                        s.hasData ? '${registros.length}' : '—',
                      ),
                    ]),
                  ],
                ),
              ),
              tituloSeccion('PERÍODO'),
              tarjeta(
                Column(
                  children: [
                    filaDato('Desde', formatoFecha(r['fechaInicio'])),
                    filaDato('Hasta', formatoFecha(r['fechaFin'])),
                  ],
                ),
              ),
              tituloSeccion('PROFESIONALES EN ESTE CIERRE'),
              for (final person in registros)
                tarjeta(
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: ColoresAplicacion.principal,
                        foregroundColor: ColoresAplicacion.fondo,
                        child: Text(
                          iniciales(nombrePersona(person['profesional'])),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nombrePersona(person['profesional'])),
                            Text(
                              '${person['cantidadServicios'] ?? '—'} servicios',
                              style: const TextStyle(
                                fontSize: 11,
                                color: ColoresAplicacion.textoSecundario,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(formatoMoneda(person['base'])),
                    ],
                  ),
                ),
            ],
            if (s.hasError) cuadroInformacion(mensajeError(s.error)),
            if (!s.hasData && !s.hasError)
              const Center(child: CircularProgressIndicator()),
            if (s.hasData && registros.isEmpty)
              cuadroInformacion('No hay registros asociados para mostrar.'),
          ],
        );
      },
    );
  }
}
