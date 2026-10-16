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

class StubAdminStudentRepository implements AdminStudentRepository {
  final List<AdminStudent> _students = [
    AdminStudent(
      id: 'stu-001',
      email: 'alice@example.com',
      displayName: 'Alice Fernando',
      enrolledCourseCount: 3,
      totalAmountPaid: 15000,
      createdAt: DateTime(2025, 3, 10),
      isActive: true,
    ),
    AdminStudent(
      id: 'stu-002',
      email: 'bob@example.com',
      displayName: 'Bob Perera',
      enrolledCourseCount: 1,
      totalAmountPaid: 5000,
      createdAt: DateTime(2025, 5, 22),
      isActive: true,
    ),
    AdminStudent(
      id: 'stu-003',
      email: 'carol@example.com',
      displayName: 'Carol Silva',
      enrolledCourseCount: 2,
      totalAmountPaid: 10000,
      createdAt: DateTime(2025, 7, 1),
      isActive: false,
    ),
    AdminStudent(
      id: 'stu-004',
      email: 'david@example.com',
      enrolledCourseCount: 0,
      totalAmountPaid: 0,
      createdAt: DateTime(2025, 9, 15),
      isActive: true,
    ),
  ];

  final Map<String, List<StudentEnrollment>> _enrollments = {
    'stu-001': [
      StudentEnrollment(
        id: 'enr-001',
        studentId: 'stu-001',
        courseId: 'crs-001',
        courseTitle: 'Flutter for Beginners',
        enrolledAt: DateTime(2025, 3, 15),
        status: EnrollmentStatus.active,
        paymentMethod: 'stripe',
        amountPaid: 5000,
        progressPercent: 72,
        lastAccessedAt: DateTime(2025, 10, 10),
      ),
      StudentEnrollment(
        id: 'enr-002',
        studentId: 'stu-001',
        courseId: 'crs-002',
        courseTitle: 'Advanced Dart Programming',
        enrolledAt: DateTime(2025, 4, 20),
        status: EnrollmentStatus.active,
        paymentMethod: 'bank_transfer',
        amountPaid: 5000,
        progressPercent: 45,
        lastAccessedAt: DateTime(2025, 10, 8),
      ),
      StudentEnrollment(
        id: 'enr-003',
        studentId: 'stu-001',
        courseId: 'crs-003',
        courseTitle: 'Supabase Masterclass',
        enrolledAt: DateTime(2025, 6, 1),
        status: EnrollmentStatus.revoked,
        paymentMethod: 'admin_grant',
        amountPaid: 0,
        progressPercent: 10,
      ),
    ],
    'stu-002': [
      StudentEnrollment(
        id: 'enr-004',
        studentId: 'stu-002',
        courseId: 'crs-001',
        courseTitle: 'Flutter for Beginners',
        enrolledAt: DateTime(2025, 5, 25),
        status: EnrollmentStatus.active,
        paymentMethod: 'stripe',
        amountPaid: 5000,
        progressPercent: 30,
        lastAccessedAt: DateTime(2025, 10, 12),
      ),
    ],
    'stu-003': [
      StudentEnrollment(
        id: 'enr-005',
        studentId: 'stu-003',
        courseId: 'crs-002',
        courseTitle: 'Advanced Dart Programming',
        enrolledAt: DateTime(2025, 7, 5),
        status: EnrollmentStatus.expired,
        paymentMethod: 'bank_transfer',
        amountPaid: 5000,
        progressPercent: 100,
      ),
      StudentEnrollment(
        id: 'enr-006',
        studentId: 'stu-003',
        courseId: 'crs-004',
        courseTitle: 'UI/UX Design Principles',
        enrolledAt: DateTime(2025, 8, 10),
        status: EnrollmentStatus.active,
        paymentMethod: 'stripe',
        amountPaid: 5000,
        progressPercent: 55,
        lastAccessedAt: DateTime(2025, 10, 5),
      ),
    ],
  };

  @override
  Future<List<AdminStudent>> listStudents({String? searchQuery}) async {
    // TODO: Replace with Supabase query on profiles table with enrollment count join
    await Future.delayed(const Duration(milliseconds: 300));
    if (searchQuery == null || searchQuery.isEmpty) return List.of(_students);
    final q = searchQuery.toLowerCase();
    return _students
        .where(
          (s) =>
              s.email.toLowerCase().contains(q) ||
              (s.displayName?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  @override
  Future<AdminStudent> getStudent(String studentId) async {
    // TODO: Replace with Supabase query on profiles table
    await Future.delayed(const Duration(milliseconds: 200));
    return _students.firstWhere((s) => s.id == studentId);
  }

  @override
  Future<List<StudentEnrollment>> getEnrollments(String studentId) async {
    // TODO: Replace with Supabase query on enrollments table with course join
    await Future.delayed(const Duration(milliseconds: 300));
    return _enrollments[studentId] ?? [];
  }

  @override
  Future<void> revokeEnrollment(String enrollmentId) async {
    // TODO: Call Supabase Edge Function or RPC to revoke enrollment
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<void> grantEnrollment(String studentId, String courseId) async {
    // TODO: Call Supabase Edge Function or RPC to grant enrollment
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<void> deactivateStudent(String studentId) async {
    // TODO: Call Supabase Edge Function or RPC to deactivate student account
    await Future.delayed(const Duration(milliseconds: 400));
  }
}

final adminStudentRepositoryProvider = Provider<AdminStudentRepository>((ref) {
  return StubAdminStudentRepository();
});
