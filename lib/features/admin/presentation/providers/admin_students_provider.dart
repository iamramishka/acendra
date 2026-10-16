import 'package:acendra/features/admin/data/repositories/admin_student_repository.dart';
import 'package:acendra/features/admin/domain/entities/admin_student.dart';
import 'package:acendra/features/admin/domain/entities/student_enrollment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminStudentsNotifier extends AsyncNotifier<List<AdminStudent>> {
  String _searchQuery = '';

  @override
  Future<List<AdminStudent>> build() {
    return ref
        .read(adminStudentRepositoryProvider)
        .listStudents(searchQuery: _searchQuery);
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(adminStudentRepositoryProvider)
          .listStudents(searchQuery: query),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(adminStudentRepositoryProvider)
          .listStudents(searchQuery: _searchQuery),
    );
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
  return ref.read(adminStudentRepositoryProvider).getStudent(studentId);
});

final studentEnrollmentsProvider =
    FutureProvider.family<List<StudentEnrollment>, String>((
      ref,
      studentId,
    ) async {
      return ref
          .read(adminStudentRepositoryProvider)
          .getEnrollments(studentId);
    });
