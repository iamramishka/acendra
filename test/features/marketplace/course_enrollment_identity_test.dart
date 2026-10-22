import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/marketplace/data/repositories/supabase_course_repository.dart';
import 'package:acendra/features/marketplace/presentation/providers/marketplace_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes/fake_course_repository.dart';

class _Repository extends FakeCourseRepository {
  _Repository(this.actor);
  final String Function() actor;
  int reads = 0;

  @override
  Future<bool> isEnrolled(String courseId) async {
    reads++;
    return actor() == 'student-a';
  }
}

Session _session(String id) => Session(
  accessToken: 'synthetic-$id',
  tokenType: 'bearer',
  user: User(
    id: id,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-10-22',
  ),
);

void main() {
  test('enrollment never carries from one account into another', () async {
    final identity = StateProvider<String>((ref) => 'student-a');
    final container = ProviderContainer(
      overrides: [
        currentSessionProvider.overrideWith(
          (ref) => _session(ref.watch(identity)),
        ),
        courseRepositoryProvider.overrideWith(
          (ref) => _Repository(() => ref.read(identity)),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      isEnrolledProvider('course-a'),
      (_, _) {},
    );
    addTearDown(subscription.close);
    expect(await container.read(isEnrolledProvider('course-a').future), isTrue);
    container.read(identity.notifier).state = 'student-b';
    expect(
      await container.read(isEnrolledProvider('course-a').future),
      isFalse,
    );
    expect((container.read(courseRepositoryProvider) as _Repository).reads, 2);
  });

  test('returning to course details rechecks enrollment', () async {
    var actor = 'student-b';
    final repository = _Repository(() => actor);
    final container = ProviderContainer(
      overrides: [courseRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      isEnrolledProvider('course-a'),
      (_, _) {},
    );
    expect(
      await container.read(isEnrolledProvider('course-a').future),
      isFalse,
    );
    subscription.close();
    await container.pump();
    actor = 'student-a';
    final returned = container.listen(
      isEnrolledProvider('course-a'),
      (_, _) {},
    );
    addTearDown(returned.close);
    expect(await container.read(isEnrolledProvider('course-a').future), isTrue);
    expect(repository.reads, 2);
  });
}
