import 'package:acendra/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:acendra/features/marketplace/domain/entities/category.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:acendra/features/marketplace/domain/repositories/course_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Catalog implements CourseRepository {
  bool fail = false;
  @override
  Future<List<CourseSummary>> listPublished() async {
    if (fail) throw StateError('catalog unavailable');
    return [
      for (var i = 0; i < 8; i++)
        CourseSummary(
          id: 'real-$i',
          slug: 'course-$i',
          title: 'Published course $i',
          shortDescription: 'Published description',
          priceMinor: 25000,
          currencyCode: 'LKR',
          publishedAt: '2026-10-${10 + i}',
          categoryId: 'category-id',
        ),
    ];
  }

  @override
  Future<List<Category>> listCategories() async => const [
    Category(id: 'category-id', name: 'Photography', slug: 'photography'),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test(
    'discovery uses published identities, categories and latest six courses',
    () async {
      final container = ProviderContainer(
        overrides: [courseRepositoryProvider.overrideWithValue(_Catalog())],
      );
      addTearDown(container.dispose);
      final data = await container.read(dashboardHomeProvider.future);
      expect(data.courses.map((c) => c.id), [
        'real-7',
        'real-6',
        'real-5',
        'real-4',
        'real-3',
        'real-2',
      ]);
      expect(data.categories.single.id, 'category-id');
      expect(data.categories.single.name, 'Photography');
      expect(data.slides.single.ctaRoute, '/marketplace');
      expect(data.courses.any((c) => c.title.contains('Demo')), isFalse);
    },
  );
  test('failed catalog does not silently substitute sample courses', () async {
    final catalog = _Catalog()..fail = true;
    final container = ProviderContainer(
      overrides: [courseRepositoryProvider.overrideWithValue(catalog)],
    );
    addTearDown(container.dispose);
    await expectLater(
      container.read(dashboardHomeProvider.future),
      throwsStateError,
    );
  });
}
