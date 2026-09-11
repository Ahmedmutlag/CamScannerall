import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../app_state.dart';
import '../screens/camera_screen.dart';

/// "Quick scan & share" — skips folder/document archiving entirely and
/// goes straight from camera to the share sheet, for one-off scans the
/// user doesn't want to keep archived (spec item 45). Also used as the
/// action behind the home-screen shortcut and the Quick Settings Tile.
Future<void> runQuickScanAndShare(BuildContext context) async {
  final navigator = Navigator.of(context);
  final appState = context.read<AppState>();

  final result = await navigator.push<List<({String highRes, String lowRes})>>(
    MaterialPageRoute(builder: (_) => const CameraScreen(quickMode: true)),
  );
  if (result == null || result.isEmpty) return;

  final pdfBytes = await appState.pdf.buildPdf(result.map((p) => p.highRes).toList());
  await appState.pdf.sharePdf(pdfBytes, filename: '${const Uuid().v4().substring(0, 8)}.pdf');
}
