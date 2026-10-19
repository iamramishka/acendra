import 'package:acendra/features/authentication/domain/auth_input_rules.dart';

sealed class AuthFailure {
  const AuthFailure(this.message);
  final String message;
}

class InvalidCredentials extends AuthFailure {
  const InvalidCredentials() : super('Invalid email or password.');
}

class EmailAlreadyInUse extends AuthFailure {
  const EmailAlreadyInUse()
    : super('An account with this email already exists.');
}

class EmailNotConfirmed extends AuthFailure {
  const EmailNotConfirmed()
    : super('Please verify your email before signing in.');
}

class WeakPassword extends AuthFailure {
  const WeakPassword()
    : super('Password must be at least $minPasswordLength characters.');
}

class NetworkError extends AuthFailure {
  const NetworkError() : super('Check your internet connection and try again.');
}

class UnexpectedAuthError extends AuthFailure {
  const UnexpectedAuthError(super.message);
}
