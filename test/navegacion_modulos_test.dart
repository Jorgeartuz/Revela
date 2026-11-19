import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/models/login/sesion_usuario.dart';
import 'package:revela/screens/inicio/pantalla_inicio.dart';
import 'package:revela/screens/profesional/portal_profesional.dart';
import 'package:revela/services/remote/cliente_api.dart';
import 'package:revela/services/remote/servicio_gestion.dart';
import 'package:revela/services/remote/servicio_inicio.dart';

Widget aplicacion(Widget pantalla) => MaterialApp(
  theme: TemaAplicacion.oscuro,
  locale: const Locale('es'),
  supportedLocales: const [Locale('es')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: pantalla,
);

void main() {
  for (final modulo in [
    ModuloGestion.especialidades,
    ModuloGestion.servicios,
    ModuloGestion.profesionales,
    ModuloGestion.clientes,
    ModuloGestion.cierres,
    ModuloGestion.horarios,
    ModuloGestion.inasistencias,
    ModuloGestion.comisiones,
  ]) {
    testWidgets('Vuelve de ${modulo.title} y actualiza el inicio sin errores', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var consultas = 0;
      final api = ClienteApi(
        urlBase: Uri.parse('https://example.com'),
        client: MockClient((_) async {
          consultas++;
          return http.Response('{"success":true,"data":[]}', 200);
        }),
      );
      addTearDown(api.close);
      final sesion = SesionUsuario(
        tokenAcceso: 'ejemplo',
        fechaVencimiento: DateTime(2100),
        nombreEmpresa: 'Revela',
        idEmpresa: 1,
        rol: 'Gestor',
      );
      await tester.pumpWidget(
        aplicacion(
          PantallaInicio(
            sesion: sesion,
            alCerrarSesion: () {},
            alVencerSesion: () {},
            servicio: ServicioInicio(api, sesion),
            repositorioGestion: ServicioGestion.vistaPrevia(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(consultas, 1);
      if (modulo == ModuloGestion.profesionales ||
          modulo == ModuloGestion.clientes) {
        await tester.tap(find.text(modulo.title).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Inicio').last);
        await tester.pumpAndSettle();
        expect(find.text('Accesos rápidos'), findsOneWidget);
        expect(tester.takeException(), isNull);
        return;
      }
      await tester.tap(find.text('Más'));
      await tester.pumpAndSettle();
      final enlace = find.widgetWithText(
        ListTile,
        modulo == ModuloGestion.horarios ? 'Horarios' : modulo.title,
      );
      await tester.scrollUntilVisible(
        enlace,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(enlace);
      await tester.pumpAndSettle();
      if (modulo == ModuloGestion.servicios) {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(find.byType(BackButton).first);
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(consultas, 2);
      await tester.tap(find.text('Inicio').last);
      await tester.pumpAndSettle();
      expect(find.text('Accesos rápidos'), findsOneWidget);
      await tester.tap(find.text('Más'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        enlace,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(enlace);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inicio').last);
      await tester.pumpAndSettle();
      expect(find.text('Accesos rápidos'), findsOneWidget);
      expect(consultas, 3);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'El inicio profesional se actualiza sin devolver un Future a setState',
    (tester) async {
      final servicio = ServicioGestion.vistaPrevia();
      await tester.pumpWidget(
        aplicacion(
          PortalProfesional(
            servicio: servicio,
            idProfesional: 1,
            alCerrarSesion: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final estado = tester.state<RefreshIndicatorState>(
        find.byType(RefreshIndicator),
      );
      final actualizacion = estado.show();
      await tester.pumpAndSettle();
      await actualizacion;
      expect(tester.takeException(), isNull);
      expect(find.byType(PortalProfesional), findsOneWidget);
    },
  );
}
