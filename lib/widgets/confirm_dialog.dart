import 'package:flutter/material.dart';

/// A confirmation dialog shown before any permanent delete (document, page,
/// folder) — none of these previously asked before deleting, so a single
/// accidental tap could destroy data with no way back.
///
/// Returns true only if the user explicitly confirmed.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
  required String cancelLabel,
  required String deleteLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(deleteLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
