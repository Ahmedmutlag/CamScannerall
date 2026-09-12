import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state_view.dart';
import 'document_detail_screen.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = appState.strings;
    final items = appState.db.recentActivity;
    final colors = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.t('timeline'))),
      body: items.isEmpty
          ? EmptyStateView(message: s.t('noActivity'))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => Divider(
                color: colors.divider, height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md,
              ),
              itemBuilder: (context, index) {
                final doc = items[index];
                final folder = appState.db.folderById(doc.folderId);
                final thumb = doc.pages.isNotEmpty ? doc.pages.first.imagePathLowRes : null;
                return ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colors.divider),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: thumb != null && File(thumb).existsSync()
                        ? Image.file(File(thumb), fit: BoxFit.cover)
                        : Icon(Icons.description_outlined, color: colors.textSecondary),
                  ),
                  title: Text(doc.name),
                  subtitle: Text(
                    '${folder?.name ?? ''} · ${DateFormat('yyyy-MM-dd HH:mm').format(doc.createdAt)}',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc)),
                  ),
                );
              },
            ),
    );
  }
}
