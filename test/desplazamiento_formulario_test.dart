import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revela/configuracion/tema_aplicacion.dart';
import 'package:revela/servicios/remoto/servicio_gestion.dart';
import 'package:revela/modelos/gestion/modulo_gestion.dart';
import 'package:revela/pantallas/gestion/pantalla_formulario.dart';

void main() {
  testWidgets(
    'Permite desplazar con ratón y tacto y mantiene Guardar visible sobre el teclado',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final servicio = ServicioGestion.vistaPrevia();
      var keyboardHeight = 0.0;
      Widget app() => MaterialApp(
        theme: TemaAplicacion.oscuro,
        locale: const Locale('es'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('es')],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(viewInsets: EdgeInsets.only(bottom: keyboardHeight)),
          child: child!,
        ),
        home: PantallaFormulario(
          modulo: ModuloGestion.clientes,
          servicio: servicio,
        ),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final guardar = find.widgetWithText(FilledButton, 'Guardar cliente');
      final listar = find.byType(ListView);
      final scroll = tester.widget<ListView>(listar).controller!;
      final initialSaveRect = tester.getRect(guardar);
      final viewport = tester.getRect(listar);
      await tester.dragFrom(
        Offset(viewport.left + 8, viewport.center.dy),
        const Offset(0, -300),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(scroll.offset, greaterThan(0));
      expect(tester.getRect(guardar), initialSaveRect);
      final afterMouse = scroll.offset;
      await tester.dragFrom(
        Offset(viewport.left + 8, viewport.center.dy),
        const Offset(0, 200),
        kind: PointerDeviceKind.touch,
      );
      await tester.pumpAndSettle();
      expect(scroll.offset, lessThan(afterMouse));
      keyboardHeight = 280;
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(
        tester.getRect(guardar).bottom,
        lessThanOrEqualTo(852 - keyboardHeight),
      );
      await tester.tap(guardar);
      await tester.pumpAndSettle();
      expect(find.textContaining('Este campo es obligatorio.'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
