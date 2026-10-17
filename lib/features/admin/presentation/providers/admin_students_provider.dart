import 'package:acendra/features/admin/data/repositories/admin_student_repository.dart';
import 'package:acendra/features/admin/domain/entities/admin_student.dart';
import 'package:acendra/features/admin/domain/entities/student_enrollment.dart';
import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminStudentsNotifier extends AsyncNotifier<List<AdminStudent>> {
  String _searchQuery = '';
  String? _sessionUserId;

  @override
  Future<List<AdminStudent>> build() {
    final userId = ref.watch(currentSessionProvider)?.user.id;
    if (userId != _sessionUserId) _searchQuery = '';
    _sessionUserId = userId;
    return ref
        .watch(adminStudentRepositoryProvider)
        .listStudents(searchQuery: _searchQuery);
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    state = const AsyncLoading();
    // Rebuild through the same Future lifecycle as the initial load. Riverpod
    // discards obsolete loads, searches and failures after invalidation.
    ref.invalidateSelf();
    // Errors are already published by the provider; don't rethrow from onChanged.
    await AsyncValue.guard(() => future);
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
