import '../domain/media_file.dart';
export '../domain/media_file.dart';

Future<MediaFile?> pickMediaFile({bool pdf = false}) async =>
    throw UnsupportedError('File selection requires a web browser.');
