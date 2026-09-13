import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/doc_page.dart';
import '../models/document.dart';
import '../models/folder.dart';
import '../theme/app_colors.dart';
import '../widgets/full_page_preview.dart';
import 'camera_screen.dart';
import 'ocr_screen.dart';
import 'signature_screen.dart';

class DocumentDetailScreen extends StatefulWidget {
  const DocumentDetailScreen({super.key, required this.document});

  final Document document;

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  late final TextEditingController _validUntilController =
      TextEditingController(text: widget.document.manualValidUntilNote ?? '');
  late final TextEditingController _locationController =
      TextEditingController(text: widget.document.locationNote ?? '');

  static const _colorOptions = <int>[
    0xFFEF5350,
    0xFFFFA726,
    0xFFFFEE58,
    0xFF66BB6A,
    0xFF42A5F5,
    0xFFAB47BC,
  ];

  @override
  void dispose() {
    _validUntilController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Document get doc => widget.document;

  Future<void> _rename() async {
    final appState = context.read<AppState>();
    final s = appState.strings;
    final controller = TextEditingController(text: doc.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('rename')),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(s.t('save'))),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await appState.renameDocument(doc, name);
      setState(() {});
    }
  }

  Future<void> _delete() async {
    final appState = context.read<AppState>();
    await appState.deleteDocument(doc);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openPreview(List<DocPage> pages, int initialIndex) async {
    final appState = context.read<AppState>();
    final removedIndex = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => FullPagePreview(
          paths: pages.map((p) => p.imagePathHighRes).toList(),
          initialIndex: initialIndex,
        ),
        fullscreenDialog: true,
      ),
    );
    if (removedIndex == null || !mounted) return;
    await appState.deletePage(doc, pages[removedIndex]);
    setState(() {});
  }

  Future<void> _addPages() async {
    final result = await Navigator.of(context).push<List<({String highRes, String lowRes})>>(
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
    if (result == null || result.isEmpty || !mounted) return;
    final appState = context.read<AppState>();
    await appState.addPagesToDocument(doc, result);
    setState(() {});
  }

  Future<void> _saveNotes() async {
    doc.manualValidUntilNote = _validUntilController.text.trim().isEmpty ? null : _validUntilController.text.trim();
    doc.locationNote = _locationController.text.trim().isEmpty ? null : _locationController.text.trim();
    await doc.save();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<AppState>().strings.t('save'))));
  }

  Future<void> _setColor(int color) async {
    doc.colorTag = color;
    await doc.save();
    setState(() {});
  }

  Future<void> _shareFlow() async {
    final appState = context.read<AppState>();
    final s = appState.strings;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: const Icon(Icons.high_quality_outlined), title: Text(s.t('qualityHigh')), onTap: () => Navigator.pop(context, 'high')),
          ListTile(leading: const Icon(Icons.speed_outlined), title: Text(s.t('qualityLight')), onTap: () => Navigator.pop(context, 'light')),
        ]),
      ),
    );
    if (choice == null) return;
    final paths = choice == 'high'
        ? doc.pages.map((p) => p.imagePathHighRes).toList()
        : doc.pages.map((p) => p.imagePathLowRes).toList();
    final bytes = await appState.pdf.buildPdf(paths);
    await appState.pdf.sharePdf(bytes, filename: '${doc.name}.pdf');
  }

  Future<void> _print() async {
    final appState = context.read<AppState>();
    final bytes = await appState.pdf.buildPdf(doc.pages.map((p) => p.imagePathHighRes).toList());
    await appState.pdf.printBytes(bytes, name: doc.name);
  }

  Future<void> _convertMenu() async {
    final appState = context.read<AppState>();
    final s = appState.strings;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(s.t('toWord')),
            subtitle: Text(s.t('toWordNote')),
            onTap: () => Navigator.pop(context, 'word'),
          ),
          ListTile(leading: const Icon(Icons.image_outlined), title: Text(s.t('pdfToImages')), onTap: () => Navigator.pop(context, 'images')),
          ListTile(leading: const Icon(Icons.call_split), title: Text(s.t('splitPdf')), onTap: () => Navigator.pop(context, 'split')),
          ListTile(leading: const Icon(Icons.compress), title: Text(s.t('compressPdf')), onTap: () => Navigator.pop(context, 'compress')),
          ListTile(
            leading: Icon(Icons.lock_outline, color: AppColors.of(context).accentBrass),
            title: Text(s.t('protectPassword')),
            onTap: () => Navigator.pop(context, 'protect'),
          ),
        ]),
      ),
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case 'word':
        await _toWord();
      case 'images':
        await _toImages();
      case 'split':
        await _split();
      case 'compress':
        await _compress();
      case 'protect':
        await _protect();
    }
  }

  Future<void> _toWord() async {
    final appState = context.read<AppState>();
    final pagesText = doc.extractedText.isEmpty ? [''] : doc.extractedText.split('\n\n');
    final bytes = appState.docx.buildDocx(title: doc.name, pagesText: pagesText);
    await appState.share.shareBytes(bytes, '${doc.name}.docx',
        mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
  }

  Future<void> _toImages() async {
    final appState = context.read<AppState>();
    await appState.share.shareFiles(doc.pages.map((p) => p.imagePathHighRes).toList());
  }

  Future<void> _split() async {
    final appState = context.read<AppState>();
    final s = appState.strings;
    if (doc.pages.length < 2) return;
    final controller = TextEditingController(text: '${(doc.pages.length / 2).ceil()}');
    final index = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('splitPdf')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.t('cancel'))),
          FilledButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text)),
            child: Text(s.t('splitPdf')),
          ),
        ],
      ),
    );
    if (index == null || index <= 0 || index >= doc.pages.length) return;
    await appState.splitDocument(doc, index);
    if (mounted) setState(() {});
  }

  Future<void> _compress() async {
    final appState = context.read<AppState>();
    final bytes = await appState.pdf.compressPdf(doc.pages.map((p) => p.imagePathHighRes).toList());
    await appState.pdf.sharePdf(bytes, filename: '${doc.name}_compressed.pdf');
  }

  Future<void> _protect() async {
    final appState = context.read<AppState>();
    final s = appState.strings;
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('protectPassword')),
        content: TextField(controller: controller, obscureText: true, decoration: InputDecoration(labelText: s.t('pdfPasswordHint'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(s.t('ok'))),
        ],
      ),
    );
    if (password == null || password.isEmpty) return;
    final pdfBytes = await appState.pdf.buildPdf(doc.pages.map((p) => p.imagePathHighRes).toList());
    final protectedBytes = await appState.pdfProtection.protect(pdfBytes, password);
    await appState.pdf.sharePdf(protectedBytes, filename: '${doc.name}.pdf');
  }

  Future<void> _moveOrCopy({required bool move}) async {
    final appState = context.read<AppState>();
    final s = appState.strings;
    final folders = appState.db.allFolders.where((f) => f.id != doc.folderId).toList();
    if (folders.isEmpty) return;
    final target = await showDialog<Folder>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(move ? s.t('move') : s.t('copy')),
        children: folders.map((f) => SimpleDialogOption(onPressed: () => Navigator.pop(context, f), child: Text(f.name))).toList(),
      ),
    );
    if (target == null) return;
    if (move) {
      await appState.moveDocumentToFolder(doc, target.id);
      if (mounted) Navigator.of(context).pop();
    } else {
      await appState.copyDocumentToFolder(doc, target.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = appState.strings;
    final colors = AppColors.of(context);
    final pages = List<DocPage>.from(doc.pages)..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(onTap: _rename, child: Text(doc.name)),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          SizedBox(
            height: 160,
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: pages.length,
              onReorder: (oldIndex, newIndex) => appState.reorderPages(doc, oldIndex, newIndex),
              itemBuilder: (context, index) {
                final page = pages[index];
                return Padding(
                  key: ValueKey(page.id),
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _openPreview(pages, index),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colors.divider),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.file(File(page.imagePathLowRes), width: 110, height: 150, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: InkWell(
                          onTap: () async {
                            await appState.deletePage(doc, page);
                            setState(() {});
                          },
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(onPressed: _addPages, icon: const Icon(Icons.add), label: Text(s.t('addAnotherPage'))),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: _colorOptions
                .map((c) => GestureDetector(
                      onTap: () => _setColor(c),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(c),
                        child: doc.colorTag == c ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _validUntilController,
            decoration: InputDecoration(labelText: s.t('validUntilNote')),
            onEditingComplete: _saveNotes,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(labelText: s.t('locationNote')),
            onEditingComplete: _saveNotes,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _actionChip(Icons.share_outlined, s.t('share'), _shareFlow),
              _actionChip(Icons.print_outlined, s.t('print'), _print),
              _actionChip(Icons.draw_outlined, s.t('sign'), () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SignatureScreen(document: doc)))),
              _actionChip(Icons.text_snippet_outlined, s.t('extractText'),
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OcrScreen(document: doc)))),
              _actionChip(Icons.transform, s.t('convertFormat'), _convertMenu),
              _actionChip(Icons.drive_file_move_outline, s.t('move'), () => _moveOrCopy(move: true)),
              _actionChip(Icons.copy_outlined, s.t('copy'), () => _moveOrCopy(move: false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, VoidCallback onTap) {
    return Builder(
      builder: (context) => ActionChip(
        avatar: Icon(icon, size: 18, color: AppColors.of(context).primaryInk),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }
}
