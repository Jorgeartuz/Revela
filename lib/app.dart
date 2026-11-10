import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';

class RevelaApp extends StatelessWidget {
  const RevelaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Revela',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    locale: const Locale('es'),
    supportedLocales: const [Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: const LoginScreen(),
  );
}
