class RememberMeCredentials {
  const RememberMeCredentials({
    this.enabled = false,
    this.email,
    this.password,
  });

  final bool enabled;
  final String? email;
  final String? password;
}

abstract class RememberMeStorage {
  Future<RememberMeCredentials> load();
  Future<void> save({
    required bool enabled,
    String? email,
    String? password,
  });
}
