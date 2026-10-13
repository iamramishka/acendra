import 'dart:js_interop';
import 'package:flutter_test/flutter_test.dart';

@JS('document.querySelectorAll')
external _Nodes _query(String selector);
extension type _Nodes(JSObject _) implements JSObject {
  external int get length;
  external _Node item(int index);
}
extension type _Node(JSObject _) implements JSObject {
  external String? get textContent;
}
void verifyNoPayloadElements() {
  expect(_query('img[onerror], svg[onload]').length, 0);
  final scripts = _query('script');
  for (var i = 0; i < scripts.length; i++) {
    expect(
      scripts.item(i).textContent ?? '',
      isNot(contains('alert("CSA187")')),
    );
  }
}
