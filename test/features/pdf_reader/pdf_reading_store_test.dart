import 'package:acendra/features/pdf_reader/data/pdf_reading_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, String> storage;
  PdfReadingStore store(String user, [String lesson = 'lesson']) =>
      PdfReadingStore(
        userId: user,
        lessonId: lesson,
        read: (key) => storage[key],
        write: (key, value) => storage[key] = value,
      );
  setUp(() => storage = {});
  test('page 1 replaces a previously saved page', () {
    store('a').savePage(8);
    expect(store('a').loadPage(10), 8);
    store('a').savePage(1);
    expect(store('a').loadPage(10), 1);
  });
  test(
    'students and lessons cannot restore one another\'s positions or bookmarks',
    () {
      store('a').savePage(4);
      store('a').saveBookmarks([2, 4]);
      expect(store('b').loadPage(10), 1);
      expect(store('b').loadBookmarks(10), isEmpty);
      expect(store('a', 'other').loadPage(10), 1);
      expect(store('a').loadBookmarks(10), [2, 4]);
    },
  );
  test('stale pages, duplicates and out-of-range bookmarks are bounded', () {
    store('a').savePage(8);
    store('a').saveBookmarks([4, 2, 2, 501, -1, 9]);
    expect(store('a').loadPage(3), 1);
    expect(store('a').loadBookmarks(5), [2, 4]);
  });
  test('unavailable or corrupted storage does not stop reading', () {
    final unavailable = PdfReadingStore(
      userId: 'a',
      lessonId: 'b',
      read: (_) => throw StateError('private mode'),
      write: (_, value) => throw StateError('quota'),
    );
    expect(unavailable.loadPage(10), 1);
    expect(unavailable.loadBookmarks(10), isEmpty);
    unavailable.savePage(1);
    unavailable.saveBookmarks([1]);
    storage['acendra_pdf_v2_a_lesson_bookmarks'] = '{invalid';
    expect(store('a').loadBookmarks(10), isEmpty);
  });
}
