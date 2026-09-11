import 'package:flutter/material.dart';

import '../models/folder.dart';

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
    final color = folder.colorTag != null ? Color(folder.colorTag!) : Theme.of(context).colorScheme.primaryContainer;

    final content = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: selected
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      padding: const EdgeInsets.all(14),
      child: isGrid
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.folder, color: color, size: 32),
                    if (selectionMode)
                      Icon(
                        selected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: selected ? Theme.of(context).colorScheme.primary : null,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(folder.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('$documentCount', style: Theme.of(context).textTheme.bodySmall),
              ],
            )
          : Row(
              children: [
                Icon(Icons.folder, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(folder.name, overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Text('$documentCount'),
                if (selectionMode) ...[
                  const SizedBox(width: 8),
                  Icon(
                    selected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: selected ? Theme.of(context).colorScheme.primary : null,
                  ),
                ],
              ],
            ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      onLongPress: onLongPress,
      child: content,
    );
  }
}
