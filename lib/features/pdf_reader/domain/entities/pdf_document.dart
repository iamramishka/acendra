import 'package:flutter/foundation.dart';

@immutable
class PdfDocument {
  const PdfDocument({
    required this.id,
    required this.title,
    required this.url,
    this.pageCount,
  });

  final String id;
  final String title;

  /// Signed URL from Supabase Storage — expires; never expose as permanent link.
  final String url;

  /// Null until the pdfx document is loaded and reports page count.
  final int? pageCount;

  PdfDocument copyWith({
    String? id,
    String? title,
    String? url,
    int? pageCount,
    bool clearPageCount = false,
  }) => PdfDocument(
    id: id ?? this.id,
    title: title ?? this.title,
    url: url ?? this.url,
    pageCount: clearPageCount ? null : (pageCount ?? this.pageCount),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfDocument &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          url == other.url &&
          pageCount == other.pageCount;

  @override
  int get hashCode => Object.hash(id, title, url, pageCount);
}
