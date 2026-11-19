import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/models/clientes/cliente.dart';
import 'package:revela/models/gestion/datos_para_api.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/models/navegacion/argumentos_gestion.dart';
import 'package:revela/screens/gestion/pantalla_formulario.dart';
import 'package:revela/screens/gestion/pantalla_revision_datos.dart';
import 'package:revela/screens/pantalla_ruta_no_disponible.dart';
import 'package:revela/routes/rutas_aplicacion.dart';
import 'package:revela/services/remote/servicio_gestion.dart';

void main() {
  test(
    'El modelo de cliente conserva los datos y permite borrar el contacto',
    () {
      final cliente = Cliente.fromJson({
        'id': 7,
        'documento': '12345',
        'nombres': 'Laura',
        'apellidos': 'Prueba',
        'fechaNacimiento': '2000-05-20',
        'celular': '3001234567',
        'correo': null,
      });
      expect(cliente.id, 7);
      expect(cliente.toJson().containsKey('id'), isFalse);
      final datos = prepararDatosEnvio(ModuloGestion.clientes, {
        'documento': cliente.documento,
        'nombres': cliente.nombres,
        'apellidos': cliente.apellidos,
        'fechaNacimiento': cliente.fechaNacimiento,
        'celular': null,
        'correo': null,
      }, esEdicion: true);
      expect(datos['fechaNacimiento'], '2000-05-20');
      expect(datos.containsKey('celular'), isTrue);
      expect(datos['celular'], isNull);
      expect(datos.containsKey('correo'), isTrue);
      expect(datos['correo'], isNull);
      expect(datos.containsKey('id'), isFalse);
    },
  );

  test(
    'La solicitud de reserva respeta las diferencias entre crear y editar',
    () {
      final valores = {
        'clienteId': 7,
        'servicioId': 9,
        'profesionalId': 3,
        'fechaDia': '2030-12-10',
        'hora': '10:00:00',
      };
      final nueva = prepararDatosEnvio(ModuloGestion.reservas, valores);
      expect(nueva, {
        'clienteId': 7,
        'servicioId': 9,
        'fecha': '2030-12-10T10:00:00.000',
      });
      final editada = prepararDatosEnvio(
        ModuloGestion.reservas,
        valores,
        esEdicion: true,
      );
      expect(editada['profesionalId'], 3);
      expect(editada.containsKey('fechaDia'), isFalse);
      expect(editada.containsKey('hora'), isFalse);
    },
  );

  testWidgets(
    'Las rutas reciben argumentos tipados y manejan argumentos inválidos',
    (tester) async {
      final servicio = ServicioGestion.vistaPrevia();
      await tester.pumpWidget(
        MaterialApp(
          theme: TemaAplicacion.oscuro,
          onGenerateRoute: RutasAplicacion.generarRuta,
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      RutasAplicacion.formularioGestion,
                      arguments: {'id': 7},
                    ),
                    child: const Text('Ruta inválida'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      RutasAplicacion.formularioGestion,
                      arguments: ArgumentosFormulario(
                        modulo: ModuloGestion.clientes,
                        servicio: servicio,
                      ),
                    ),
                    child: const Text('Ruta válida'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ruta inválida'));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaRutaNoDisponible), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ruta válida'));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaFormulario), findsOneWidget);
      final contexto = tester.element(find.byType(PantallaFormulario));
      expect(
        ModalRoute.of(contexto)!.settings.name,
        RutasAplicacion.formularioGestion,
      );
      expect(
        ModalRoute.of(contexto)!.settings.arguments,
        isA<ArgumentosFormulario>(),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Los selectores de cliente y servicio guardan IDs enteros en una cita',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final servicio = ServicioGestion.vistaPrevia();
      servicio.memoria[ModuloGestion.clientes] = [
        {'id': 7, 'nombres': 'Laura', 'apellidos': 'Prueba'},
      ];
      servicio.memoria[ModuloGestion.servicios] = [
        {'id': 9, 'nombre': 'Peinado', 'precio': 20000, 'duracion': 30},
      ];
      final cantidad = servicio.memoria[ModuloGestion.reservas]!.length;
      await tester.pumpWidget(
        MaterialApp(
          theme: TemaAplicacion.oscuro,
          locale: const Locale('es'),
          supportedLocales: const [Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: PantallaFormulario(
            modulo: ModuloGestion.reservas,
            servicio: servicio,
            datosIniciales: const {
              'fecha': '2030-12-10',
              'horaInicio': '10:00:00',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Laura Prueba').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Peinado').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Confirmar Reserva'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar Reserva'));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaRevisionDatos), findsOneWidget);
      expect(find.text('Laura Prueba'), findsOneWidget);
      expect(find.text('Peinado'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Confirmar y crear reserva'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar y crear reserva'));
      await tester.pumpAndSettle();
      expect(servicio.memoria[ModuloGestion.reservas]!.length, cantidad + 1);
      expect(servicio.memoria[ModuloGestion.reservas]!.last['clienteId'], 7);
      expect(servicio.memoria[ModuloGestion.reservas]!.last['servicioId'], 9);
      expect(tester.takeException(), isNull);
    },
  );
}
