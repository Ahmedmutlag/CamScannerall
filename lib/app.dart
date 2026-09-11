import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'screens/lock_screen.dart';
import 'screens/splash_screen.dart';
import 'services/quick_actions_service.dart';
import 'services/quick_scan_flow.dart';
import 'services/quick_tile_channel.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class ScannerApp extends StatefulWidget {
  const ScannerApp({super.key});

  @override
  State<ScannerApp> createState() => _ScannerAppState();
}

class _ScannerAppState extends State<ScannerApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initQuickEntryPoints());
  }

  Future<void> _initQuickEntryPoints() async {
    final appState = context.read<AppState>();
    await appState.quickActions.init(onAction: (type) {
      if (type == QuickActionsService.scanActionType) _openQuickScan();
    });
    QuickTileChannel.listen(_openQuickScan);
    final pending = await QuickTileChannel.consumePendingAction();
    if (pending) _openQuickScan();
  }

  void _openQuickScan() {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null) runQuickScanAndShare(ctx);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final appState = context.read<AppState>();
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      appState.lock.markBackgrounded();
    } else if (state == AppLifecycleState.resumed) {
      final shouldLock = appState.lock.hasPin && appState.lock.shouldLockAfterIdle();
      if (shouldLock) {
        rootNavigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const LockScreen(), fullscreenDialog: true),
        );
      }
      appState.lock.markActive();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final locale = Locale(appState.db.settings.languageCode);

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: appState.strings.t('appName'),
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final seed = const Color(0xFF2F6F73);
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
