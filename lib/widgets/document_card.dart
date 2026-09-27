import 'dart:io';

import 'package:flutter/material.dart';

import '../models/document.dart';
import '../theme/app_colors.dart';

/// A single document tile. Grid mode is a rounded card with a soft shadow
/// (the page thumbnail itself is the main visual, with a pastel-colored
/// placeholder — deterministic per document, see [PastelPalette] — when
/// there's no page yet); list mode stays a plain row between dividers.
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
    final thumbPath = document.pages.isNotEmpty
        ? document.pages.first.imagePathLowRes
        : null;
    final tagColor = document.colorTag != null
        ? Color(document.colorTag!)
        : null;
    final selectionIcon = selected
        ? Icons.check_circle
        : Icons.radio_button_unchecked;
    final selectionColor = selected ? colors.primaryInk : colors.textSecondary;
    final (placeholderBg, placeholderFg) = PastelPalette.forSeed(document.id);

    Widget placeholder() => ColoredBox(
      color: placeholderBg,
      child: Icon(Icons.description_outlined, color: placeholderFg),
    );

    Widget thumb({required double size, required double radius}) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius)),
        clipBehavior: Clip.antiAlias,
        child: thumbPath != null && File(thumbPath).existsSync()
            ? Image.file(File(thumbPath), fit: BoxFit.cover)
            : placeholder(),
      );
    }

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
          color: colors.backgroundPrimary,
          borderRadius: AppRadius.cardRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: thumbPath != null && File(thumbPath).existsSync()
                          ? Image.file(
                              File(thumbPath),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : placeholder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      if (tagColor != null) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: tagColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Expanded(
                        child: Text(
                          document.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (selectionMode)
                        Icon(selectionIcon, size: 18, color: selectionColor),
                    ],
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
            thumb(size: 48, radius: 10),
            const SizedBox(width: AppSpacing.md),
            if (tagColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: tagColor,
                  shape: BoxShape.circle,
                ),
              ),
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
