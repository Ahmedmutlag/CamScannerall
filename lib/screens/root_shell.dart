import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import 'files_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

/// Bottom-nav shell shown after unlock: Home (scan + recent), Files
/// (folders), Settings — kept to three plain tabs on purpose.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _tabs = [HomeScreen(), FilesScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().strings;
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: s.t('home')),
          NavigationDestination(icon: const Icon(Icons.folder_outlined), selectedIcon: const Icon(Icons.folder), label: s.t('files')),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: s.t('settings')),
        ],
      ),
    );
  }
}
