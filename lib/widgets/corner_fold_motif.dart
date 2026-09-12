import 'package:flutter/material.dart';

/// The app's recurring brand motif: a simple sheet of paper with its top
/// corner folded down (see design-spec.md §3). Used, at different sizes
/// and opacities, on the splash screen and as a faint background decoration
/// on empty states. This is a fixed brand mark (like a logotype), so it is
/// not mirrored for RTL — only functional directional icons are.
class CornerFoldMotif extends StatelessWidget {
  const CornerFoldMotif({
    super.key,
    this.size = 96,
    this.color,
    this.opacity = 1,
  });

  final double size;
  final Color? color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _CornerFoldPainter(color: resolvedColor),
        ),
      ),
    );
  }
}

class _CornerFoldPainter extends CustomPainter {
  _CornerFoldPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fold = size.width * 0.32;

    final pagePath = Path()
      ..moveTo(size.width * 0.12, 0)
      ..lineTo(size.width - fold, 0)
      ..lineTo(size.width, fold)
      ..lineTo(size.width, size.height * 0.88)
      ..quadraticBezierTo(size.width, size.height, size.width * 0.88, size.height)
      ..lineTo(size.width * 0.12, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height * 0.88)
      ..lineTo(0, size.width * 0.12)
      ..quadraticBezierTo(0, 0, size.width * 0.12, 0)
      ..close();

    final pageStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..color = color;

    canvas.drawPath(pagePath, pageStroke);

    // The folded triangle at the top-right corner.
    final foldPath = Path()
      ..moveTo(size.width - fold, 0)
      ..lineTo(size.width, fold)
      ..lineTo(size.width - fold, fold)
      ..close();

    final foldFill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.16);
    canvas.drawPath(foldPath, foldFill);
    canvas.drawPath(foldPath, pageStroke);

    // A couple of short lines suggesting text on the page.
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.55);
    final left = size.width * 0.24;
    final right = size.width * 0.76;
    for (final fy in [0.42, 0.58, 0.74]) {
      canvas.drawLine(
        Offset(left, size.height * fy),
        Offset(fy == 0.74 ? size.width * 0.58 : right, size.height * fy),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CornerFoldPainter oldDelegate) => oldDelegate.color != color;
}
