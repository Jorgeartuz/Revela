import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revela/core/theme/app_theme.dart';
import 'package:revela/features/management/data/management_repository.dart';
import 'package:revela/features/management/domain/module.dart';
import 'package:revela/features/management/presentation/record_form.dart';

void main() {
  testWidgets(
    'Mouse and touch can scroll; save stays visible above the keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = ManagementRepository.preview();
      var keyboardHeight = 0.0;
      Widget app() => MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('es'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('es')],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(viewInsets: EdgeInsets.only(bottom: keyboardHeight)),
          child: child!,
        ),
        home: RecordFormPage(module: Module.customers, repository: repository),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final save = find.widgetWithText(FilledButton, 'Guardar cliente');
      final list = find.byType(ListView);
      final scroll = tester.widget<ListView>(list).controller!;
      final initialSaveRect = tester.getRect(save);
      final viewport = tester.getRect(list);
      await tester.dragFrom(
        Offset(viewport.left + 8, viewport.center.dy),
        const Offset(0, -300),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(scroll.offset, greaterThan(0));
      expect(tester.getRect(save), initialSaveRect);
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
        tester.getRect(save).bottom,
        lessThanOrEqualTo(852 - keyboardHeight),
      );
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('Este campo es obligatorio.'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
