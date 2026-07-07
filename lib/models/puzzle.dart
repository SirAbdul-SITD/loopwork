class Puzzle {
  final int id;
  final String tier;
  final int h;
  final int w;
  final List<List<int>> clues; // -1 = empty, else 0-4
  final List<List<bool>> hedgeSolution; // (h+1) x w
  final List<List<bool>> vedgeSolution; // h x (w+1)

  Puzzle({
    required this.id,
    required this.tier,
    required this.h,
    required this.w,
    required this.clues,
    required this.hedgeSolution,
    required this.vedgeSolution,
  });

  factory Puzzle.fromJson(Map<String, dynamic> j) {
    final h = j['h'] as int;
    final w = j['w'] as int;
    final cl = (j['clues'] as List).map((e) => e as int).toList();
    final hf = (j['hedge'] as List).map((e) => e as int).toList();
    final vf = (j['vedge'] as List).map((e) => e as int).toList();
    return Puzzle(
      id: j['id'] as int,
      tier: j['tier'] as String,
      h: h,
      w: w,
      clues: List.generate(h, (r) => List.generate(w, (c) => cl[r * w + c])),
      hedgeSolution: List.generate(
          h + 1, (r) => List.generate(w, (c) => hf[r * w + c] == 1)),
      vedgeSolution: List.generate(
          h, (r) => List.generate(w + 1, (c) => vf[r * (w + 1) + c] == 1)),
    );
  }

  int get clueCount {
    int n = 0;
    for (final row in clues) {
      for (final v in row) {
        if (v >= 0) n++;
      }
    }
    return n;
  }
}
