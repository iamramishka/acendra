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
