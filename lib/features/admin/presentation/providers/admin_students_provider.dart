import 'package:acendra/features/admin/data/repositories/admin_student_repository.dart';
import 'package:acendra/features/admin/domain/entities/admin_student.dart';
import 'package:acendra/features/admin/domain/entities/student_enrollment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminStudentsNotifier extends AsyncNotifier<List<AdminStudent>> {
  String _searchQuery = '';
  int _generation = 0;

  @override
  Future<List<AdminStudent>> build() {
    _searchQuery = '';
    _generation++;
    ref.onDispose(() => _generation++);
    return ref
        .watch(adminStudentRepositoryProvider)
        .listStudents(searchQuery: _searchQuery);
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    final generation = ++_generation;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(adminStudentRepositoryProvider)
          .listStudents(searchQuery: query),
    );
    if (ref.mounted && generation == _generation) state = result;
  }

  Future<void> refresh() async {
    await search(_searchQuery);
  }
}

final adminStudentsProvider =
    AsyncNotifierProvider<AdminStudentsNotifier, List<AdminStudent>>(
      AdminStudentsNotifier.new,
    );

final studentDetailProvider = FutureProvider.family<AdminStudent, String>((
  ref,
  studentId,
) async {
  return ref.watch(adminStudentRepositoryProvider).getStudent(studentId);
});

final studentEnrollmentsProvider =
    FutureProvider.family<List<StudentEnrollment>, String>((
      ref,
      studentId,
    ) async {
      return ref
          .watch(adminStudentRepositoryProvider)
          .getEnrollments(studentId);
    });
