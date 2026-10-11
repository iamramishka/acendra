import 'package:acendra/features/marketplace/data/models/course_summary_dto.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CourseSummaryDto.fromJson', () {
    const rawJson = {
      'id': '08100000-0000-0000-0000-000000000011',
      'slug': 'synthetic-published-course',
      'title': 'Synthetic published course',
      'short_description': 'Development catalog fixture',
      'price_minor': 125000,
      'currency_code': 'LKR',
      'published_at': '2026-10-11T00:00:00Z',
    };

    test('parses all fields into CourseSummary', () {
      final course = CourseSummaryDto.fromJson(rawJson);
      expect(course, isA<CourseSummary>());
      expect(course.id, '08100000-0000-0000-0000-000000000011');
      expect(course.slug, 'synthetic-published-course');
      expect(course.title, 'Synthetic published course');
      expect(course.shortDescription, 'Development catalog fixture');
      expect(course.priceMinor, 125000);
      expect(course.currencyCode, 'LKR');
    });

    test('accepts a published course without a short description', () {
      final nullableJson = Map<String, dynamic>.from(rawJson)
        ..['short_description'] = null;
      final course = CourseSummaryDto.fromJson(nullableJson);
      expect(course.id, rawJson['id']);
      expect(course.shortDescription, '');
    });

    test('throws ArgumentError when required field is missing', () {
      final bad = Map<String, dynamic>.from(rawJson)..remove('id');
      expect(() => CourseSummaryDto.fromJson(bad), throwsArgumentError);
    });
  });
}
