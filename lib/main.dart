import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.init();
  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const ScannerApp(),
    ),
  );
}
