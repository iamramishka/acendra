import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import '../domain/entities/pdf_outline_entry.dart';

@JS('pdfjsLib')
external _PdfLibrary? get _library;
extension type _PdfLibrary(JSObject _) implements JSObject {
  external _Task getDocument(JSObject options);
}
extension type _Task(JSObject _) implements JSObject {
  external JSPromise<_Document> get promise;
  external JSPromise<JSAny?> destroy();
}
extension type _Document(JSObject _) implements JSObject {
  external int get numPages;
  external JSPromise<JSArray<JSObject>?> getOutline();
  external JSPromise<JSArray<JSAny?>?> getDestination(String name);
  external JSPromise<JSNumber> getPageIndex(JSObject reference);
}

/// Read local destinations from authenticated derivative bytes using the
/// bundled renderer's public API. pdfx exposes no outline API. Destroy this
/// parser before opening the renderer; never resolve remote destinations.
Future<List<PdfOutlineEntry>> loadPdfOutline(Uint8List bytes) async {
  final library = _library;
  if (library == null) throw StateError('PDF renderer unavailable');
  final task = library.getDocument(
    {
          'data': Uint8List.fromList(bytes).toJS,
          'isEvalSupported': false,
          'useSystemFonts': false,
        }.jsify()
        as JSObject,
  );
  try {
    return await (() async {
      final document = await task.promise.toDart;
      final outline = (await document.getOutline().toDart)?.dartify();
      final entries = <PdfOutlineEntry>[];
      var visited = 0;
      Future<void> visit(List<dynamic> items, int level) async {
        if (level > 8) return;
        for (final item in items) {
          if (++visited > 500) throw StateError('PDF outline exceeds limits');
          if (item is! Map) continue;
          final title = item['title'];
          var destination = item['dest'];
          if (destination is String) {
            destination = (await document.getDestination(destination).toDart)
                ?.dartify();
          }
          if (item['url'] == null &&
              title is String &&
              destination is List &&
              destination.isNotEmpty) {
            final reference = destination.first;
            final int? page;
            if (reference is num &&
                reference.isFinite &&
                reference == reference.roundToDouble()) {
              page = reference.toInt() + 1;
            } else if (reference is Map &&
                reference['num'] is num &&
                reference['gen'] is num) {
              page =
                  (await document
                          .getPageIndex(reference.jsify() as JSObject)
                          .toDart)
                      .toDartInt +
                  1;
            } else {
              page = null;
            }
            final label = title
                .replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '')
                .trim();
            if (page != null &&
                page >= 1 &&
                page <= document.numPages &&
                label.isNotEmpty) {
              entries.add(
                PdfOutlineEntry(
                  title: label.length > 200 ? label.substring(0, 200) : label,
                  page: page,
                  level: level,
                ),
              );
            }
          }
          if (item['items'] is List) {
            await visit(item['items'] as List, level + 1);
          }
        }
      }

      if (outline is List) await visit(outline, 0);
      return entries;
    })().timeout(const Duration(seconds: 10));
  } finally {
    await task.destroy().toDart;
  }
}
