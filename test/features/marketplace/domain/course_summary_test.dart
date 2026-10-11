import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CourseSummary', () {
    test('stores all fields', () {
      const c = CourseSummary(
        id: 'id-1',
        slug: 'flutter-basics',
        title: 'Flutter Basics',
        shortDescription: 'Learn Flutter.',
        priceMinor: 125000,
        currencyCode: 'LKR',
        publishedAt: '2026-10-11T00:00:00Z',
      );
      expect(c.id, 'id-1');
      expect(c.priceMinor, 125000);
      expect(c.formattedPrice, 'LKR 1,250.00');
    });

    test('formattedPrice handles zero minor units', () {
      const c = CourseSummary(
        id: 'x',
        slug: 'free',
        title: 'Free',
        shortDescription: '',
        priceMinor: 0,
        currencyCode: 'LKR',
        publishedAt: '2026-10-11T00:00:00Z',
      );
      expect(c.formattedPrice, 'LKR 0.00');
    });
  });
}
