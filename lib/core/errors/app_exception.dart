import 'app_failure.dart';

class AppException implements Exception {
  const AppException(this.failure);
  final AppFailure failure;

  @override
  String toString() =>
      'AppException(${failure.runtimeType}: ${failure.message})';
}
