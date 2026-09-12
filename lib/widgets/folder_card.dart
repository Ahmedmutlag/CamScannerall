import 'package:flutter/material.dart';

import '../models/folder.dart';
import '../theme/app_colors.dart';

/// A single folder row. The default (list) presentation is a plain row
/// meant to be separated by a hairline [Divider] in the parent list —
/// per design-spec.md §1/§3, folders/documents are not shown as matching-
/// shadow cards. Grid mode (an explicit user preference toggle from the
/// base feature spec) keeps the same flat, borderless language: a thin
/// outline instead of a filled card.
class FolderCard extends StatelessWidget {
  const FolderCard({
    super.key,
    required this.folder,
    required this.documentCount,
    required this.isGrid,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  final Folder folder;
  final int documentCount;
  final bool isGrid;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final iconColor = folder.colorTag != null ? Color(folder.colorTag!) : colors.primaryInk;
    final selectionIcon = selected ? Icons.check_circle : Icons.radio_button_unchecked;
    final selectionColor = selected ? colors.primaryInk : colors.textSecondary;

    if (isGrid) {
      return InkWell(
        borderRadius: AppRadius.radius,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.radius,
            border: Border.all(color: selected ? colors.primaryInk : colors.divider, width: selected ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.folder_outlined, color: iconColor, size: 30),
                  if (selectionMode) Icon(selectionIcon, color: selectionColor),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(folder.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text('$documentCount',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.folder_outlined, color: iconColor, size: 26),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(folder.name, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            Text('$documentCount',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
            if (selectionMode) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(selectionIcon, color: selectionColor),
            ],
          ],
        ),
      ),
    );
  }
}
