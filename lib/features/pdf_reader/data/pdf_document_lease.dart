/// Owns an asynchronously opened renderer resource, including late completion
/// after its reader has been removed. The document is closed exactly once.
class PdfDocumentLease<T> {
  PdfDocumentLease(Future<T> opening, this.close) {
    document = opening.then((value) async {
      _value = value;
      if (_released) {
        await _close();
      }
      return value;
    });
  }

  final Future<void> Function(T value) close;
  late final Future<T> document;
  T? _value;
  bool _released = false;
  Future<void>? _closing;

  Future<void> _close() => _closing ??= close(_value as T);

  Future<void> release() async {
    _released = true;
    if (_value != null) {
      await _close();
    }
  }
}
