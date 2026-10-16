import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/admin/data/repositories/admin_directory_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:acendra/features/admin/domain/entities/admin_student.dart';
import 'package:acendra/features/admin/domain/entities/student_enrollment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class AdminStudentRepository {
  Future<List<AdminStudent>> listStudents({String? searchQuery});
  Future<AdminStudent> getStudent(String studentId);
  Future<List<StudentEnrollment>> getEnrollments(String studentId);
  Future<void> revokeEnrollment(String enrollmentId);
  Future<void> grantEnrollment(String studentId, String courseId);
  Future<void> deactivateStudent(String studentId);
}

class SupabaseAdminStudentRepository implements AdminStudentRepository {
  SupabaseAdminStudentRepository(SupabaseClient client)
    : _directory = AdminDirectoryClient(client);
  final AdminDirectoryClient _directory;

  AdminStudent _student(Map<String, dynamic> row) => AdminStudent(
    id: row['id'] as String,
    email: row['email'] as String,
    displayName: row['display_name'] as String?,
    enrolledCourseCount: (row['enrolled_course_count'] as num).toInt(),
    totalAmountPaid: row['total_paid_minor'] == null
        ? null
        : num.parse(row['total_paid_minor'].toString()) / 100,
    currency: row['currency_code'] as String,
    createdAt: DateTime.parse(row['created_at'] as String),
    isActive: row['is_active'] as bool,
  );

  @override
  Future<List<AdminStudent>> listStudents({String? searchQuery}) async =>
      (await _directory.read(
        'students',
        search: searchQuery?.trim() ?? '',
      )).map(_student).toList();

  @override
  Future<AdminStudent> getStudent(String studentId) async {
    final rows = await _directory.read('students', id: studentId);
    if (rows.isEmpty) {
      throw const AdminDataException(
        'Student not found or no longer available to your account.',
      );
    }
    return _student(rows.single);
  }

  Never _unavailable() => throw const AdminDataException(
    'Enrollment and account management are not available in this release. Contact your administrator.',
  );
  @override
  Future<List<StudentEnrollment>> getEnrollments(String studentId) async =>
      _unavailable();
  @override
  Future<void> revokeEnrollment(String enrollmentId) async => _unavailable();
  @override
  Future<void> grantEnrollment(String studentId, String courseId) async =>
      _unavailable();
  @override
  Future<void> deactivateStudent(String studentId) async => _unavailable();
}

final adminStudentRepositoryProvider = Provider<AdminStudentRepository>((ref) {
  final session = ref.watch(currentSessionProvider);
  if (session == null) {
    throw const AdminDataException('Your session expired. Sign in again.');
  }
  return SupabaseAdminStudentRepository(Supabase.instance.client);
});
