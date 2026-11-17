import 'package:revela/pantallas/gestion/pantalla_operacion_exitosa.dart';
import 'package:flutter/material.dart';

import 'package:revela/pantallas/vista_previa/catalogo_figma.dart';

import 'package:revela/modelos/gestion/modulo_gestion.dart';
import 'package:revela/servicios/remoto/servicio_gestion.dart';
import 'package:revela/servicios/local/datos_ejemplo.dart';
import 'package:revela/pantallas/gestion/pantalla_listado.dart';
import 'package:revela/pantallas/gestion/pantalla_formulario.dart';
import 'package:revela/pantallas/gestion/pantalla_detalle.dart';
import 'package:revela/componentes/gestion/componentes_compartidos.dart';
import 'package:revela/pantallas/autenticacion/pantalla_recuperacion.dart';
import 'package:revela/pantallas/profesional/portal_profesional.dart';

class GaleriaPantallas extends StatefulWidget {
  const GaleriaPantallas({super.key});
  @override
  State<GaleriaPantallas> createState() => _EstadoGaleriaPantallas();
}

class _EstadoGaleriaPantallas extends State<GaleriaPantallas> {
  final repo = ServicioGestion.vistaPrevia();
  Map<String, dynamic> _ejemplo(ModuloGestion modulo) {
    if (repo.memoria[modulo]!.isEmpty) {
      repo.memoria[modulo]!.add(datosEjemplo()[modulo]!.first);
    }
    return Map<String, dynamic>.from(repo.memoria[modulo]!.first);
  }

  void _abrir(Widget page) => Navigator.push<void>(
    context,
    MaterialPageRoute(builder: (context) => page),
  );
  @override
  Widget build(BuildContext context) => SectionShell(
    title: 'Pantallas de Revela',
    vistaPrevia: true,
    child: ListView(
      padding: const EdgeInsets.all(21),
      children: [
        cuadroInformacion(
          'Esta entrada contiene datos de ejemplo. Ninguna acción modifica registros ni cuentas del servidor.',
        ),
        FilledButton.icon(
          onPressed: () => _abrir(const CatalogoFigma()),
          icon: const Icon(Icons.grid_view),
          label: const Text('Ver los 92 marcos de Figma'),
        ),
        const SizedBox(height: 16),
        tituloSeccion('MÓDULOS ADMINISTRATIVOS'),
        for (final modulo in ModuloGestion.values)
          ExpansionTile(
            title: Text(modulo.title),
            children: [
              ListTile(
                title: const Text('Listado, búsqueda y filtros'),
                onTap: () =>
                    _abrir(PantallaListado(modulo: modulo, servicio: repo)),
              ),
              if (modulo.puedeCrear)
                ListTile(
                  title: Text('Crear ${modulo.nombreSingular.toLowerCase()}'),
                  onTap: () => _abrir(
                    PantallaFormulario(modulo: modulo, servicio: repo),
                  ),
                ),
              ListTile(
                title: const Text('Detalle y acciones'),
                onTap: () => _abrir(
                  PantallaDetalle(
                    modulo: modulo,
                    registro: _ejemplo(modulo),
                    servicio: repo,
                  ),
                ),
              ),
              if (modulo.puedeEditar)
                ListTile(
                  title: const Text('Formulario de edición'),
                  onTap: () => _abrir(
                    PantallaFormulario(
                      modulo: modulo,
                      servicio: repo,
                      datosIniciales: _ejemplo(modulo),
                      esEdicion: true,
                    ),
                  ),
                ),
              ListTile(
                title: const Text('Estado sin resultados'),
                onTap: () => _abrir(
                  PantallaListado(
                    modulo: modulo,
                    servicio: repo,
                    filtrosIniciales: const {'previewEmpty': '1'},
                  ),
                ),
              ),
              if (modulo.puedeCrear)
                ListTile(
                  title: const Text('Errores de validación'),
                  onTap: () => _abrir(
                    PantallaFormulario(
                      modulo: modulo,
                      servicio: repo,
                      mostrarErrores: true,
                    ),
                  ),
                ),
            ],
          ),
        tituloSeccion('ACCESO Y RECUPERACIÓN'),
        ListTile(
          title: const Text('Splash'),
          onTap: () => _abrir(
            PantallaCargaInicial(
              child: Scaffold(
                appBar: AppBar(title: const Text('Splash completado')),
                body: Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Volver'),
                  ),
                ),
              ),
            ),
          ),
        ),
        for (final stage in {
          0: 'Recuperar acceso',
          1: 'Verificación OTP y código inválido',
          2: 'Nueva contraseña y validación',
          3: 'Contraseña actualizada (ejemplo)',
        }.entries)
          ListTile(
            title: Text(stage.value),
            onTap: () => _abrir(
              PantallaRecuperacion(vistaPrevia: true, pasoInicial: stage.key),
            ),
          ),
        tituloSeccion('PERFIL PROFESIONAL'),
        ListTile(
          title: const Text(
            'Inicio, agenda, servicios, horario e inasistencias',
          ),
          onTap: () => _abrir(
            PortalProfesional(
              servicio: repo,
              idProfesional: 1,
              usuario: 'Camilo',
              alCerrarSesion: () => Navigator.pop(context),
            ),
          ),
        ),
        tituloSeccion('ESTADOS Y CONFIRMACIONES'),
        ListTile(
          title: const Text('Operación exitosa'),
          onTap: () => _abrir(
            const PantallaOperacionExitosa(
              title: 'Registro guardado',
              message: 'Ejemplo visual de operación exitosa.',
            ),
          ),
        ),
        ListTile(
          title: const Text('Reserva cancelada'),
          onTap: () => _abrir(
            PantallaDetalle(
              modulo: ModuloGestion.reservas,
              registro: {..._ejemplo(ModuloGestion.reservas), 'estado': 3},
              servicio: repo,
            ),
          ),
        ),
        ListTile(
          title: const Text('Reserva atendida'),
          onTap: () => _abrir(
            PantallaDetalle(
              modulo: ModuloGestion.reservas,
              registro: {..._ejemplo(ModuloGestion.reservas), 'estado': 2},
              servicio: repo,
            ),
          ),
        ),
      ],
    ),
  );
}
