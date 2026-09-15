import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/document.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/full_page_preview.dart';
import '../widgets/recent_document_tile.dart';
import 'camera_screen.dart';
import 'document_detail_screen.dart';

/// The Home tab: quick tools (scan, import) up top and a flat "Recent"
/// documents feed below with one-tap actions — the primary landing screen,
/// so scanning never requires picking a folder first (new scans land in
/// [AppState.defaultFolderId] and can be filed away later from Files).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _busy = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final result = await Navigator.of(context).push<List<({String highRes, String lowRes})>>(
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
    if (result == null || result.isEmpty || !mounted) return;

    final appState = context.read<AppState>();
    final s = appState.strings;
    final (doc, duplicate) = await appState.createDocumentFromPages(pages: result);

    if (duplicate != null && mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(s.t('duplicateFound')),
          content: Text('${s.t('duplicateBody')}\n\n"${duplicate.name}"'),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(s.t('ok')))],
        ),
      );
    }
    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc)));
    }
  }

  Future<void> _importFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (file == null || file.path == null || !mounted) return;
    final appState = context.read<AppState>();

    setState(() => _busy = true);
    try {
      final bytes = await File(file.path!).readAsBytes();
      final ext = (file.extension ?? '').toLowerCase();
      final pages = ext == 'pdf' ? await appState.rasterizePdf(bytes) : [bytes];
      final (doc, _) = await appState.importPages(pageBytesList: pages);
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _quickView(Document doc) async {
    final appState = context.read<AppState>();
    final sorted = List.of(doc.pages)..sort((a, b) => a.order.compareTo(b.order));
    final removedIndex = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => FullPagePreview(
          paths: sorted.map((p) => p.imagePathHighRes).toList(),
          initialIndex: 0,
        ),
        fullscreenDialog: true,
      ),
    );
    if (removedIndex != null) await appState.deletePage(doc, sorted[removedIndex]);
  }

  Future<void> _shareAsPdf(Document doc) async {
    final appState = context.read<AppState>();
    final bytes = await appState.pdf.buildPdf(doc.pages.map((p) => p.imagePathHighRes).toList());
    await appState.pdf.sharePdf(bytes, filename: '${doc.name}.pdf');
  }

  Future<void> _toWord(Document doc) async {
    final appState = context.read<AppState>();
    final pagesText = doc.extractedText.isEmpty ? [''] : doc.extractedText.split('\n\n');
    final bytes = appState.docx.buildDocx(title: doc.name, pagesText: pagesText);
    await appState.share.shareBytes(
      bytes,
      '${doc.name}.docx',
      mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = appState.strings;
    final colors = AppColors.of(context);

    final searching = _query.trim().isNotEmpty;
    final results = searching ? appState.db.search(_query) : appState.db.recentActivity;

    return Scaffold(
      appBar: AppBar(title: Text(s.t('appName'))),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: s.t('search'),
                    ),
                  ),
                ),
                if (!searching)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: _toolButton(
                            context,
                            icon: Icons.document_scanner_outlined,
                            label: s.t('scan'),
                            background: const Color(0xFFDCF5F0),
                            foreground: const Color(0xFF0E9384),
                            onTap: _scan,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _toolButton(
                            context,
                            icon: Icons.file_upload_outlined,
                            label: s.t('importFile'),
                            background: const Color(0xFFE0EEFF),
                            foreground: const Color(0xFF2563EB),
                            onTap: _importFile,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                if (!searching)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(s.t('recent'), style: Theme.of(context).textTheme.titleSmall),
                    ),
                  ),
                Expanded(
                  child: results.isEmpty
                      ? EmptyStateView(message: searching ? s.t('noSearchResults') : s.t('noRecent'))
                      : ListView.separated(
                          itemCount: results.length,
                          separatorBuilder: (_, _) =>
                              Divider(color: colors.divider, height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final doc = results[index];
                            return RecentDocumentTile(
                              document: doc,
                              viewLabel: s.t('view'),
                              toWordLabel: s.t('wordShort'),
                              shareLabel: s.t('share'),
                              onTap: () => Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc))),
                              onView: () => _quickView(doc),
                              onToWord: () => _toWord(doc),
                              onShare: () => _shareAsPdf(doc),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _toolButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radius,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: background,
              child: Icon(icon, color: foreground),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
