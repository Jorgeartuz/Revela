import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revela/config/tema_aplicacion.dart';
import 'package:revela/models/gestion/modulo_gestion.dart';
import 'package:revela/models/inicio/reserva.dart';
import 'package:revela/screens/gestion/pantalla_formulario.dart';
import 'package:revela/screens/gestion/vistas_gestion.dart';
import 'package:revela/services/remote/servicio_gestion.dart';
import 'package:revela/widgets/agenda/agenda_administrativa.dart';

Widget aplicacion(Widget child) => MaterialApp(
  theme: TemaAplicacion.oscuro,
  locale: const Locale('es'),
  supportedLocales: const [Locale('es')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: Scaffold(body: SafeArea(child: child)),
);

void main() {
  testWidgets(
    'La agenda filtra las citas y mantiene Reserva accesible al desplazarse',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final servicio = ServicioGestion.vistaPrevia();
      final fecha = DateUtils.dateOnly(DateTime.now()).toIso8601String();
      servicio.memoria[ModuloGestion.reservas] = List.generate(
        4,
        (i) => {
          'id': i + 1,
          'fecha': fecha,
          'horaInicio': '${10 + i}:00:00',
          'estado': i,
          'cliente': {
            'nombreCompleto': ['Laura', 'Marco', 'Luisa', 'Julia'][i],
          },
          'servicio': {'nombre': 'Corte'},
          'profesional': {'nombre': 'Camilo'},
        },
      );
      await tester.pumpWidget(
        aplicacion(
          VistaGestion(
            modulo: ModuloGestion.reservas,
            servicio: servicio,
            mostrarTitulo: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Agenda'), findsOneWidget);
      expect(find.text('Reservas hoy'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Confirmada'));
      await tester.pumpAndSettle();
      expect(find.text('Marco'), findsOneWidget);
      expect(find.text('Laura'), findsNothing);
      expect(find.text('4'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Todas'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Luisa');
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == 'Luisa',
        ),
        findsOneWidget,
      );
      expect(find.text('Marco'), findsNothing);
      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pumpAndSettle();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'Luisa',
      );
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      final reserva = find.widgetWithText(FilledButton, 'Reserva');
      expect(reserva.hitTestable(), findsOneWidget);
      await tester.tap(reserva);
      await tester.pumpAndSettle();
      expect(find.byType(PantallaFormulario), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'La agenda conserva como desconocidos los estados no configurados',
    (tester) async {
      final fecha = DateUtils.dateOnly(DateTime.now());
      await tester.pumpWidget(
        aplicacion(
          AgendaAdministrativa(
            registros: [
              {
                'id': 1,
                'fecha': fecha.toIso8601String(),
                'horaInicio': '10:00:00',
                'estado': 8,
                'cliente': {'nombre': 'Laura'},
              },
            ],
            estados: const EstadosReserva(),
            fecha: fecha,
            busqueda: '',
            estadoSeleccionado: null,
            mostrarTitulo: true,
            alBuscar: (_) {},
            alFiltrar: (_) {},
            alElegirFecha: () {},
            alCrearReserva: () {},
            alAbrirReserva: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Por confirmar'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(2));
      final filtro = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Confirmada'),
      );
      expect(filtro.onSelected, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
