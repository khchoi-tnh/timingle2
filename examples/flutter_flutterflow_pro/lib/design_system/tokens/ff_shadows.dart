import 'package:flutter/material.dart';

class FFShadows {
  // Subtle shadows for cards
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 12,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> xxl = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 16,
      offset: Offset(0, 12),
    ),
  ];

  // Elevated - For prominent elements
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 12,
      offset: Offset(0, 8),
    ),
  ];

  // Interactive - For hover/focus states
  static const List<BoxShadow> interactive = [
    BoxShadow(
      color: Color(0x0066CC),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
}
