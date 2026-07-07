import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/puzzle.dart';
import '../painters/board_painter.dart';
import '../services/palette.dart';
import '../services/progress_service.dart';
import '../services/settings_service.dart';
import '../services/audio_manager.dart';

class GameScreen extends StatefulWidget {
  final Puzzle puzzle;
  final AudioManager audio;
  final VoidCallback? onNext;
  const GameScreen({
    super.key,
    required this.puzzle,
    required this.audio,
    this.onNext,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<List<int>> hState; // (h+1) x w : 0 unknown, 1 line, 2 X
  late List<List<int>> vState; // h x (w+1)
  bool won = false;
  int moves = 0;
  double _cell = 1;

  int get _h => widget.puzzle.h;
  int get _w => widget.puzzle.w;

  @override
  void initState() {
    super.initState();
    hState = List.generate(_h + 1, (_) => List.filled(_w, 0));
    vState = List.generate(_h, (_) => List.filled(_w + 1, 0));
  }

  void _haptic() {
    if (context.read<SettingsService>().haptics) {
      HapticFeedback.selectionClick();
    }
  }

  /// Find nearest edge (h or v) to a tap point; returns ('h'|'v', r, c) or null
  /// if the tap is too far from any edge midpoint.
  (String, int, int)? _nearestEdge(Offset local) {
    final cell = _cell;
    double best = double.infinity;
    String? bestKind;
    int bestR = 0, bestC = 0;
    for (int r = 0; r <= _h; r++) {
      for (int c = 0; c < _w; c++) {
        final mid = Offset((c + 0.5) * cell, r * cell);
        final d = (local - mid).distance;
        if (d < best) {
          best = d;
          bestKind = 'h';
          bestR = r;
          bestC = c;
        }
      }
    }
    for (int r = 0; r < _h; r++) {
      for (int c = 0; c <= _w; c++) {
        final mid = Offset(c * cell, (r + 0.5) * cell);
        final d = (local - mid).distance;
        if (d < best) {
          best = d;
          bestKind = 'v';
          bestR = r;
          bestC = c;
        }
      }
    }
    if (best > cell * 0.42) return null;
    return (bestKind!, bestR, bestC);
  }

  void _onTap(Offset local) {
    if (won) return;
    final edge = _nearestEdge(local);
    if (edge == null) return;
    final (kind, r, c) = edge;
    setState(() {
      final grid = kind == 'h' ? hState : vState;
      grid[r][c] = (grid[r][c] + 1) % 3;
      moves++;
    });
    final grid = kind == 'h' ? hState : vState;
    final val = grid[r][c];
    if (val == 1) {
      widget.audio.draw();
    } else if (val == 2) {
      widget.audio.mark();
    } else {
      widget.audio.erase();
    }
    _haptic();
    _checkWin();
  }

  List<(String, int, int)> _dotEdges(int r, int c) {
    final out = <(String, int, int)>[];
    if (c > 0) out.add(('h', r, c - 1));
    if (c < _w) out.add(('h', r, c));
    if (r > 0) out.add(('v', r - 1, c));
    if (r < _h) out.add(('v', r, c));
    return out;
  }

  int _edgeVal(String kind, int r, int c) =>
      kind == 'h' ? hState[r][c] : vState[r][c];

  Set<String> _badDots() {
    final out = <String>{};
    for (int r = 0; r <= _h; r++) {
      for (int c = 0; c <= _w; c++) {
        final edges = _dotEdges(r, c);
        final onCount =
            edges.where((e) => _edgeVal(e.$1, e.$2, e.$3) == 1).length;
        if (onCount > 2) out.add('$r,$c');
      }
    }
    return out;
  }

  void _checkWin() {
    final p = widget.puzzle;
    for (final row in hState) {
      if (row.contains(0)) return;
    }
    for (final row in vState) {
      if (row.contains(0)) return;
    }
    bool match = true;
    for (int r = 0; r <= _h && match; r++) {
      for (int c = 0; c < _w; c++) {
        final want = p.hedgeSolution[r][c];
        final got = hState[r][c] == 1;
        if (want != got) {
          match = false;
          break;
        }
      }
    }
    for (int r = 0; r < _h && match; r++) {
      for (int c = 0; c <= _w; c++) {
        final want = p.vedgeSolution[r][c];
        final got = vState[r][c] == 1;
        if (want != got) {
          match = false;
          break;
        }
      }
    }
    if (match) {
      won = true;
      widget.audio.win();
      final stars = _starRating();
      context.read<ProgressService>().recordWin(p.id, stars);
      Future.delayed(const Duration(milliseconds: 300), _showWinSheet);
    }
  }

  int _starRating() {
    final totalEdges = (_h + 1) * _w + _h * (_w + 1);
    final par = (totalEdges * 0.75).round();
    if (moves <= par) return 3;
    if (moves <= (par * 1.4).round()) return 2;
    return 1;
  }

  void _showWinSheet() {
    final stars = _starRating();
    showModalBottomSheet(
      context: context,
      backgroundColor: Palette.panel,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Loop Closed',
                style: TextStyle(
                    color: Palette.parchmentLight,
                    fontSize: 24,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    color: i < stars ? Palette.gold : Palette.haze,
                    size: 44,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Solved in $moves taps',
                style: const TextStyle(color: Palette.haze, fontSize: 14)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Palette.parchmentLight,
                      side: const BorderSide(color: Palette.line),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Levels'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.gold,
                      foregroundColor: Palette.void_,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      widget.onNext?.call();
                    },
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      hState = List.generate(_h + 1, (_) => List.filled(_w, 0));
      vState = List.generate(_h, (_) => List.filled(_w + 1, 0));
      moves = 0;
      won = false;
    });
    widget.audio.tap();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.puzzle;
    final badDots = _badDots();
    return Scaffold(
      backgroundColor: Palette.void_,
      appBar: AppBar(
        backgroundColor: Palette.void_,
        elevation: 0,
        foregroundColor: Palette.parchmentLight,
        title: Text('Level ${p.id + 1}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reset),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Tap near an edge to cycle it: line → X → blank. Draw a single '
                'closed loop so each number matches the lines touching its cell.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Palette.haze.withValues(alpha: 0.9),
                    fontSize: 12.5,
                    height: 1.4),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Center(
                child: LayoutBuilder(builder: (context, cons) {
                  final side = (cons.maxWidth < cons.maxHeight
                          ? cons.maxWidth
                          : cons.maxHeight) -
                      32;
                  _cell = side / _w;
                  return GestureDetector(
                    onTapUp: (d) => _onTap(d.localPosition),
                    child: CustomPaint(
                      size: Size(side, side),
                      painter: BoardPainter(
                        puzzle: p,
                        hState: hState,
                        vState: vState,
                        badDots: badDots,
                      ),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Taps: $moves',
                      style: const TextStyle(color: Palette.haze, fontSize: 14)),
                  Text(p.tier.toUpperCase(),
                      style: TextStyle(
                          color: Palette.tierColors[p.tier],
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
