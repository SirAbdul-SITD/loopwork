import 'package:flutter/material.dart';

/// Noir ink-on-paper theme: cool grey paper, deep ink loop, red-pencil marks.
class Palette {
  // Surfaces
  static const void_ = Color(0xFF16181C); // deepest background
  static const panel = Color(0xFF1E2126); // panel
  static const raised = Color(0xFF262A31); // raised surface
  static const board = Color(0xFFEDEAE2); // paper board background

  // Loop / marks
  static const ink = Color(0xFF1A1D22); // the drawn loop
  static const inkDim = Color(0xFF3A3F47); // dot grid, unfilled edges
  static const crossRed = Color(0xFFB5473F); // "definitely not an edge" mark
  static const previewGold = Color(0xFFC9A227);

  // Text
  static const paperText = Color(0xFF20242A);
  static const parchmentLight = Color(0xFFF4F1E9);
  static const haze = Color(0xFF9AA1AC);
  static const line = Color(0xFF33373E);

  // Accents
  static const gold = Color(0xFFC9A227);
  static const teal = Color(0xFF3D8E86);
  static const coral = Color(0xFFB5473F);

  static const tierColors = {
    'easy': Color(0xFF3D8E86),
    'medium': Color(0xFFC9A227),
    'hard': Color(0xFFB5473F),
  };
}
