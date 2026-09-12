import 'dart:io';

import 'package:flutter/material.dart';

import '../models/document.dart';
import '../theme/app_colors.dart';

/// A single document row/tile. Per design-spec.md §1/§3, this avoids the
/// matching-shadow-card pattern: list mode is a plain row (thumbnail +
/// name) meant to sit between hairline [Divider]s; grid mode uses a thin
/// outline instead of a filled, elevated card.
class DocumentCard extends StatelessWidget {
  const DocumentCard({
    super.key,
    required this.document,
    required this.isGrid,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  final Document document;
  final bool isGrid;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final thumbPath = document.pages.isNotEmpty ? document.pages.first.imagePathLowRes : null;
    final tagColor = document.colorTag != null ? Color(document.colorTag!) : null;
    final selectionIcon = selected ? Icons.check_circle : Icons.radio_button_unchecked;
    final selectionColor = selected ? colors.primaryInk : colors.textSecondary;

    Widget thumb({required double size, required double radius}) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: colors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: thumbPath != null && File(thumbPath).existsSync()
            ? Image.file(File(thumbPath), fit: BoxFit.cover)
            : ColoredBox(
                color: colors.backgroundPrimary,
                child: Icon(Icons.description_outlined, color: colors.textSecondary),
              ),
      );
    }

    if (isGrid) {
      return InkWell(
        borderRadius: AppRadius.radius,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadius.radius,
            border: Border.all(color: selected ? colors.primaryInk : colors.divider, width: selected ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: colors.divider),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: thumbPath != null && File(thumbPath).existsSync()
                      ? Image.file(File(thumbPath), fit: BoxFit.cover, width: double.infinity)
                      : ColoredBox(
                          color: colors.backgroundPrimary,
                          child: Icon(Icons.description_outlined, color: colors.textSecondary),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  if (tagColor != null) ...[
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: tagColor, shape: BoxShape.circle)),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Expanded(
                    child: Text(document.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  if (selectionMode) Icon(selectionIcon, size: 18, color: selectionColor),
                ],
              ),
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
            thumb(size: 48, radius: 6),
            const SizedBox(width: AppSpacing.md),
            if (tagColor != null) ...[
              Container(width: 8, height: 8, decoration: BoxDecoration(color: tagColor, shape: BoxShape.circle)),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Text(document.name, overflow: TextOverflow.ellipsis),
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
