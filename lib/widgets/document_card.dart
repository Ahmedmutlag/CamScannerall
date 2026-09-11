import 'dart:io';

import 'package:flutter/material.dart';

import '../models/document.dart';

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
    final thumbPath = document.pages.isNotEmpty ? document.pages.first.imagePathLowRes : null;
    final color = document.colorTag != null ? Color(document.colorTag!) : null;

    final thumb = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: thumbPath != null && File(thumbPath).existsSync()
          ? Image.file(File(thumbPath), fit: BoxFit.cover)
          : Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.description_outlined, size: 32),
            ),
    );

    final container = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: isGrid
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: thumb),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      if (color != null) ...[
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(document.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (selectionMode)
                        Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked, size: 18),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                SizedBox(width: 56, height: 56, child: thumb),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(document.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
                if (selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked),
                  ),
              ],
            ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      onLongPress: onLongPress,
      child: container,
    );
  }
}
