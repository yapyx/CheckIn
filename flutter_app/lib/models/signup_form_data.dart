import 'role.dart';

class SignupFormData {
  const SignupFormData({
    required this.userId,
    required this.password,
    required this.displayName,
    required this.profileContext,
    required this.occupation,
  });

  final String userId;
  final String password;
  final String displayName;
  final String profileContext;
  final String occupation;
}

class LoginFormData {
  const LoginFormData({
    required this.role,
    required this.userId,
    required this.password,
  });

  final Role role;
  final String userId;
  final String password;
}
