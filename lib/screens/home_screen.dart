import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/document.dart';
import '../theme/app_colors.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_dialogs.dart';
import '../widgets/full_page_preview.dart';
import '../widgets/recent_document_tile.dart';
import 'camera_screen.dart';
import 'document_detail_screen.dart';
import 'files_screen.dart';
import 'settings_screen.dart';

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
    final result = await Navigator.of(context)
        .push<List<({String highRes, String lowRes})>>(
          MaterialPageRoute(builder: (_) => const CameraScreen()),
        );
    if (result == null || result.isEmpty || !mounted) return;

    final appState = context.read<AppState>();
    final s = appState.strings;

    Document doc;
    Document? duplicate;
    try {
      (doc, duplicate) = await runWithBusyOverlay(
        context,
        () => appState.createDocumentFromPages(pages: result),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('operationFailedGeneric'))));
      }
      return;
    }

    if (duplicate != null && mounted) {
      final viewExisting = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(s.t('duplicateFound')),
          content: Text('${s.t('duplicateBody')}\n\n"${duplicate!.name}"'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(s.t('viewExisting')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.t('ok')),
            ),
          ],
        ),
      );
      if (viewExisting == true && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: duplicate!)),
        );
        return;
      }
    }
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc)),
      );
    }
  }

  Future<void> _importFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (file == null || file.path == null || !mounted) return;
    final appState = context.read<AppState>();
    final s = appState.strings;

    setState(() => _busy = true);
    try {
      final bytes = await File(file.path!).readAsBytes();
      final ext = (file.extension ?? '').toLowerCase();
      final pages = ext == 'pdf' ? await appState.rasterizePdf(bytes) : [bytes];
      final (doc, _) = await appState.importPages(pageBytesList: pages);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DocumentDetailScreen(document: doc),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('operationFailedGeneric'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Lets the Home "Recent" list delete a document directly, instead of
  /// forcing a trip into the document's detail screen first just to reach
  /// its delete button.
  Future<void> _deleteDocument(Document doc) async {
    final appState = context.read<AppState>();
    final s = appState.strings;
    final confirmed = await confirmDelete(
      context,
      title: s.t('deleteDocumentTitle'),
      message: s.t('deleteDocumentBody'),
      cancelLabel: s.t('cancel'),
      deleteLabel: s.t('delete'),
    );
    if (!confirmed || !mounted) return;
    await appState.deleteDocument(doc);
  }

  Future<void> _quickView(Document doc) async {
    final appState = context.read<AppState>();
    final s = appState.strings;
    final sorted = List.of(doc.pages)
      ..sort((a, b) => a.order.compareTo(b.order));
    final removedIndex = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => FullPagePreview(
          paths: sorted.map((p) => p.imagePathHighRes).toList(),
          initialIndex: 0,
          deleteTooltip: s.t('delete'),
        ),
        fullscreenDialog: true,
      ),
    );
    if (removedIndex == null || !mounted) return;
    final confirmed = await confirmDelete(
      context,
      title: s.t('deletePageTitle'),
      message: s.t('deletePageBody'),
      cancelLabel: s.t('cancel'),
      deleteLabel: s.t('delete'),
    );
    if (confirmed) await appState.deletePage(doc, sorted[removedIndex]);
  }

  Future<void> _shareAsPdf(Document doc) async {
    final appState = context.read<AppState>();
    final s = appState.strings;
    try {
      await runWithBusyOverlay(context, () async {
        final bytes = await appState.pdf.buildPdf(
          doc.pages.map((p) => p.imagePathHighRes).toList(),
        );
        await appState.pdf.sharePdf(bytes, filename: '${doc.name}.pdf');
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('pdfBuildError'))));
      }
    }
  }

  Future<void> _toWord(Document doc) async {
    final appState = context.read<AppState>();
    final s = appState.strings;
    try {
      await runWithBusyOverlay(context, () async {
        final pagesText = doc.extractedText.isEmpty
            ? ['']
            : doc.extractedText.split('\n\n');
        final bytes = appState.docx.buildDocx(
          title: doc.name,
          pagesText: pagesText,
        );
        await appState.share.shareBytes(
          bytes,
          '${doc.name}.docx',
          mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        );
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('operationFailedGeneric'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = appState.strings;
    final colors = AppColors.of(context);

    final searching = _query.trim().isNotEmpty;
    final results = searching
        ? appState.db.search(_query)
        : appState.db.recentActivity;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('appName')),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            tooltip: s.t('files'),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const FilesScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: s.t('settings'),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: s.t('search'),
                      suffixIcon: searching
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: s.t('clearSearch'),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                if (!searching)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _toolCard(
                            context,
                            icon: Icons.document_scanner_outlined,
                            title: s.t('scan'),
                            subtitle: s.t('scanSubtitle'),
                            background: const Color(0xFFDCF5F0),
                            foreground: const Color(0xFF0E9384),
                            onTap: _scan,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _toolCard(
                            context,
                            icon: Icons.file_upload_outlined,
                            title: s.t('importFile'),
                            subtitle: s.t('importFileSubtitle'),
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
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.xs,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        s.t('recent'),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
                Expanded(
                  child: results.isEmpty
                      ? EmptyStateView(
                          message: searching
                              ? s.t('noSearchResults')
                              : s.t('noRecent'),
                        )
                      : ListView.separated(
                          itemCount: results.length,
                          separatorBuilder: (_, _) => Divider(
                            color: colors.divider,
                            height: 1,
                            indent: AppSpacing.md,
                            endIndent: AppSpacing.md,
                          ),
                          itemBuilder: (context, index) {
                            final doc = results[index];
                            return RecentDocumentTile(
                              document: doc,
                              viewLabel: s.t('view'),
                              toWordLabel: s.t('wordShort'),
                              shareLabel: s.t('share'),
                              deleteLabel: s.t('delete'),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DocumentDetailScreen(document: doc),
                                ),
                              ),
                              onView: () => _quickView(doc),
                              onToWord: () => _toWord(doc),
                              onShare: () => _shareAsPdf(doc),
                              onDelete: () => _deleteDocument(doc),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  /// A big, colorful, tappable tile — the whole pastel card is the button
  /// (no separate small icon-button in the corner), matching the reference
  /// Ahmed sent while keeping the interaction simple on a phone screen.
  Widget _toolCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardRadius,
        boxShadow: PastelPalette.shadow,
      ),
      child: Material(
        color: background,
        borderRadius: AppRadius.cardRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: Icon(icon, color: foreground, size: 22),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: foreground.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
