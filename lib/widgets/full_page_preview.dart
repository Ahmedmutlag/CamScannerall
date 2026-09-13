import 'dart:io';

import 'package:flutter/material.dart';

/// Full-screen, pinch-to-zoom review of a scanned page, with swipe between
/// pages and an optional delete action. Used both by the camera review grid
/// (before a document is even saved) and the document detail screen (after
/// it's saved) — in both places, tapping a thumbnail previously did nothing.
class FullPagePreview extends StatefulWidget {
  const FullPagePreview({super.key, required this.paths, required this.initialIndex});

  final List<String> paths;
  final int initialIndex;

  @override
  State<FullPagePreview> createState() => _FullPagePreviewState();
}

class _FullPagePreviewState extends State<FullPagePreview> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late int _currentIndex = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.paths.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => Navigator.of(context).pop(_currentIndex),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.paths.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) => InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Center(child: Image.file(File(widget.paths[index]))),
        ),
      ),
    );
  }
}
