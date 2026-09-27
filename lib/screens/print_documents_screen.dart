import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../app_state.dart';
import '../services/storage_paths.dart';
import '../theme/app_colors.dart';
import '../widgets/error_dialogs.dart';

/// The kinds of official documents a print-shop customer typically brings
/// in, each with its own colored slot card — see the reference screenshot
/// Ahmed sent. Order here is the order pages are compiled into the PDF.
enum IdSlot {
  nationalIdFront,
  nationalIdBack,
  housingCardFront,
  housingCardBack,
  foodRationCard,
  passport,
  drivingLicense,
}

extension on IdSlot {
  Color get background => switch (this) {
    IdSlot.nationalIdFront => const Color(0xFFDCEEFB),
    IdSlot.nationalIdBack => const Color(0xFFDCF5F0),
    IdSlot.housingCardFront => const Color(0xFFFFF1D6),
    IdSlot.housingCardBack => const Color(0xFFEFE0FB),
    IdSlot.foodRationCard => const Color(0xFFFBDDE7),
    IdSlot.passport => const Color(0xFFE0EEFF),
    IdSlot.drivingLicense => const Color(0xFFFCE8D6),
  };

  Color get foreground => switch (this) {
    IdSlot.nationalIdFront => const Color(0xFF1976D2),
    IdSlot.nationalIdBack => const Color(0xFF0E9384),
    IdSlot.housingCardFront => const Color(0xFFB8860B),
    IdSlot.housingCardBack => const Color(0xFF8E24AA),
    IdSlot.foodRationCard => const Color(0xFFD81B60),
    IdSlot.passport => const Color(0xFF2563EB),
    IdSlot.drivingLicense => const Color(0xFFE65100),
  };

  IconData get icon => switch (this) {
    IdSlot.nationalIdFront || IdSlot.nationalIdBack => Icons.badge_outlined,
    IdSlot.housingCardFront || IdSlot.housingCardBack => Icons.home_outlined,
    IdSlot.foodRationCard => Icons.receipt_long_outlined,
    IdSlot.passport => Icons.menu_book_outlined,
    IdSlot.drivingLicense => Icons.directions_car_outlined,
  };

  String titleKey() => switch (this) {
    IdSlot.nationalIdFront => 'nationalIdFront',
    IdSlot.nationalIdBack => 'nationalIdBack',
    IdSlot.housingCardFront => 'housingCardFront',
    IdSlot.housingCardBack => 'housingCardBack',
    IdSlot.foodRationCard => 'foodRationCard',
    IdSlot.passport => 'passport',
    IdSlot.drivingLicense => 'drivingLicense',
  };

  String subtitleKey() => switch (this) {
    IdSlot.nationalIdFront => 'nationalIdFrontSubtitle',
    IdSlot.nationalIdBack => 'nationalIdBackSubtitle',
    IdSlot.housingCardFront => 'housingCardFrontSubtitle',
    IdSlot.housingCardBack => 'housingCardBackSubtitle',
    IdSlot.foodRationCard => 'foodRationCardSubtitle',
    IdSlot.passport => 'passportSubtitle',
    IdSlot.drivingLicense => 'drivingLicenseSubtitle',
  };
}

class _Person {
  final Map<IdSlot, String> slotPaths = {};
}

/// A deliberately temporary workspace for a print shop (or anyone) to scan
/// someone's official documents and immediately print/save them as one
/// PDF. Nothing here is written to the app's database or any persisted
/// document — only to plain files that "Start new" deletes — because this
/// screen exists to process other people's sensitive IDs one customer at a
/// time, not to build an archive of them.
class PrintDocumentsScreen extends StatefulWidget {
  const PrintDocumentsScreen({super.key, this.hasUnsavedData});

  /// Kept in sync with whether any person here has at least one scanned
  /// slot — [RootShell] watches this to warn before letting the app exit
  /// (via the system back button) and silently discard everything, since
  /// this section deliberately never saves anything on its own.
  final ValueNotifier<bool>? hasUnsavedData;

  @override
  State<PrintDocumentsScreen> createState() => _PrintDocumentsScreenState();
}

class _PrintDocumentsScreenState extends State<PrintDocumentsScreen> {
  final List<_Person> _people = [_Person()];
  int _activePerson = 0;
  bool _busy = false;

  static const _maxPeople = 4;

  void _syncUnsavedFlag() {
    widget.hasUnsavedData?.value = _people.any((p) => p.slotPaths.isNotEmpty);
  }

