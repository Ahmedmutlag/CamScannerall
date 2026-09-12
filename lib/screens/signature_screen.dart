import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart' as sig;

import '../app_state.dart';
import '../models/document.dart';
import '../theme/app_colors.dart';

enum _Stage { loading, choose, draw, place }

class SignatureScreen extends StatefulWidget {
  const SignatureScreen({super.key, required this.document});

  final Document document;

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  _Stage _stage = _Stage.loading;
  final sig.SignatureController _padController =
      sig.SignatureController(penStrokeWidth: 4, penColor: AppColors.light.textPrimary);

  Uint8List? _signatureBytes;
  int _pageIndex = 0;
  bool _addDate = false;
  Offset _position = const Offset(0.35, 0.7);
  double _widthFraction = 0.32;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final appState = context.read<AppState>();
    if (await appState.signature.hasSavedSignature()) {
      final path = await appState.signature.savedSignaturePath();
      _signatureBytes = await File(path).readAsBytes();
      setState(() => _stage = _Stage.choose);
    } else {
      setState(() => _stage = _Stage.draw);
    }
  }

  @override
  void dispose() {
    _padController.dispose();
    super.dispose();
  }

  Future<void> _saveDrawnSignature() async {
    if (_padController.isEmpty) return;
    final bytes = await _padController.toPngBytes();
    if (bytes == null || !mounted) return;
    final appState = context.read<AppState>();
    await appState.signature.saveMySignature(bytes);
    setState(() {
      _signatureBytes = bytes;
      _stage = _Stage.place;
    });
  }

  Future<void> _apply() async {
    setState(() => _saving = true);
    final appState = context.read<AppState>();
    final page = widget.document.pages[_pageIndex];
    await appState.signature.applySignatureToPage(
      highResPath: page.imagePathHighRes,
      lowResPath: page.imagePathLowRes,
      signaturePng: _signatureBytes!,
      relativeOffset: _position,
      relativeWidth: _widthFraction,
      addDateStamp: _addDate,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = appState.strings;

    return Scaffold(
      appBar: AppBar(title: Text(s.t('signature'))),
      body: switch (_stage) {
        _Stage.loading => const Center(child: CircularProgressIndicator()),
        _Stage.choose => _buildChoose(s),
        _Stage.draw => _buildDraw(s),
        _Stage.place => _buildPlace(s),
      },
    );
  }

  Widget _buildChoose(dynamic s) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_signatureBytes != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(border: Border.all(color: colors.divider), borderRadius: AppRadius.radius),
              child: Image.memory(_signatureBytes!, height: 100),
            ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: () => setState(() => _stage = _Stage.place), child: Text(s.t('useSignature'))),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(onPressed: () => setState(() => _stage = _Stage.draw), child: Text(s.t('drawSignature'))),
        ],
      ),
    );
  }

  Widget _buildDraw(dynamic s) {
    final colors = AppColors.of(context);
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(border: Border.all(color: colors.divider), borderRadius: AppRadius.radius),
            child: sig.Signature(controller: _padController, backgroundColor: colors.backgroundPrimary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: () => _padController.clear(), child: Text(s.t('clear'))),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(onPressed: _saveDrawnSignature, child: Text(s.t('save'))),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlace(dynamic s) {
    final colors = AppColors.of(context);
    final page = widget.document.pages[_pageIndex];
    return Column(
      children: [
        if (widget.document.pages.length > 1)
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.document.pages.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
                child: GestureDetector(
                  onTap: () => setState(() => _pageIndex = i),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: i == _pageIndex ? colors.primaryInk : Colors.transparent, width: 2),
                    ),
                    child: Image.file(File(widget.document.pages[i].imagePathLowRes), width: 46, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 0.707, // A4 portrait ratio
              child: LayoutBuilder(builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                final sigWidth = size.width * _widthFraction;
                return Stack(
                  children: [
                    Positioned.fill(child: Image.file(File(page.imagePathLowRes), fit: BoxFit.fill)),
                    Positioned(
                      left: _position.dx * size.width,
                      top: _position.dy * size.height,
                      child: GestureDetector(
                        onPanUpdate: (d) => setState(() {
                          _position = Offset(
                            ((_position.dx * size.width + d.delta.dx) / size.width).clamp(0.0, 0.85),
                            ((_position.dy * size.height + d.delta.dy) / size.height).clamp(0.0, 0.9),
                          );
                        }),
                        child: Container(
                          width: sigWidth,
                          decoration: BoxDecoration(border: Border.all(color: colors.primaryInk)),
                          child: Image.memory(_signatureBytes!, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Icon(Icons.photo_size_select_small, color: colors.textSecondary),
              Expanded(
                child: Slider(
                  value: _widthFraction,
                  min: 0.15,
                  max: 0.6,
                  onChanged: (v) => setState(() => _widthFraction = v),
                ),
              ),
            ],
          ),
        ),
        CheckboxListTile(
          value: _addDate,
          onChanged: (v) => setState(() => _addDate = v ?? false),
          title: Text(s.t('addDateStamp')),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _apply,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(s.t('done')),
            ),
          ),
        ),
      ],
    );
  }
}
