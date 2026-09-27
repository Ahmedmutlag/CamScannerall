import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../widgets/confirm_dialog.dart';
import 'home_screen.dart';
import 'print_documents_screen.dart';

/// Bottom-nav shell: Home (scan + recent + files/settings access) and
/// Print Documents — kept to two sections on purpose. Files and Settings
/// live one tap into Home rather than as their own tabs.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  // Print Documents deliberately never persists anything (see its own
  // doc comment), so exiting the app while it holds scanned-but-unsaved
  // pages would silently destroy them — this is watched below to warn
  // before letting the back button close the app in that case.
  final ValueNotifier<bool> _printHasUnsavedData = ValueNotifier(false);

  late final _tabs = [const HomeScreen(), PrintDocumentsScreen(hasUnsavedData: _printHasUnsavedData)];

  @override
  void dispose() {
    _printHasUnsavedData.dispose();
    super.dispose();
  }

  Future<void> _confirmExit() async {
    final s = context.read<AppState>().strings;
    final confirmed = await confirmDelete(
      context,
      title: s.t('exitWithUnsavedTitle'),
      message: s.t('exitWithUnsavedBody'),
      cancelLabel: s.t('cancel'),
      deleteLabel: s.t('exitAnyway'),
    );
    if (confirmed) SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().strings;
    return ValueListenableBuilder<bool>(
      valueListenable: _printHasUnsavedData,
      builder: (context, hasUnsavedData, child) => PopScope(
        canPop: !hasUnsavedData,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _confirmExit();
        },
        child: child!,
      ),
      child: Scaffold(
        body: IndexedStack(index: _index, children: _tabs),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: s.t('home')),
            NavigationDestination(icon: const Icon(Icons.print_outlined), selectedIcon: const Icon(Icons.print), label: s.t('printDocuments')),
          ],
        ),
      ),
    );
  }
}
