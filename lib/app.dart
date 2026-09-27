import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

class ScannerApp extends StatelessWidget {
  const ScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final locale = Locale(appState.db.settings.languageCode);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appState.strings.t('appName'),
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.build(languageCode: appState.db.settings.languageCode),
      home: const SplashScreen(),
    );
  }
}
