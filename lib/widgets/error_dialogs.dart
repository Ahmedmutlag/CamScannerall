import 'package:flutter/material.dart';

/// A blocking dialog for a failed operation, with an optional retry action —
/// used instead of a transient SnackBar for failures the user needs to
/// actively acknowledge (e.g. the scanner failing to start), per Ahmed's
/// preference for a clear "أفهمت" moment over a toast that disappears on
/// its own.
///
/// Returns true if the user tapped retry, false otherwise.
Future<bool> showErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String dismissLabel,
  String? retryLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(dismissLabel),
        ),
        if (retryLabel != null)
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(retryLabel),
          ),
      ],
    ),
  );
  return result ?? false;
}

/// Runs [action] behind a non-dismissible loading overlay, so a heavy async
/// operation (building a PDF, merging documents, exporting) always gives the
/// user visual feedback instead of leaving the screen looking frozen.
Future<T> runWithBusyOverlay<T>(
  BuildContext context,
  Future<T> Function() action,
) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    return await action();
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}
