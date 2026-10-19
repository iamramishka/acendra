import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;
import '../domain/media_file.dart';
export '../domain/media_file.dart';

Future<MediaFile?> pickMediaFile({bool pdf = false}) async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = pdf ? '.pdf' : '.jpg,.jpeg,.png'
    ..style.display = 'none';
  final result = Completer<MediaFile?>();
  var reading = false;
  final change = ((web.Event event) {
    if (reading || result.isCompleted) return;
    reading = true;
    () async {
      try {
        final file = input.files?.item(0);
        if (file == null) {
          result.complete(null);
          return;
        }
        final error = mediaFileError(file.name, file.size, pdf: pdf);
        if (error != null) throw FormatException(error);
        final buffer = await file.arrayBuffer().toDart;
        result.complete(
          MediaFile(name: file.name, bytes: buffer.toDart.asUint8List()),
        );
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    }();
  }).toJS;
  final cancel = ((web.Event event) {
    if (!reading && !result.isCompleted) result.complete(null);
  }).toJS;
  input.addEventListener('change', change);
  input.addEventListener('cancel', cancel);
  final body = web.document.body;
  if (body == null) return null;
  body.appendChild(input);
  try {
    input.click();
    return await result.future;
  } finally {
    input.removeEventListener('change', change);
    input.removeEventListener('cancel', cancel);
    input.remove();
  }
}
