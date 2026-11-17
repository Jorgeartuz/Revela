import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:revela/servicios/remoto/cliente_api.dart';
import 'package:revela/configuracion/tema_aplicacion.dart';
import 'package:revela/modelos/login/sesion_usuario.dart';
import 'package:revela/modelos/login/rol_usuario.dart';
import 'package:revela/servicios/remoto/servicio_inicio.dart';
import 'package:revela/servicios/remoto/servicio_gestion.dart';
import 'package:revela/pantallas/inicio/pantalla_inicio.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

SesionUsuario sesion(String? rol) => SesionUsuario(
  tokenAcceso: 'test',
  fechaVencimiento: DateTime.now().add(const Duration(hours: 1)),
  nombreEmpresa: 'Prueba',
  idEmpresa: 1,
  rol: rol,
);

void main() {
  test(
    'Solo Gestor abre la administración; el profesional requiere confirmación',
    () {
      expect(PoliticaRoles.resolver('Gestor'), RolUsuario.administrador);
      expect(PoliticaRoles.resolver('otro'), RolUsuario.noAdmitido);
      expect(PoliticaRoles.resolver(null), RolUsuario.noAdmitido);
      expect(PoliticaRoles.resolver('Profesional'), RolUsuario.noAdmitido);
      expect(
        PoliticaRoles.resolver('Estilista', profesional: 'Estilista'),
        RolUsuario.profesional,
      );
    },
  );

  for (final width in [320.0, 393.0]) {
    testWidgets('Panel administrativo y navegación sin desbordes a $width px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = ClienteApi(
        urlBase: Uri.parse('https://example.com'),
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer test');
          return http.Response('{"success":true,"data":[]}', 200);
        }),
      );
      addTearDown(api.close);
      final account = sesion('Gestor');
      await tester.pumpWidget(
        MaterialApp(
          theme: TemaAplicacion.oscuro,
          locale: const Locale('es'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('es')],
          home: PantallaInicio(
            sesion: account,
            alCerrarSesion: () {},
            alVencerSesion: () {},
            servicio: ServicioInicio(api, account),
            repositorioGestion: ServicioGestion.vistaPrevia(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Accesos rápidos'), findsOneWidget);
      expect(find.text('Reservas hoy'), findsOneWidget);
      expect(find.text('Has iniciado sesión correctamente.'), findsNothing);
      await tester.tap(find.text('Agenda'));
      await tester.pumpAndSettle();
      expect(find.text('Agenda'), findsWidgets);
      await tester.tap(find.text('Clientes'));
      await tester.pumpAndSettle();
      expect(find.text('Buscar por nombre o documento...'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Un rol desconocido no consulta datos administrativos', (
    tester,
  ) async {
    var requests = 0;
    final api = ClienteApi(
      urlBase: Uri.parse('https://example.com'),
      client: MockClient((_) async {
        requests++;
        return http.Response('', 403);
      }),
    );
    addTearDown(api.close);
    final account = sesion('Desconocido');
    await tester.pumpWidget(
      MaterialApp(
        home: PantallaInicio(
          sesion: account,
          alCerrarSesion: () {},
          alVencerSesion: () {},
          servicio: ServicioInicio(api, account),
          repositorioGestion: ServicioGestion.vistaPrevia(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Tu cuenta no tiene un perfil habilitado en la aplicación.'),
      findsOneWidget,
    );
    expect(find.text('Accesos rápidos'), findsNothing);
    expect(requests, 0);
  });
}
