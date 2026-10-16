import 'dart:async';

import 'package:acendra/features/admin/data/repositories/admin_course_repository.dart';
import 'package:acendra/features/admin/data/repositories/admin_directory_client.dart';
import 'package:acendra/features/admin/data/repositories/admin_student_repository.dart';
import 'package:acendra/features/admin/domain/entities/admin_course.dart';
import 'package:acendra/features/admin/domain/entities/admin_student.dart';
import 'package:acendra/features/admin/domain/entities/curriculum_section.dart';
import 'package:acendra/features/admin/domain/entities/student_enrollment.dart';
import 'package:acendra/features/admin/presentation/providers/admin_courses_provider.dart';
import 'package:acendra/features/admin/presentation/providers/admin_students_provider.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _session = StateProvider<Session?>((_) => _identity('admin-a'));
Session _identity(String id) => Session(
  accessToken: 'synthetic',
  tokenType: 'bearer',
  user: User(
    id: id,
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-10-17',
  ),
);

AdminStudent _student(String account) => AdminStudent(
  id: 'student',
  email: '$account@synthetic.test',
  enrolledCourseCount: 0,
  totalAmountPaid: null,
  createdAt: DateTime(2026),
  isActive: true,
);
AdminCourse _course(String account) => AdminCourse(
  id: 'course',
  title: account,
  description: '',
  price: 0,
  isPublished: false,
  enrollmentCount: 0,
  sectionCount: 0,
  lessonCount: 0,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

class _Students implements AdminStudentRepository {
  _Students(this.account);
  final String account;
  Completer<List<AdminStudent>>? pending;
  String? lastSearch;
  @override
  Future<List<AdminStudent>> listStudents({String? searchQuery}) {
    lastSearch = searchQuery;
    return pending?.future ?? Future.value([_student(account)]);
  }

  @override
  Future<AdminStudent> getStudent(String id) async => _student(account);
  @override
  Future<List<StudentEnrollment>> getEnrollments(String id) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Courses implements AdminCourseRepository {
  _Courses(this.account);
  final String account;
  @override
  Future<List<AdminCourse>> listCourses() async => [_course(account)];
  @override
  Future<AdminCourse> getCourse(String id) async => _course(account);
  @override
  Future<List<AdminCurriculumSection>> getCurriculum(String id) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ProviderContainer container;
  late Map<String, _Students> students;
  late List<String> courseReads;
  setUp(() {
    students = {
      'admin-a': _Students('admin-a'),
      'admin-b': _Students('admin-b'),
    };
    courseReads = [];
    container = ProviderContainer(
      overrides: [
        currentSessionProvider.overrideWith((ref) => ref.watch(_session)),
        adminStudentRepositoryProvider.overrideWith((ref) {
          final session = ref.watch(currentSessionProvider);
          if (session == null) throw const AdminDataException('Signed out');
          return students[session.user.id]!;
        }),
        adminCourseRepositoryProvider.overrideWith((ref) {
          final session = ref.watch(currentSessionProvider);
          if (session == null) throw const AdminDataException('Signed out');
          courseReads.add(session.user.id);
          return _Courses(session.user.id);
        }),
      ],
    );
  });
  tearDown(() => container.dispose());

  test(
    'logout discards cached student list and detail; next account refetches',
    () async {
      container.listen(adminStudentsProvider, (_, _) {});
      container.listen(studentDetailProvider('student'), (_, _) {});
      expect(
        (await container.read(adminStudentsProvider.future)).single.email,
        'admin-a@synthetic.test',
      );
      await container.read(studentDetailProvider('student').future);
      container.read(_session.notifier).state = null;
      await expectLater(
        container.read(adminStudentsProvider.future),
        throwsA(
          predicate(
            (Object error) =>
                error.toString().contains('Signed out') ||
                error.toString().contains('Your session expired'),
          ),
        ),
      );
      await expectLater(
        container.read(studentDetailProvider('student').future),
        throwsA(
          predicate(
            (Object error) =>
                error.toString().contains('Signed out') ||
                error.toString().contains('Your session expired'),
          ),
        ),
      );
      expect(container.read(adminStudentsProvider).asData, isNull);
      expect(container.read(studentDetailProvider('student')).asData, isNull);
      container.read(_session.notifier).state = _identity('admin-b');
      expect(
        (await container.read(adminStudentsProvider.future)).single.email,
        'admin-b@synthetic.test',
      );
      expect(
        (await container.read(studentDetailProvider('student').future)).email,
        'admin-b@synthetic.test',
      );
    },
  );

  test(
    'account switch invalidates course lists, detail and curriculum providers',
    () async {
      container.listen(adminCoursesProvider, (_, _) {});
      container.listen(adminCourseDetailProvider('course'), (_, _) {});
      container.listen(adminCurriculumProvider('course'), (_, _) {});
      final lesson = adminLessonDetailProvider((
        courseId: 'course',
        lessonId: 'lesson',
      ));
      container.listen(lesson, (_, _) {});
      await container.read(adminCoursesProvider.future);
      await container.read(adminCourseDetailProvider('course').future);
      await container.read(adminCurriculumProvider('course').future);
      await container.read(lesson.future);
      container.read(_session.notifier).state = _identity('admin-b');
      expect(
        (await container.read(adminCoursesProvider.future)).single.title,
        'admin-b',
      );
      expect(
        (await container.read(
          adminCourseDetailProvider('course').future,
        )).title,
        'admin-b',
      );
      await container.read(adminCurriculumProvider('course').future);
      await container.read(lesson.future);
      expect(courseReads, ['admin-a', 'admin-b']);
    },
  );

  for (final operation in ['build', 'search', 'refresh']) {
    test(
      'old in-flight $operation cannot restore previous-account PII',
      () async {
        container.listen(adminStudentsProvider, (_, _) {});
        if (operation != 'build') {
          await container.read(adminStudentsProvider.future);
        }
        final pending = students['admin-a']!.pending =
            Completer<List<AdminStudent>>();
        Future<void>? request;
        if (operation == 'build') {
          container.invalidate(adminStudentsProvider);
          container.read(adminStudentsProvider);
        } else {
          final notifier = container.read(adminStudentsProvider.notifier);
          request = operation == 'search'
              ? notifier.search('private')
              : notifier.refresh();
        }
        container.read(_session.notifier).state = _identity('admin-b');
        expect(
          (await container.read(adminStudentsProvider.future)).single.email,
          'admin-b@synthetic.test',
        );
        expect(students['admin-b']!.lastSearch, '');
        pending.complete([_student('admin-a')]);
        await request;
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(adminStudentsProvider).requireValue.single.email,
          'admin-b@synthetic.test',
        );
      },
    );
  }

  test('default live repository providers reject signed-out access', () {
    final signedOut = ProviderContainer(
      overrides: [currentSessionProvider.overrideWithValue(null)],
    );
    addTearDown(signedOut.dispose);
    expect(
      () => signedOut.read(adminStudentRepositoryProvider),
      throwsA(
        predicate(
          (Object error) =>
              error.toString().contains('Signed out') ||
              error.toString().contains('Your session expired'),
        ),
      ),
    );
    expect(
      () => signedOut.read(adminCourseRepositoryProvider),
      throwsA(
        predicate(
          (Object error) =>
              error.toString().contains('Signed out') ||
              error.toString().contains('Your session expired'),
        ),
      ),
    );
  });
}
