import 'package:acendra/features/dashboard/data/dashboard_sample_data.dart';
import 'package:acendra/features/dashboard/domain/entities/dashboard_category.dart';
import 'package:acendra/features/dashboard/domain/entities/hero_slide.dart';
import 'package:acendra/features/dashboard/domain/entities/why_learn_item.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Offline preview sources. Override these when integrating trusted live data.
final heroSlidesProvider = Provider<List<HeroSlide>>((ref) => sampleHeroSlides);

final dashboardCategoriesProvider = Provider<List<DashboardCategory>>(
  (ref) => sampleCategories,
);

final featuredCoursesProvider = Provider<List<CourseSummary>>(
  (ref) => sampleCourses,
);

final whyLearnItemsProvider = Provider<List<WhyLearnItem>>(
  (ref) => sampleWhyLearnItems,
);

typedef DashboardHomeData = ({
  List<HeroSlide> slides,
  List<DashboardCategory> categories,
  List<CourseSummary> courses,
  List<WhyLearnItem> highlights,
});

/// Composes the four offline sources behind a loading/error/retry boundary.
/// This does not fetch live data or establish backend course identities.
final dashboardHomeProvider = FutureProvider<DashboardHomeData>(
  (ref) => (
    slides: ref.watch(heroSlidesProvider),
    categories: ref.watch(dashboardCategoriesProvider),
    courses: ref.watch(featuredCoursesProvider),
    highlights: ref.watch(whyLearnItemsProvider),
  ),
);