  Future<void> _scanSlot(IdSlot slot) async {
    setState(() => _busy = true);
    final appState = context.read<AppState>();
    final s = appState.strings;
    var retry = false;
    try {
      final pictures = await CunningDocumentScanner.getPictures(noOfPages: 1);
      if (pictures == null || pictures.isEmpty || !mounted) return;

      final outDir = await StoragePaths.scansDirectory();
      final id = const Uuid().v4();
      final (highRes, _) = await appState.imageProcessing.processAndSave(
        sourcePath: pictures.first,
        outputDir: outDir.path,
        pageId: 'print_$id',
      );
      await CunningDocumentScanner.cleanCache();

      final previous = _people[_activePerson].slotPaths[slot];
      if (previous != null) await _deleteQuietly(previous);
      _people[_activePerson].slotPaths[slot] = highRes;
      _syncUnsavedFlag();
    } on CunningDocumentScannerException catch (e) {
      if (!mounted) return;
      final message = e.code == 'permission_denied'
          ? s.t('scannerErrorPermission')
          : s.t('scannerErrorGeneric');
      retry = await showErrorDialog(
        context,
        title: s.t('scannerErrorTitle'),
        message: message,
        retryLabel: s.t('retry'),
        dismissLabel: s.t('cancel'),
      );
    } catch (_) {
      if (!mounted) return;
      await showErrorDialog(
        context,
        title: s.t('genericErrorTitle'),
        message: s.t('imageProcessingError'),
        dismissLabel: s.t('ok'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (retry && mounted) await _scanSlot(slot);
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best-effort cleanup — a leftover temp file here is not worth
      // surfacing an error to the user over.
    }
  }

  Future<void> _print() async {
    final appState = context.read<AppState>();
    final s = appState.strings;
    final paths = _people.expand((p) => p.slotPaths.values).toList();
    if (paths.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.t('noDocumentsToPrint'))));
      return;
    }
    setState(() => _busy = true);
    try {
      final bytes = await appState.pdf.buildPdf(paths);
      await appState.pdf.printBytes(bytes, name: s.t('printDocuments'));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('pdfBuildError'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmReset() async {
    final s = context.read<AppState>().strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('startNew')),
        content: Text(s.t('printDocsResetConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.t('ok')),
          ),
        ],
      ),
    );
    if (confirmed == true) await _resetAll();
  }

  Future<void> _resetAll() async {
    for (final person in _people) {
      for (final path in person.slotPaths.values) {
        await _deleteQuietly(path);
      }
    }
    setState(() {
      _people
        ..clear()
        ..add(_Person());
      _activePerson = 0;
    });
    _syncUnsavedFlag();
  }

  void _addPerson() {
    if (_people.length >= _maxPeople) return;
    setState(() {
      _people.add(_Person());
      _activePerson = _people.length - 1;
    });
  }

  @override
  void dispose() {
    // Best-effort cleanup if the user leaves without an explicit reset —
    // this screen's whole point is to not leave a customer's IDs behind.
    for (final person in _people) {
      for (final path in person.slotPaths.values) {
        _deleteQuietly(path);
      }
    }
    widget.hasUnsavedData?.value = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = appState.strings;
    final person = _people[_activePerson];

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('printDocuments')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: s.t('startNew'),
            onPressed: _confirmReset,
          ),
        ],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _print,
                    icon: const Icon(Icons.print_outlined),
                    label: Text(s.t('printOrSavePdf')),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_people.length > 1 || _people.length < _maxPeople)
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (var i = 0; i < _people.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.sm),
                            child: ChoiceChip(
                              label: Text('${s.t('person')} ${i + 1}'),
                              selected: _activePerson == i,
                              onSelected: (_) =>
                                  setState(() => _activePerson = i),
                            ),
                          ),
                        if (_people.length < _maxPeople)
                          Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.sm),
                            child: ActionChip(
                              avatar: const Icon(Icons.add, size: 16),
                              label: Text(s.t('addPerson')),
                              onPressed: _addPerson,
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.15,
                  children: [
                    for (final slot in IdSlot.values)
                      _slotCard(
                        context,
                        slot: slot,
                        filledPath: person.slotPaths[slot],
                        s: s,
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _slotCard(
    BuildContext context, {
    required IdSlot slot,
    required String? filledPath,
    required dynamic s,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardRadius,
        boxShadow: PastelPalette.shadow,
      ),
      child: Material(
        color: slot.background,
        borderRadius: AppRadius.cardRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _scanSlot(slot),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Stack(
              children: [
                if (filledPath != null)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(File(filledPath), fit: BoxFit.cover),
                    ),
                  )
                else
                  Positioned(
                    right: -8,
                    bottom: -8,
                    child: Icon(
                      slot.icon,
                      size: 64,
                      color: slot.foreground.withValues(alpha: 0.18),
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.t(slot.titleKey()),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: filledPath != null ? Colors.white : null,
                        shadows: filledPath != null
                            ? const [
                                Shadow(blurRadius: 4, color: Colors.black54),
                              ]
                            : null,
                      ),
                    ),
                    Text(
                      s.t(slot.subtitleKey()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: filledPath != null
                            ? Colors.white
                            : slot.foreground.withValues(alpha: 0.85),
                        shadows: filledPath != null
                            ? const [
                                Shadow(blurRadius: 4, color: Colors.black54),
                              ]
                            : null,
                      ),
                    ),
                    const Spacer(),
                    Align(
                      alignment: AlignmentDirectional.bottomStart,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Icon(
                          filledPath != null ? Icons.edit_outlined : Icons.add,
                          color: slot.foreground,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
