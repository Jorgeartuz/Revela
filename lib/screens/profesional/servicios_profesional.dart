import 'package:revela/models/profesional/datos_profesional.dart';
import 'package:revela/models/profesional/resumen_servicios.dart';

import 'package:revela/widgets/gestion/componentes_operativos.dart';
import 'package:flutter/material.dart';
import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/services/remote/servicio_gestion.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/widgets/gestion/componentes_compartidos.dart';

class ServiciosProfesional extends StatefulWidget {
  const ServiciosProfesional({
    super.key,
    required this.servicio,
    required this.idProfesional,
  });
  final ServicioGestion servicio;
  final int idProfesional;
  @override
  State<ServiciosProfesional> createState() => _EstadoServiciosProfesional();
}

class _EstadoServiciosProfesional extends State<ServiciosProfesional> {
  late Future<DatosProfesional> _consulta;
  DateTimeRange? _periodo;
  int? _servicioSeleccionado;
  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _consulta = () async {
      final perfil = await widget.servicio.obtenerProfesional(
        widget.idProfesional,
      );
      final reservas = await widget.servicio.listar(
        ModuloGestion.reservas,
        filtros: {'profesionalId': '${widget.idProfesional}'},
      );
      final servicios = await widget.servicio.listar(ModuloGestion.servicios);
      return DatosProfesional(
        perfil: perfil,
        reservas: reservas,
        servicios: servicios,
      );
    }();
  }

  Future<void> _actualizar() async {
    setState(_cargar);
    try {
      await _consulta;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _actualizar,
    child: FutureBuilder<DatosProfesional>(
      future: _consulta,
      builder: (c, s) {
        if (s.hasError) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              cuadroInformacion(mensajeError(s.error)),
              TextButton(
                onPressed: () => setState(_cargar),
                child: const Text('Reintentar'),
              ),
            ],
          );
        }
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final datos = s.data!;
        final perfil = datos.perfil;
        final reservas = datos.reservas;
        final servicios = datos.servicios;
        final atendida = estadosDelServicio(widget.servicio).atendida;
        final registros = reservas.where((r) {
          final d = DateTime.tryParse('${r['fecha']}');
          return atendida != null &&
              r['estado'] == atendida &&
              (_servicioSeleccionado == null ||
                  r['servicioId'] == _servicioSeleccionado) &&
              (_periodo == null ||
                  (d != null &&
                      !d.isBefore(_periodo!.start) &&
                      d.isBefore(_periodo!.end.add(const Duration(days: 1)))));
        }).toList();
        final porcentaje = perfil?['porcentaje'];
        final serviciosAsignados = servicios
            .where(
              (r) =>
                  perfil?['especialidadId'] != null &&
                  r['especialidadId'] == perfil?['especialidadId'],
            )
            .toList();
        final porcentajeActual = porcentaje is num ? porcentaje : null;
        final resumen = ResumenServicios.calcular(
          reservas: registros,
          serviciosIdentificados: atendida != null,
          porcentaje: porcentajeActual,
        );
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              '${perfil == null ? 'Profesional' : nombreRegistro(perfil)} · ${datosAnidados(perfil ?? {}, 'especialidad')['nombre'] ?? 'Especialidad sin informar'}',
              style: const TextStyle(
                fontSize: 12,
                color: ColoresAplicacion.textoSecundario,
              ),
            ),
            tituloSeccion('SERVICIOS DE TU ESPECIALIDAD'),
            for (final servicio in serviciosAsignados)
              tarjeta(
                Column(
                  children: [
                    filaDato(
                      '${servicio['nombre']}',
                      formatoMoneda(servicio['precio']),
                    ),
                    filaDato(
                      '${servicio['duracion']} min · ${servicio['activo'] == true ? 'Activo' : 'Inactivo'}',
                      'Comisión ${porcentaje ?? '—'}%',
                    ),
                  ],
                ),
              ),
            if (serviciosAsignados.isEmpty)
              cuadroInformacion(
                'No hay servicios de tu especialidad para mostrar.',
              ),
            tituloSeccion('SERVICIOS REALIZADOS'),
            OutlinedButton(
              onPressed: () async {
                final r = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (r != null && mounted) setState(() => _periodo = r);
              },
              child: Text(
                _periodo == null
                    ? 'Seleccionar período'
                    : '${formatoFecha(_periodo!.start)} – ${formatoFecha(_periodo!.end)}',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _servicioSeleccionado,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Servicio'),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Todos los servicios'),
                ),
                for (final r in servicios)
                  DropdownMenuItem(
                    value: r['id'] as int,
                    child: Text('${r['nombre']}'),
                  ),
              ],
              onChanged: (v) => setState(() => _servicioSeleccionado = v),
            ),
            const SizedBox(height: 16),
            if (atendida == null)
              cuadroInformacion(
                'Todavía no se dispone de información para identificar los servicios realizados.',
              )
            else if (registros.isEmpty)
              cuadroInformacion('No hay servicios atendidos en este período.'),
            for (final r in registros)
              tarjeta(
                Column(
                  children: [
                    filaDato(
                      nombrePersona(r['cliente']),
                      formatoMoneda(datosAnidados(r, 'servicio')['precio']),
                    ),
                    filaDato(
                      '${datosAnidados(r, 'servicio')['nombre']} · ${formatoFecha(r['fecha'])}',
                      '${formatoMoneda(ResumenServicios.comisionDe(r, porcentajeActual))} comisión estimada',
                    ),
                  ],
                ),
              ),
            tituloSeccion('RESUMEN DEL PERÍODO'),
            tarjeta(
              Column(
                children: [
                  filaDato(
                    'Servicios realizados',
                    '${resumen.cantidadServicios ?? '—'}',
                  ),
                  filaDato('Base total', formatoMoneda(resumen.baseTotal)),
                  filaDato(
                    'Comisión estimada',
                    formatoMoneda(resumen.comisionTotal),
                  ),
                ],
              ),
              accent: true,
            ),
            const Text(
              'La estimación utiliza los precios informados en las reservas y el porcentaje actual del profesional. La liquidación definitiva se consulta en el cierre del centro.',
              style: TextStyle(
                fontSize: 11,
                color: ColoresAplicacion.textoSecundario,
              ),
            ),
          ],
        );
      },
    ),
  );
}
