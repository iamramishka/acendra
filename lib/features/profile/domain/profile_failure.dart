sealed class ProfileFailure {
  const ProfileFailure(this.message);
  final String message;
}

final class ProfileUpdateFailed extends ProfileFailure {
  const ProfileUpdateFailed(super.message);
}

final class ProfileNetworkError extends ProfileFailure {
  const ProfileNetworkError() : super('Network error. Please try again.');
}
