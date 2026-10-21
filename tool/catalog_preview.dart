// Offline QA entry point only. Production starts at lib/main.dart.
import 'package:acendra/app/theme/app_theme.dart';
import 'package:acendra/features/checkout/data/repositories/student_order_repository.dart';
import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:acendra/features/marketplace/presentation/screens/course_detail_screen.dart';
import 'package:acendra/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../test/features/marketplace/fixtures/catalog_preview_fixtures.dart';

void main() => runApp(const CatalogPreviewApp());

class CatalogPreviewApp extends StatefulWidget {
  const CatalogPreviewApp({super.key, this.dark = false, this.textScale = 1});
  final bool dark;
  final double textScale;

  @override
  State<CatalogPreviewApp> createState() => _CatalogPreviewAppState();
}

class _CatalogPreviewAppState extends State<CatalogPreviewApp> {
  late bool _dark = widget.dark;
  late final _router = GoRouter(
    initialLocation: '/marketplace',
    routes: [
      GoRoute(
        path: '/marketplace',
        builder: (_, _) => Scaffold(
          appBar: AppBar(
            title: const Text('Acedra'),
            actions: [
              IconButton(
                tooltip: 'Toggle preview theme',
                onPressed: () => setState(() => _dark = !_dark),
                icon: const Icon(Icons.brightness_6_outlined),
              ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(24),
              child: Text('Local preview · synthetic course data'),
            ),
          ),
          body: const MarketplaceScreen(),
        ),
      ),
      GoRoute(
        path: '/marketplace/:courseId',
        builder: (_, state) =>
            CourseDetailScreen(courseId: state.pathParameters['courseId']!),
      ),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      courseRepositoryProvider.overrideWithValue(CatalogPreviewRepository()),
      openCourseOrderProvider.overrideWith((ref, courseId) async => null),
    ],
    child: MaterialApp.router(
      title: 'Acedra catalog offline QA',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(widget.textScale)),
        child: child!,
      ),
    ),
  );
}
