import 'package:acendra/features/dashboard/domain/entities/student_home.dart';

abstract interface class StudentHomeRepository {
  Future<StudentHome> load();
}
