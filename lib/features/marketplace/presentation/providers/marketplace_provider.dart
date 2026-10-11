import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MarketplaceNotifier extends AsyncNotifier<List<CourseSummary>> {
  @override
  Future<List<CourseSummary>> build() {
    return ref.read(courseRepositoryProvider).listPublished();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(courseRepositoryProvider).listPublished(),
    );
  }
}

final marketplaceProvider =
    AsyncNotifierProvider<MarketplaceNotifier, List<CourseSummary>>(
      MarketplaceNotifier.new,
    );
