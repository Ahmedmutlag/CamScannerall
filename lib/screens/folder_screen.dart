import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/document.dart';
import '../models/folder.dart';
import '../widgets/document_card.dart';
import 'camera_screen.dart';
import 'document_detail_screen.dart';

class FolderScreen extends StatefulWidget {
  const FolderScreen({super.key, required this.folder});

  final Folder folder;

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  Future<void> _addDocument() async {
    final result = await Navigator.of(context).push<List<({String highRes, String lowRes})>>(
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
    if (result == null || result.isEmpty || !mounted) return;

    final appState = context.read<AppState>();
    final (doc, duplicate) = await appState.createDocumentFromPages(
      folderId: widget.folder.id,
      pages: result,
    );

    if (duplicate != null && mounted) {
      final s = appState.strings;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(s.t('duplicateFound')),
          content: Text('${s.t('duplicateBody')}\n\n"${duplicate.name}"'),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(context), child: Text(s.t('ok'))),
          ],
        ),
      );
    }

    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc)));
    }
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final appState = context.read<AppState>();
    for (final id in _selectedIds) {
      final doc = appState.db.documentById(id);
      if (doc != null) await appState.deleteDocument(doc);
    }
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _moveOrCopySelected({required bool move}) async {
    final appState = context.read<AppState>();
    final s = appState.strings;
    final folders = appState.db.allFolders.where((f) => f.id != widget.folder.id).toList();
    if (folders.isEmpty) return;
    final target = await showDialog<Folder>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(move ? s.t('move') : s.t('copy')),
        children: folders
            .map((f) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, f),
                  child: Text(f.name),
                ))
            .toList(),
      ),
    );
    if (target == null) return;
    for (final id in _selectedIds) {
      final doc = appState.db.documentById(id);
      if (doc == null) continue;
      if (move) {
        await appState.moveDocumentToFolder(doc, target.id);
      } else {
        await appState.copyDocumentToFolder(doc, target.id);
      }
    }
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _exportBatch(List<Document> docs) async {
    final appState = context.read<AppState>();
    final files = <String, Uint8List>{};
    for (final doc in docs) {
      final bytes = await appState.pdf.buildPdf(doc.pages.map((p) => p.imagePathHighRes).toList());
      files['${doc.name}.pdf'] = bytes;
    }
    final zip = appState.export.buildZip(files);
    await appState.share.shareBytes(zip, 'export.zip', mimeType: 'application/zip');
  }

  Future<void> _exportIndex(List<Document> docs) async {
    final appState = context.read<AppState>();
    final bytes = appState.export.buildTextIndex(widget.folder.name, docs);
    await appState.share.shareBytes(bytes, '${widget.folder.name}_index.txt', mimeType: 'text/plain');
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = appState.strings;
    final isGrid = appState.db.settings.viewMode == 'grid';
    final documents = appState.db.documentsForFolder(widget.folder.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode ? '${_selectedIds.length} ${s.t('selected')}' : widget.folder.name),
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _selectionMode = false;
                  _selectedIds.clear();
                }),
              )
            : null,
        actions: _selectionMode
            ? [
                IconButton(icon: const Icon(Icons.drive_file_move_outline), onPressed: () => _moveOrCopySelected(move: true)),
                IconButton(icon: const Icon(Icons.copy_outlined), onPressed: () => _moveOrCopySelected(move: false)),
                IconButton(icon: const Icon(Icons.delete_outline), onPressed: _deleteSelected),
              ]
            : [
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'export_batch') _exportBatch(documents);
                    if (v == 'export_index') _exportIndex(documents);
                    if (v == 'select') setState(() => _selectionMode = true);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'select', child: Text(s.t('selectMode'))),
                    PopupMenuItem(value: 'export_batch', child: Text(s.t('export'))),
                    PopupMenuItem(value: 'export_index', child: Text(s.t('exportIndex'))),
                  ],
                ),
              ],
      ),
      body: documents.isEmpty
          ? Center(child: Text(s.t('noDocuments')))
          : isGrid
              ? GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: documents.length,
                  itemBuilder: (context, index) => _buildCard(documents[index], isGrid, appState),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: documents.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _buildCard(documents[index], isGrid, appState),
                ),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _addDocument,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(s.t('addDocument')),
            ),
    );
  }

  Widget _buildCard(Document doc, bool isGrid, AppState appState) {
    return DocumentCard(
      document: doc,
      isGrid: isGrid,
      selected: _selectedIds.contains(doc.id),
      selectionMode: _selectionMode,
      onTap: () {
        if (_selectionMode) {
          _toggle(doc.id);
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc)));
        }
      },
      onLongPress: () => setState(() {
        _selectionMode = true;
        _selectedIds.add(doc.id);
      }),
    );
  }
}
