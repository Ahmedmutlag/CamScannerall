import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/document.dart';
import '../theme/app_colors.dart';

/// A single row in the Home tab's "Recent" list: thumbnail, name, page
/// count and date, with inline quick actions — matches the flat
/// recent-documents pattern of typical scanner apps (thumbnail + a couple
/// of one-tap actions) rather than requiring a trip into the document's
/// full detail screen just to view, convert, or share it.
class RecentDocumentTile extends StatelessWidget {
  const RecentDocumentTile({
    super.key,
    required this.document,
    required this.viewLabel,
    required this.toWordLabel,
    required this.shareLabel,
    required this.onTap,
    required this.onView,
    required this.onToWord,
    required this.onShare,
  });

  final Document document;
  final String viewLabel;
  final String toWordLabel;
  final String shareLabel;
  final VoidCallback onTap;
  final VoidCallback onView;
  final VoidCallback onToWord;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final thumbPath = document.pages.isNotEmpty ? document.pages.first.imagePathLowRes : null;
    final tagColor = document.colorTag != null ? Color(document.colorTag!) : null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.divider),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: thumbPath != null && File(thumbPath).existsSync()
                      ? Image.file(File(thumbPath), fit: BoxFit.cover)
                      : ColoredBox(
                          color: colors.backgroundPrimary,
                          child: Icon(Icons.description_outlined, color: colors.textSecondary),
                        ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (tagColor != null) ...[
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: tagColor, shape: BoxShape.circle)),
                            const SizedBox(width: AppSpacing.xs),
                          ],
                          Expanded(
                            child: Text(
                              document.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${document.pages.length} · ${DateFormat('yyyy-MM-dd HH:mm').format(document.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(child: _actionButton(context, Icons.visibility_outlined, viewLabel, onView)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: _actionButton(context, Icons.description_outlined, toWordLabel, onToWord)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: _actionButton(context, Icons.share_outlined, shareLabel, onShare)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final colors = AppColors.of(context);
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.textPrimary,
        side: BorderSide(color: colors.divider),
        padding: const EdgeInsets.symmetric(vertical: 6),
      ),
    );
  }
}
