import 'package:flutter/material.dart';
import '../models/puzzle.dart';
import '../services/palette.dart';

/// Edge state: 0 = unknown, 1 = line (loop edge), 2 = X (marked not-edge)
class BoardPainter extends CustomPainter {
  final Puzzle puzzle;
  final List<List<int>> hState; // (h+1) x w
  final List<List<int>> vState; // h x (w+1)
  final Set<String> badDots; // "r,c" dots with degree > 2 or dangling

  BoardPainter({
    required this.puzzle,
    required this.hState,
    required this.vState,
    required this.badDots,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final h = puzzle.h, w = puzzle.w;
    final cell = size.width / w;

    // paper background
    canvas.drawRect(Offset.zero & size, Paint()..color = Palette.board);

    // faint base grid (helper lines)
    final base = Paint()
      ..color = Palette.inkDim.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (int r = 0; r <= h; r++) {
      canvas.drawLine(Offset(0, r * cell), Offset(size.width, r * cell), base);
    }
    for (int c = 0; c <= w; c++) {
      canvas.drawLine(Offset(c * cell, 0), Offset(c * cell, size.height), base);
    }

    // horizontal edges
    for (int r = 0; r <= h; r++) {
      for (int c = 0; c < w; c++) {
        final s = hState[r][c];
        final p1 = Offset(c * cell, r * cell);
        final p2 = Offset((c + 1) * cell, r * cell);
        _drawEdge(canvas, p1, p2, s, cell);
      }
    }
    // vertical edges
    for (int r = 0; r < h; r++) {
      for (int c = 0; c <= w; c++) {
        final s = vState[r][c];
        final p1 = Offset(c * cell, r * cell);
        final p2 = Offset(c * cell, (r + 1) * cell);
        _drawEdge(canvas, p1, p2, s, cell);
      }
    }

    // dots
    for (int r = 0; r <= h; r++) {
      for (int c = 0; c <= w; c++) {
        final isBad = badDots.contains('$r,$c');
        if (isBad) {
          final haloPaint = Paint()
            ..color = Palette.coral
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.03;
          canvas.drawCircle(Offset(c * cell, r * cell), cell * 0.16, haloPaint);
          canvas.drawCircle(Offset(c * cell, r * cell), cell * 0.08,
              Paint()..color = Palette.coral);
        } else {
          canvas.drawCircle(Offset(c * cell, r * cell), cell * 0.045,
              Paint()..color = Palette.ink.withValues(alpha: 0.75));
        }
      }
    }

    // clue numbers
    for (int r = 0; r < h; r++) {
      for (int c = 0; c < w; c++) {
        final v = puzzle.clues[r][c];
        if (v >= 0) {
          final center = Offset((c + 0.5) * cell, (r + 0.5) * cell);
          final tp = TextPainter(
            text: TextSpan(
                text: '$v',
                style: TextStyle(
                    color: Palette.paperText,
                    fontSize: cell * 0.44,
                    fontWeight: FontWeight.w700)),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
        }
      }
    }
  }

  void _drawEdge(Canvas canvas, Offset p1, Offset p2, int s, double cell) {
    if (s == 1) {
      final p = Paint()
        ..color = Palette.ink
        ..strokeWidth = cell * 0.09
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p1, p2, p);
    } else if (s == 2) {
      // small X mark at midpoint
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      final p = Paint()
        ..color = Palette.crossRed.withValues(alpha: 0.75)
        ..strokeWidth = cell * 0.035
        ..strokeCap = StrokeCap.round;
      final sz = cell * 0.09;
      canvas.drawLine(mid + Offset(-sz, -sz), mid + Offset(sz, sz), p);
      canvas.drawLine(mid + Offset(-sz, sz), mid + Offset(sz, -sz), p);
    }
    // unknown (0): draw nothing extra beyond base grid
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) =>
      old.hState != hState ||
      old.vState != vState ||
      old.badDots != badDots ||
      old.puzzle != puzzle;
}
