import 'package:flutter/foundation.dart';

/// Immutable value object representing a bookmark in a PDF document.
@immutable
class PdfBookmark {
  const PdfBookmark({required this.page, this.label});

  /// 1-indexed page number this bookmark points to.
  final int page;

  /// Optional user-supplied or auto-generated label.
  final String? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfBookmark &&
          runtimeType == other.runtimeType &&
          page == other.page;

  @override
  int get hashCode => page.hashCode;
}
