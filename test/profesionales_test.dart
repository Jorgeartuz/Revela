import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/models/login/sesion_usuario.dart';
import 'package:revela/screens/gestion/pantalla_detalle.dart';
import 'package:revela/screens/gestion/pantalla_formulario.dart';
import 'package:revela/screens/gestion/pantalla_listado.dart';
import 'package:revela/screens/inicio/pantalla_inicio.dart';
import 'package:revela/services/remote/cliente_api.dart';
import 'package:revela/services/remote/servicio_gestion.dart';
import 'package:revela/services/remote/servicio_inicio.dart';

Widget aplicacion(Widget child) => MaterialApp(
  theme: TemaAplicacion.oscuro,
  locale: const Locale('es'),
  supportedLocales: const [Locale('es')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: child,
);

void datos(ServicioGestion servicio) {
  servicio.memoria[ModuloGestion.especialidades] = [
    {'id': 1, 'nombre': 'Peinados', 'activa': true},
    {'id': 2, 'nombre': 'Barbería', 'activa': true},
    {'id': 3, 'nombre': 'Colorimetría', 'activa': true},
  ];
  servicio.memoria[ModuloGestion.profesionales] = [
    {
      'id': 1,
      'nombres': 'Camilo',
      'apellidos': 'Ruiz',
      'documento': '1102345678',
      'estado': true,
      'porcentaje': 10,
      'especialidadId': 1,
    },
    {
      'id': 2,
      'nombres': 'Maria',
      'apellidos': 'Casas',
      'documento': '369852963',
      'estado': true,
      'porcentaje': 20,
      'especialidad': 1,
    },
    {
      'id': 3,
      'nombres': 'Andrea',
      'apellidos': 'Peña',
      'documento': '258741963',
      'estado': true,
      'porcentaje': 30,
      'especialidad': {'id': 2, 'nombre': 'Barbería'},
    },
    {
      'id': 4,
      'nombres': 'Clara',
      'apellidos': 'Perez',
      'documento': '147852369',
      'estado': false,
      'porcentaje': 40,
      'especialidadId': 3,
    },
  ];
}

class ServicioEspecialidadesPrueba extends ServicioGestion {
  ServicioEspecialidadesPrueba() : super.vistaPrevia();
  bool fallar = true;
  @override
  Future<List<Map<String, dynamic>>> listar(
    ModuloGestion modulo, {
    Map<String, String> filtros = const {},
  }) {
    if (fallar && modulo == ModuloGestion.especialidades) {
      return Future.error(
        const ErrorGestion('No se cargaron las especialidades.'),
      );
    }
    return super.listar(modulo, filtros: filtros);
  }
}

void main() {
  testWidgets(
    'Profesionales combina filtros y resuelve especialidades por ID u objeto',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final servicio = ServicioGestion.vistaPrevia();
      datos(servicio);
      await tester.pumpWidget(
        aplicacion(
          PantallaListado(
            modulo: ModuloGestion.profesionales,
            servicio: servicio,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('4 PROFESIONALES  ·  3 ACTIVOS'), findsOneWidget);
      expect(find.text('Peinados'), findsNWidgets(2));
      expect(find.text('Activo'), findsNWidgets(3));
      expect(find.text('Inactivo'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Activos'));
      await tester.pumpAndSettle();
      expect(find.text('Clara Perez'), findsNothing);
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Barbería').last);
      await tester.pumpAndSettle();
      expect(find.text('Andrea Peña'), findsOneWidget);
      expect(find.text('Camilo Ruiz'), findsNothing);
      await tester.enterText(find.byType(TextField), '258741');
      await tester.pumpAndSettle();
      expect(find.text('Andrea Peña'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Inactivos'));
      await tester.pumpAndSettle();
      expect(find.text('No hay resultados para mostrar.'), findsOneWidget);
      await tester.tap(find.text('Limpiar filtros'));
      await tester.pumpAndSettle();
      expect(find.text('4 PROFESIONALES  ·  3 ACTIVOS'), findsOneWidget);
      await tester.tap(find.byTooltip('Crear profesional'));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaFormulario), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'La pestaña Profesionales muestra un encabezado y abre la ficha',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = ClienteApi(
        urlBase: Uri.parse('https://example.com'),
        client: MockClient(
          (_) async => http.Response('{"success":true,"data":[]}', 200),
        ),
      );
      addTearDown(api.close);
      final sesion = SesionUsuario(
        tokenAcceso: 'ejemplo',
        fechaVencimiento: DateTime(2100),
        nombreEmpresa: 'Revela',
        idEmpresa: 1,
        rol: 'Gestor',
      );
      final servicio = ServicioGestion.vistaPrevia();
      datos(servicio);
      await tester.pumpWidget(
        aplicacion(
          PantallaInicio(
            sesion: sesion,
            servicio: ServicioInicio(api, sesion),
            repositorioGestion: servicio,
            alCerrarSesion: () {},
            alVencerSesion: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profesionales').last);
      await tester.pumpAndSettle();
      expect(find.text('Profesionales'), findsNWidgets(2));
      await tester.tap(find.text('Camilo Ruiz'));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaDetalle), findsOneWidget);
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
      expect(find.text('Profesionales'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Profesionales permite reintentar si falla el catálogo de especialidades',
    (tester) async {
      final servicio = ServicioEspecialidadesPrueba();
      datos(servicio);
      await tester.pumpWidget(
        aplicacion(
          PantallaListado(
            modulo: ModuloGestion.profesionales,
            servicio: servicio,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No se cargaron las especialidades.'), findsOneWidget);
      servicio.fallar = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('4 PROFESIONALES  ·  3 ACTIVOS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
