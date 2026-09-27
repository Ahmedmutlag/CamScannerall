import 'package:flutter/material.dart';

import '../models/folder.dart';
import '../theme/app_colors.dart';

/// A single folder tile. Grid mode is a colorful pastel card (deterministic
/// color per folder, see [PastelPalette]) with a soft shadow; list mode
/// keeps the same colored icon badge but as a plain row, so a long list
/// doesn't turn into a wall of heavy cards.
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
    final (background, foreground) = folder.colorTag != null
        ? (
            Color(folder.colorTag!).withValues(alpha: 0.15),
            Color(folder.colorTag!),
          )
        : PastelPalette.forSeed(folder.id);
    final selectionIcon = selected
        ? Icons.check_circle
        : Icons.radio_button_unchecked;
    final selectionColor = selected ? colors.primaryInk : colors.textSecondary;

    if (isGrid) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.cardRadius,
          boxShadow: PastelPalette.shadow,
          border: selected
              ? Border.all(color: colors.primaryInk, width: 2)
              : null,
        ),
        child: Material(
          color: background,
          borderRadius: AppRadius.cardRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.folder_outlined,
                          color: foreground,
                          size: 20,
                        ),
                      ),
                      if (selectionMode)
                        Icon(selectionIcon, color: selectionColor),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    folder.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$documentCount',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: foreground),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.md,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: background,
              child: Icon(Icons.folder_outlined, color: foreground, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                folder.name,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              '$documentCount',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.textSecondary),
            ),
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
