import 'package:acendra/app/router/route_names.dart';
import 'package:acendra/features/dashboard/domain/entities/dashboard_category.dart';
import 'package:acendra/features/dashboard/domain/entities/hero_slide.dart';
import 'package:acendra/features/dashboard/domain/entities/why_learn_item.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:acendra/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Neutral discovery copy is not a simulated course or promotion.
final heroSlidesProvider = Provider<List<HeroSlide>>(
  (ref) => const [
    HeroSlide(
      id: 'explore',
      label: 'EXPLORE',
      headline: 'Your next chapter starts here',
      subtext: 'Browse available courses and find something new to learn.',
      ctaLabel: 'Explore Courses',
      ctaRoute: RouteNames.marketplace,
    ),
  ],
);

final dashboardCategoriesProvider = FutureProvider<List<DashboardCategory>>((
  ref,
) async {
  final categories = await ref.watch(categoriesProvider.future);
  return [
    for (final category in categories)
      DashboardCategory(
        id: category.id,
        name: category.name,
        slug: category.slug,
        icon: switch (category.slug) {
          'development' => DashboardCategoryIcon.development,
          'design' => DashboardCategoryIcon.design,
          'business' => DashboardCategoryIcon.business,
          'languages' => DashboardCategoryIcon.languages,
          _ => DashboardCategoryIcon.general,
        },
      ),
  ];
});

final featuredCoursesProvider = FutureProvider<List<CourseSummary>>((
  ref,
) async {
  final courses = [...await ref.watch(marketplaceProvider.future)];
  courses.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
  return courses.take(6).toList();
});

final whyLearnItemsProvider = Provider<List<WhyLearnItem>>(
  (ref) => const [
    WhyLearnItem(
      id: 'flexible-learning',
      title: 'Learn at your pace',
      subtitle: 'Make learning part of your own schedule.',
      icon: WhyLearnIcon.flexibleLearning,
    ),
    WhyLearnItem(
      id: 'practical-skills',
      title: 'Explore practical skills',
      subtitle: 'Find subjects connected to your interests and goals.',
      icon: WhyLearnIcon.practicalSkills,
    ),
    WhyLearnItem(
      id: 'learning-materials',
      title: 'Explore learning materials',
      subtitle: 'Discover courses with lessons and supporting resources.',
      icon: WhyLearnIcon.learningMaterials,
    ),
    WhyLearnItem(
      id: 'progress',
      title: 'Continue your journey',
      subtitle: 'Return to your learning and take the next step.',
      icon: WhyLearnIcon.progress,
    ),
  ],
);

typedef DashboardHomeData = ({
  List<HeroSlide> slides,
  List<DashboardCategory> categories,
  List<CourseSummary> courses,
  List<WhyLearnItem> highlights,
});

final dashboardHomeProvider = FutureProvider<DashboardHomeData>((ref) async {
  final categories = ref.watch(dashboardCategoriesProvider.future);
  final courses = ref.watch(featuredCoursesProvider.future);
  final slides = ref.watch(heroSlidesProvider);
  final highlights = ref.watch(whyLearnItemsProvider);
  // Join both futures so either failing read is handled by this boundary.
  final values = await Future.wait<Object>([categories, courses]);
  return (
    slides: slides,
    categories: values[0] as List<DashboardCategory>,
    courses: values[1] as List<CourseSummary>,
    highlights: highlights,
  );
});
