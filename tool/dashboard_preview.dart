// Local, offline QA entry point. Never used by lib/main.dart or deployments.
import 'package:acendra/app/providers/theme_mode_provider.dart';
import 'package:acendra/app/router/app_router.dart';
import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/providers/navigation_access_provider.dart';
import 'package:acendra/features/dashboard/data/dashboard_sample_data.dart';
import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:acendra/features/marketplace/domain/entities/category.dart';
import 'package:acendra/features/my_courses/data/repositories/supabase_my_courses_repository.dart';
import 'package:acendra/features/profile/presentation/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../test/features/marketplace/fakes/fake_course_repository.dart';
import '../test/features/my_courses/fakes/fake_my_courses_repository.dart';

class _PreviewTheme extends ThemeModeNotifier {
  @override
  ThemeMode build() => Uri.base.queryParameters['qaTheme'] == 'dark'
      ? ThemeMode.dark
      : ThemeMode.light;
}

void main() => runApp(
  ProviderScope(
    overrides: [
      sessionRestoredProvider.overrideWithValue(true),
      isAuthenticatedProvider.overrideWithValue(true),
      authStreamProvider.overrideWith((ref) => const Stream.empty()),
      navigationAccessProvider.overrideWith((ref) async => false),
      displayNameProvider.overrideWithValue('QA Student'),
      currentEmailProvider.overrideWithValue('student@example.invalid'),
      themeModeProvider.overrideWith(_PreviewTheme.new),
      courseRepositoryProvider.overrideWithValue(
        FakeCourseRepository(
          result: sampleCourses,
          categories: [
            for (final category in sampleCategories)
              Category(
                id: category.id,
                name: category.name,
                slug: category.slug,
              ),
          ],
        ),
      ),
      myCoursesRepositoryProvider.overrideWithValue(FakeMyCoursesRepository()),
    ],
    child: Consumer(
      builder: (_, ref, _) => MaterialApp.router(
        title: 'Acedra offline dashboard QA',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ref.watch(themeModeProvider),
        routerConfig: ref.watch(appRouterProvider),
      ),
    ),
  ),
);
