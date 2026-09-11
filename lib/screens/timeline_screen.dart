import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import 'document_detail_screen.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = appState.strings;
    final items = appState.db.recentActivity;

    return Scaffold(
      appBar: AppBar(title: Text(s.t('timeline'))),
      body: items.isEmpty
          ? Center(child: Text(s.t('noActivity')))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final doc = items[index];
                final folder = appState.db.folderById(doc.folderId);
                final thumb = doc.pages.isNotEmpty ? doc.pages.first.imagePathLowRes : null;
                return ListTile(
                  leading: thumb != null && File(thumb).existsSync()
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(File(thumb), width: 44, height: 44, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.description_outlined),
                  title: Text(doc.name),
                  subtitle: Text('${folder?.name ?? ''} · ${DateFormat('yyyy-MM-dd HH:mm').format(doc.createdAt)}'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc)),
                  ),
                );
              },
            ),
    );
  }
}
