sealed class AppFailure {
  const AppFailure(this.message);
  final String message;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message);
}

final class AuthFailure extends AppFailure {
  const AuthFailure(super.message);
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message);
}

final class PermissionFailure extends AppFailure {
  const PermissionFailure(super.message);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

final class ServerFailure extends AppFailure {
  const ServerFailure(super.message);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message);
}
