import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/models/login/sesion_usuario.dart';
import 'package:revela/screens/gestion/pantalla_formulario.dart';
import 'package:revela/screens/gestion/pantalla_listado.dart';
import 'package:revela/services/remote/cliente_api.dart';
import 'package:revela/services/remote/servicio_gestion.dart';

Widget aplicacion(ServicioGestion servicio) => MaterialApp(
  theme: TemaAplicacion.oscuro,
  locale: const Locale('es'),
  supportedLocales: const [Locale('es')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: PantallaListado(modulo: ModuloGestion.servicios, servicio: servicio),
);

void main() {
  testWidgets(
    'Servicios combina filtros, conserva precios y abre crear y editar',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final servicio = ServicioGestion.vistaPrevia();
      servicio.memoria[ModuloGestion.especialidades] = [
        {'id': 1, 'nombre': 'Peinados', 'activa': true},
        {'id': 2, 'nombre': 'Barbería', 'activa': true},
      ];
      servicio.memoria[ModuloGestion.servicios] = [
        {
          'id': 6,
          'nombre': 'Corte y cepillado',
          'precio': 45000,
          'duracion': 60,
          'activo': true,
          'especialidadId': 1,
        },
        {
          'id': 2,
          'nombre': 'Afeitado',
          'precio': 20000,
          'duracion': 30,
          'activo': false,
          'especialidad': {'id': 2, 'nombre': 'Barbería'},
        },
      ];
      await tester.pumpWidget(aplicacion(servicio));
      await tester.pumpAndSettle();
      expect(find.text('Servicios'), findsOneWidget);
      expect(find.text('2 SERVICIOS'), findsOneWidget);
      expect(find.text(r'$45.000'), findsOneWidget);
      expect(find.text('60 min'), findsOneWidget);
      expect(find.text('#SV-006'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Inactivos'));
      await tester.pumpAndSettle();
      expect(find.text('Afeitado'), findsOneWidget);
      expect(find.text('Corte y cepillado'), findsNothing);
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Peinados').last);
      await tester.pumpAndSettle();
      expect(find.text('No hay resultados para mostrar.'), findsOneWidget);
      await tester.tap(find.text('Limpiar filtros'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'cepillado');
      await tester.pumpAndSettle();
      expect(find.text('1 SERVICIO'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('editar-servicio-6')));
      await tester.pumpAndSettle();
      final formulario = tester.widget<PantallaFormulario>(
        find.byType(PantallaFormulario),
      );
      expect(formulario.esEdicion, isTrue);
      expect(formulario.datosIniciales?['id'], 6);
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
      expect(find.text('1 SERVICIO'), findsOneWidget);
      await tester.tap(find.byTooltip('Crear servicio'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PantallaFormulario>(find.byType(PantallaFormulario))
            .esEdicion,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final rechazar in [false, true]) {
    testWidgets(
      'El interruptor ${rechazar ? 'conserva el estado si falla' : 'guarda y recarga el estado'} sin duplicar solicitudes',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(393, 852));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var activo = true;
        final solicitudes = <http.Request>[];
        final respuesta = Completer<http.Response>();
        final api = ClienteApi(
          urlBase: Uri.parse('https://example.com'),
          client: MockClient((peticion) async {
            solicitudes.add(peticion);
            if (peticion.method == 'PUT') {
              final resultado = await respuesta.future;
              if (!rechazar) activo = false;
              return resultado;
            }
            final datos = peticion.url.path.endsWith('Especialidades')
                ? [
                    {'id': 1, 'nombre': 'Peinados'},
                  ]
                : [
                    {
                      'id': 6,
                      'nombre': 'Corte',
                      'activo': activo,
                      'precio': 45000,
                      'duracion': 60,
                      'especialidad': 1,
                    },
                  ];
            return http.Response(
              jsonEncode({'success': true, 'data': datos}),
              200,
            );
          }),
        );
        addTearDown(api.close);
        final servicio = ServicioGestion(
          api: api,
          sesion: SesionUsuario(
            tokenAcceso: 'ejemplo',
            fechaVencimiento: DateTime(2100),
            nombreEmpresa: 'Revela',
            idEmpresa: 1,
          ),
        );
        await tester.pumpWidget(aplicacion(servicio));
        await tester.pumpAndSettle();
        final interruptor = find.byKey(const ValueKey('estado-servicio-6'));
        await tester.tap(interruptor);
        await tester.pump();
        await tester.tap(interruptor);
        await tester.pump();
        expect(solicitudes.where((r) => r.method == 'PUT').length, 1);
        final solicitud = solicitudes.singleWhere((r) => r.method == 'PUT');
        expect(solicitud.url.path, '/api/Servicios/6');
        expect(jsonDecode(solicitud.body), {'activo': false});
        expect(solicitud.headers['Authorization'], 'Bearer ejemplo');
        respuesta.complete(
          http.Response(
            jsonEncode(
              rechazar
                  ? {
                      'success': false,
                      'message': 'No se permite cambiar el estado.',
                    }
                  : {'success': true, 'data': null},
            ),
            200,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(rechazar ? 'Activo' : 'Inactivo'), findsOneWidget);
        if (rechazar) {
          expect(find.text('No se permite cambiar el estado.'), findsOneWidget);
        }
        expect(find.text('Corte'), findsOneWidget);
        expect(find.text(r'$45.000'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
