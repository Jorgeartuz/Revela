import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/models/login/sesion_usuario.dart';
import 'package:revela/screens/inicio/pantalla_inicio.dart';
import 'package:revela/services/remote/cliente_api.dart';
import 'package:revela/services/remote/servicio_gestion.dart';
import 'package:revela/services/remote/servicio_inicio.dart';
import 'package:revela/widgets/menu/menu_administrativo.dart';

Widget aplicacion(Widget child) => MaterialApp(
  theme: TemaAplicacion.oscuro,
  locale: const Locale('es'),
  supportedLocales: const [Locale('es')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: child,
);

void main() {
  testWidgets('Más agrupa sus seis accesos y abre el módulo correspondiente', (
    tester,
  ) async {
    final abiertos = <ModuloGestion>[];
    var cierres = 0;
    await tester.pumpWidget(
      aplicacion(
        Scaffold(
          body: MenuAdministrativo(
            alAbrirModulo: abiertos.add,
            alCerrarSesion: () => cierres++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final entrada in [
      ('Especialidades', ModuloGestion.especialidades),
      ('Servicios', ModuloGestion.servicios),
      ('Horarios', ModuloGestion.horarios),
      ('Inasistencias', ModuloGestion.inasistencias),
      ('Cierres', ModuloGestion.cierres),
      ('Comisiones', ModuloGestion.comisiones),
    ]) {
      final opcion = find.widgetWithText(ListTile, entrada.$1);
      await tester.scrollUntilVisible(
        opcion,
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(opcion);
      await tester.pumpAndSettle();
      expect(abiertos.last, entrada.$2);
    }
    await tester.scrollUntilVisible(
      find.text('Cerrar sesión'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión'));
    expect(abiertos.length, 6);
    expect(cierres, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cerrar sesión desde Más pide confirmación y respeta cancelar', (
    tester,
  ) async {
    var cierres = 0;
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
    await tester.pumpWidget(
      aplicacion(
        PantallaInicio(
          sesion: sesion,
          servicio: ServicioInicio(api, sesion),
          repositorioGestion: ServicioGestion.vistaPrevia(),
          alCerrarSesion: () => cierres++,
          alVencerSesion: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Más'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, 'Cerrar sesión'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cerrar sesión?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(cierres, 0);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(cierres, 1);
    expect(tester.takeException(), isNull);
  });
}
