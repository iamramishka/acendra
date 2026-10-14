import 'dart:async';
import 'package:acendra/features/pdf_reader/data/pdf_document_lease.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release closes a ready renderer document exactly once', () async {
    final resource = Object();
    final closed = <Object>[];
    final lease = PdfDocumentLease<Object>(Future.value(resource), (
      value,
    ) async {
      closed.add(value);
    });
    await lease.document;
    await lease.release();
    await lease.release();
    expect(closed, [resource]);
  });
  test(
    'release before open closes late document without resurrecting reader',
    () async {
      final opening = Completer<Object>();
      final resource = Object();
      final closed = <Object>[];
      final lease = PdfDocumentLease<Object>(opening.future, (value) async {
        closed.add(value);
      });
      await lease.release();
      expect(closed, isEmpty);
      opening.complete(resource);
      await lease.document;
      await lease.release();
      expect(closed, [resource]);
    },
  );
  test(
    'opening failure stays a failure and creates no close operation',
    () async {
      var closes = 0;
      final opening = Completer<Object>();
      final lease = PdfDocumentLease<Object>(opening.future, (_) async {
        closes++;
      });
      final assertion = expectLater(lease.document, throwsStateError);
      await lease.release();
      opening.completeError(StateError('synthetic renderer failure'));
      await assertion;
      expect(closes, 0);
    },
  );
}
