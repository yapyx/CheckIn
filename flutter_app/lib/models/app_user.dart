import 'role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.role,
    this.displayName = '',
    this.pairingCode = '',
  });

  factory AppUser.fromApi(Map<String, dynamic> json) {
    final roleValue = json['role'] as String? ?? '';
    return AppUser(
      id: json['id'] as String? ?? '',
      role: roleValue == 'senior' ? Role.senior : Role.caregiver,
      displayName: json['display_name'] as String? ?? '',
      pairingCode: json['pairing_code'] as String? ?? '',
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final roleValue = json['role'] as String? ?? '';
    return AppUser(
      id: json['id'] as String? ?? '',
      role: roleValue == 'senior' ? Role.senior : Role.caregiver,
      displayName: json['display_name'] as String? ?? '',
      pairingCode: json['pairing_code'] as String? ?? '',
    );
  }

  final String id;
  final Role role;
  final String displayName;
  final String pairingCode;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role == Role.senior ? 'senior' : 'caregiver',
      'display_name': displayName,
      'pairing_code': pairingCode,
    };
  }
}
