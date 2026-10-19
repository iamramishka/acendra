import 'dart:async';
import 'dart:js_interop';

import 'package:acendra/features/profile/domain/avatar_file.dart';
import 'package:web/web.dart' as web;

/// Opens the browser file chooser for an image. Returns null if cancelled;
/// throws [FormatException] (user-facing message) for an invalid file.
Future<AvatarFile?> pickAvatarFile() async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = kAvatarAccept
    ..style.display = 'none';
  final result = Completer<AvatarFile?>();
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
        final error = avatarFileError(file.name, file.size);
        if (error != null) throw FormatException(error);
        final buffer = await file.arrayBuffer().toDart;
        result.complete(
          AvatarFile(name: file.name, bytes: buffer.toDart.asUint8List()),
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
