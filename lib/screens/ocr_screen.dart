import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/document.dart';
import '../theme/app_colors.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key, required this.document});

  final Document document;

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  bool _busy = false;

  Future<void> _reextract() async {
    setState(() => _busy = true);
    final appState = context.read<AppState>();
    final text = await appState.ocr.extractTextFromPages(
      widget.document.pages.map((p) => p.imagePathHighRes).toList(),
    );
    widget.document.extractedText = text;
    await widget.document.save();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.document.extractedText));
    if (!mounted) return;
    final s = context.read<AppState>().strings;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('textCopied'))));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = appState.strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('extractedText')),
        actions: [
          IconButton(
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            onPressed: _busy ? null : _reextract,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  widget.document.extractedText.isEmpty ? '—' : widget.document.extractedText,
                  style: TextStyle(color: AppColors.of(context).textPrimary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(onPressed: _copy, icon: const Icon(Icons.copy_outlined), label: Text(s.t('copyText'))),
          ],
        ),
      ),
    );
  }
}
