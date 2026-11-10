import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/config/api_config.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/domain/auth_session.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/home/data/dashboard_repository.dart';

class RevelaApp extends StatefulWidget {
  const RevelaApp({
    super.key,
    this.authRepository,
    this.dashboardRepositoryFactory,
  });
  final AuthRepository? authRepository;
  final DashboardRepository Function(AuthSession)? dashboardRepositoryFactory;
  @override
  State<RevelaApp> createState() => _RevelaAppState();
}

class _RevelaAppState extends State<RevelaApp> with WidgetsBindingObserver {
  ApiClient? _ownedApi;
  late final AuthRepository _auth;
  AuthSession? _session;
  Timer? _expiry;
  final _navigatorKey = GlobalKey<NavigatorState>();
  String? _loginNotice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth =
        widget.authRepository ??
        AuthRepository(
          _ownedApi = ApiClient(baseUrl: Uri.parse(ApiConfig.baseUrl)),
        );
  }

  void _signedIn(AuthSession session) {
    if (!mounted) return;
    _expiry?.cancel();
    if (session.isExpired) {
      _logout(expired: true);
      return;
    }
    setState(() {
      _session = session;
      _loginNotice = null;
    });
    _expiry = Timer(
      session.expiresAt.difference(DateTime.now()),
      () => _logout(expired: true),
    );
  }

  void _logout({bool expired = false}) {
    if (!mounted) return;
    _expiry?.cancel();
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    setState(() {
      _session = null;
      _loginNotice = expired
          ? 'Tu sesión ha vencido. Inicia sesión nuevamente.'
          : null;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && (_session?.isExpired ?? false)) {
      _logout(expired: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _expiry?.cancel();
    _ownedApi?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Revela',
    navigatorKey: _navigatorKey,
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    locale: const Locale('es'),
    supportedLocales: const [Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: _session == null
        ? LoginScreen(
            repository: _auth,
            onSignedIn: _signedIn,
            notice: _loginNotice,
          )
        : HomeScreen(
            session: _session!,
            repository: widget.dashboardRepositoryFactory?.call(_session!),
            onLogout: _logout,
            onSessionExpired: () => _logout(expired: true),
          ),
  );
}
