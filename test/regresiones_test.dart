import 'package:revela/screens/gestion/pantalla_revision_datos.dart';
import 'package:revela/screens/profesional/portal_profesional.dart';
import 'package:revela/screens/gestion/pantalla_detalle.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:revela/services/remote/cliente_api.dart';
import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/models/login/sesion_usuario.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/models/gestion/datos_para_api.dart';
import 'package:revela/models/gestion/valores_registro.dart';
import 'package:revela/services/remote/servicio_gestion.dart';
import 'package:revela/screens/gestion/pantalla_formulario.dart';

Widget app(Widget home) => MaterialApp(
  theme: TemaAplicacion.oscuro,
  locale: const Locale('es'),
  supportedLocales: const [Locale('es')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: home,
);
void main() {
  test(
    'Una configuración de días inválida no rompe ni etiqueta mal la pantalla',
    () {
      for (final origen in [
        '{',
        '[]',
        'null',
        '{"lunes":1}',
        jsonEncode({
          'domingo': 0,
          'lunes': 0,
          'martes': 2,
          'miercoles': 3,
          'jueves': 4,
          'viernes': 5,
          'sabado': 6,
        }),
      ]) {
        expect(codigosDiasSemana(origen: origen), isEmpty);
      }
      expect(
        codigosDiasSemana(
          origen: jsonEncode(codigosDiasSemana(vistaPrevia: true)),
        ),
        hasLength(7),
      );
    },
  );
  test('Los filtros locales comprueban cierre, profesional y fecha', () async {
    final api = ClienteApi(
      urlBase: Uri.parse('https://example.com'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {'id': 1, 'profesionalId': 7, 'liquidacionComisionId': 10},
              {'id': 2, 'profesionalId': 7, 'liquidacionComisionId': 20},
              {'id': 3, 'profesionalId': 8, 'liquidacionComisionId': 10},
            ],
          }),
          200,
        ),
      ),
    );
    addTearDown(api.close);
    final sesion = SesionUsuario(
      tokenAcceso: 'test',
      fechaVencimiento: DateTime.now().add(const Duration(hours: 1)),
      nombreEmpresa: 'Test',
      idEmpresa: 1,
    );
    final registros = await ServicioGestion(api: api, sesion: sesion).listar(
      ModuloGestion.comisiones,
      filtros: {'profesionalId': '7', 'liquidacionComisionId': '10'},
    );
    expect(registros.map((r) => r['id']), [1]);
    expect(
      filtrarRegistros(
        ModuloGestion.reservas,
        [
          {'id': 1, 'fecha': '2026-11-10', 'horaInicio': '08:00:00'},
          {'id': 2, 'fecha': '2026-11-10', 'horaInicio': '15:00:00'},
          {'id': 3, 'fecha': '2026-11-11', 'horaInicio': '15:00:00'},
        ],
        {
          'fechaInicio': '2026-11-10T14:00:00',
          'fechaFin': '2026-11-10T23:59:59',
        },
      ).map((r) => r['id']),
      [2],
    );
  });
  test(
    'La galería conserva copias, especialidades e historial de cancelaciones',
    () async {
      final repo = ServicioGestion.vistaPrevia();
      final read = await repo.listar(ModuloGestion.reservas);
      (read.first['cliente'] as Map)['nombres'] = 'Changed';
      expect(
        (repo.memoria[ModuloGestion.reservas]!.first['cliente']
            as Map)['nombres'],
        isNot('Changed'),
      );
      await repo.guardar(ModuloGestion.profesionales, {
        'nombres': 'Nuevo',
        'especialidad': 1,
        'estado': true,
      });
      expect(
        (repo.memoria[ModuloGestion.profesionales]!.last['especialidad']
            as Map)['nombre'],
        isNotEmpty,
      );
      await repo.eliminar(
        ModuloGestion.reservas,
        1,
        body: {'motivoOtro': 'Prueba'},
      );
      expect(repo.memoria[ModuloGestion.reservas]!.first['estado'], 3);
      expect(
        repo.memoria[ModuloGestion.reservas]!.first['motivoOtro'],
        'Prueba',
      );
    },
  );
  test('Compara las horas válidas y rechaza horas fuera de rango', () {
    expect(
      prepararDatosEnvio(ModuloGestion.horarios, {
        'profesionalId': 1,
        'dia': 'lunes',
        'horaInicio': '9:00',
        'horaFin': '17:00',
        'tieneAlmuerzo': false,
      }, vistaPrevia: true)['diaSemana'],
      1,
    );
    expect(
      () => prepararDatosEnvio(ModuloGestion.horarios, {
        'profesionalId': 1,
        'dia': 'lunes',
        'horaInicio': '25:00',
        'horaFin': '17:00',
      }, vistaPrevia: true),
      throwsA(isA<ErrorGestion>()),
    );
  });
  testWidgets('La edición permite borrar datos de contacto opcionales', (
    tester,
  ) async {
    final requests = <http.Request>[];
    final api = ClienteApi(
      urlBase: Uri.parse('https://example.com'),
      client: MockClient((r) async {
        requests.add(r);
        return http.Response('{"success":true,"data":null}', 200);
      }),
    );
    addTearDown(api.close);
    final repo = ServicioGestion(
      api: api,
      sesion: SesionUsuario(
        tokenAcceso: 'test',
        fechaVencimiento: DateTime.now().add(const Duration(hours: 1)),
        nombreEmpresa: 'Test',
        idEmpresa: 1,
      ),
    );
    await tester.pumpWidget(
      app(
        PantallaFormulario(
          modulo: ModuloGestion.clientes,
          servicio: repo,
          esEdicion: true,
          datosIniciales: {
            'id': 1,
            'documento': '100000001',
            'nombres': 'Cliente',
            'apellidos': 'Prueba',
            'correo': 'correo@revela.test',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('correo')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byKey(const ValueKey('correo')), '');
    await tester.tap(find.text('Guardar cliente'));
    await tester.pumpAndSettle();
    expect(requests, hasLength(1));
    expect(jsonDecode(requests.single.body), containsPair('correo', null));
  });
  testWidgets('La edición de inasistencias recupera fechas y motivo', (
    tester,
  ) async {
    final repo = ServicioGestion.vistaPrevia();
    await tester.pumpWidget(
      app(
        PantallaFormulario(
          modulo: ModuloGestion.inasistencias,
          servicio: repo,
          esEdicion: true,
          datosIniciales: {
            'id': 1,
            'fechaInicio': '2026-11-10',
            'fechaFin': '2026-11-12',
            'motivo': 1,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Familiar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final reason = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Familiar'),
    );
    expect(reason.selected, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Las pulsaciones repetidas abren una sola revisión de reserva', (
    tester,
  ) async {
    final repo = ServicioGestion.vistaPrevia();
    final tomorrow = DateTime.now()
        .add(const Duration(days: 1))
        .toIso8601String();
    await tester.pumpWidget(
      app(
        PantallaFormulario(
          modulo: ModuloGestion.reservas,
          servicio: repo,
          datosIniciales: {
            'clienteId': 1,
            'servicioId': 1,
            'fecha': tomorrow,
            'horaInicio': '10:00:00',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Confirmar Reserva'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirmar Reserva'),
    );
    button.onPressed!();
    button.onPressed!();
    await tester.pumpAndSettle();
    expect(
      find.byType(PantallaRevisionDatos, skipOffstage: false),
      findsOneWidget,
    );
  });
  testWidgets('El inicio profesional carga el perfil vinculado a la sesión', (
    tester,
  ) async {
    final repo = ServicioGestion.vistaPrevia();
    repo.memoria[ModuloGestion.profesionales]!.add({
      'id': 2,
      'nombres': 'Sofía',
      'apellidos': 'Prueba',
      'porcentaje': 15,
    });
    await tester.pumpWidget(
      app(
        PortalProfesional(
          servicio: repo,
          idProfesional: 2,
          usuario: 'Usuario',
          alCerrarSesion: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sofía Prueba'), findsOneWidget);
    expect(find.text('Camilo Ruiz'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'La asistencia de ejemplo persiste y permite volver a la agenda',
    (tester) async {
      final repo = ServicioGestion.vistaPrevia();
      final registro = (await repo.listar(ModuloGestion.reservas)).first;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PantallaDetalle(
                      modulo: ModuloGestion.reservas,
                      registro: registro,
                      servicio: repo,
                    ),
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Confirmar asistencia'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Confirmar asistencia'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(repo.memoria[ModuloGestion.reservas]!.first['estado'], 2);
      expect(find.text('Abrir'), findsOneWidget);
    },
  );
}
