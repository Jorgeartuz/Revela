import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/models/gestion/datos_para_api.dart';
import 'package:revela/models/login/sesion_usuario.dart';
import 'package:revela/services/remote/cliente_api.dart';
import 'package:revela/screens/gestion/pantalla_formulario.dart';
import 'package:revela/screens/gestion/pantalla_revision_datos.dart';
import 'package:revela/screens/gestion/pantalla_operacion_exitosa.dart';
import 'package:revela/services/remote/servicio_gestion.dart';

void main() {
  test(
    'Una cita sin fecha u hora devuelve un mensaje y no un error de tipos',
    () {
      for (final datos in [
        <String, dynamic>{},
        {'fechaDia': '2030-12-10'},
        {'fechaDia': '2030-12-10', 'hora': '25:00:00'},
        {'fechaDia': 'incorrecta', 'hora': '10:00:00'},
      ]) {
        expect(
          () => prepararDatosEnvio(ModuloGestion.reservas, datos),
          throwsA(isA<ErrorGestion>()),
        );
      }
    },
  );

  test(
    'Conserva el motivo de rechazo aunque la API responda HTTP 200',
    () async {
      final api = ClienteApi(
        urlBase: Uri.parse('https://example.com'),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': false,
              'message': 'El horario está ocupado.',
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
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
      await expectLater(
        servicio.guardar(ModuloGestion.reservas, {}),
        throwsA(
          isA<ErrorGestion>().having(
            (error) => error.message,
            'motivo',
            'El horario está ocupado.',
          ),
        ),
      );
    },
  );

  testWidgets('Conserva la cita rechazada y permite corregirla y guardar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final envios = <Map<String, dynamic>>[];
    final api = ClienteApi(
      urlBase: Uri.parse('https://example.com'),
      client: MockClient((solicitud) async {
        Object cuerpo;
        var estado = 200;
        if (solicitud.method == 'POST') {
          expect(solicitud.url.path, '/api/Reservas');
          expect(solicitud.headers['Authorization'], 'Bearer ejemplo');
          envios.add(jsonDecode(solicitud.body) as Map<String, dynamic>);
          estado = envios.length == 1 ? 409 : 201;
          cuerpo = envios.length == 1
              ? {
                  'message':
                      'No hay profesionales disponibles para ese horario.',
                }
              : {
                  'success': true,
                  'data': {'id': 100},
                };
        } else {
          cuerpo = {
            'success': true,
            'data': solicitud.url.path == '/api/Clientes'
                ? [
                    {'id': 7, 'nombres': 'Ana', 'apellidos': 'Prueba'},
                  ]
                : [
                    {
                      'id': 9,
                      'nombre': 'Corte',
                      'precio': 20000,
                      'duracion': 30,
                    },
                  ],
          };
        }
        return http.Response(
          jsonEncode(cuerpo),
          estado,
          headers: {'content-type': 'application/json; charset=utf-8'},
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
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaAplicacion.oscuro,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              child: const Text('Crear cita de prueba'),
              onPressed: () => Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => PantallaFormulario(
                    modulo: ModuloGestion.reservas,
                    servicio: servicio,
                    datosIniciales: const {
                      'clienteId': 7,
                      'servicioId': 9,
                      'fecha': '2030-12-10',
                      'horaInicio': '10:00:00',
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear cita de prueba'));
    await tester.pumpAndSettle();
    Future<void> confirmar() async {
      await tester.scrollUntilVisible(
        find.text('Confirmar Reserva'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar Reserva'));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaRevisionDatos), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Confirmar y crear reserva'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar y crear reserva'));
      await tester.pumpAndSettle();
    }

    await confirmar();
    expect(
      find.text('No hay profesionales disponibles para ese horario.'),
      findsOneWidget,
    );
    expect(find.byType(PantallaOperacionExitosa), findsNothing);
    expect(envios.single, {
      'clienteId': 7,
      'servicioId': 9,
      'fecha': '2030-12-10T10:00:00.000',
    });
    await confirmar();
    expect(envios.length, 2);
    expect(envios.last, envios.first);
    expect(find.byType(PantallaOperacionExitosa), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.byType(PantallaFormulario), findsNothing);
    expect(find.text('Crear cita de prueba'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'No confirma una cita si faltan selecciones fuera de la pantalla',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: TemaAplicacion.oscuro,
          locale: const Locale('es'),
          supportedLocales: const [Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: PantallaFormulario(
            modulo: ModuloGestion.reservas,
            servicio: ServicioGestion.vistaPrevia(),
            datosIniciales: const {
              'fecha': '2030-12-10',
              'horaInicio': '10:00:00',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Confirmar Reserva'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar Reserva'));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaRevisionDatos), findsNothing);
      expect(find.textContaining('Cliente:'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Consultar disponibilidad'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Consultar disponibilidad'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Selecciona un servicio y una fecha para consultar disponibilidad.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
