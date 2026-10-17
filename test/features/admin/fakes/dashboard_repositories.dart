import 'package:acendra/features/admin/data/repositories/admin_course_repository.dart';
import 'package:acendra/features/admin/data/repositories/admin_directory_client.dart';
import 'package:acendra/features/admin/data/repositories/admin_student_repository.dart';
import 'package:acendra/features/admin/domain/entities/admin_course.dart';
import 'package:acendra/features/admin/domain/entities/admin_student.dart';

class EmptyCourseRepository implements AdminCourseRepository {
  @override
  Future<List<AdminCourse>> listCourses() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class EmptyStudentRepository implements AdminStudentRepository {
  @override
  Future<List<AdminStudent>> listStudents({String? searchQuery}) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RestrictedStudentRepository extends EmptyStudentRepository {
  @override
  Future<List<AdminStudent>> listStudents({String? searchQuery}) async =>
      throw const AdminDataException('Current permission and MFA required.');
}
