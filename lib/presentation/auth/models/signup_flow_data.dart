enum AccountSetupType {
  evv,
  patientQuestionsOnly,
}

/// Shared signup/onboarding context passed through post-signup screens.
class SignupFlowData {
  const SignupFlowData({
    required this.email,
    this.setupType = AccountSetupType.evv,
  });

  final String email;
  final AccountSetupType setupType;

  SignupFlowData copyWith({
    String? email,
    AccountSetupType? setupType,
  }) {
    return SignupFlowData(
      email: email ?? this.email,
      setupType: setupType ?? this.setupType,
    );
  }
}
