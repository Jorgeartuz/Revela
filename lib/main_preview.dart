import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/preview/design_gallery.dart';

/// Entrada separada de diseño. No inicia sesión ni accede a la API.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'Revela · Vista de diseño',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      scrollBehavior: const RevelaScrollBehavior(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => Banner(
        message: 'VISTA PREVIA',
        location: BannerLocation.topEnd,
        child: child!,
      ),
      home: const DesignGallery(),
    ),
  );
}
