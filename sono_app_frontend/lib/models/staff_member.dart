class StaffMember {
  const StaffMember({
    required this.id,
    required this.nomPrenom,
    required this.email,
    required this.role,
    this.photoUrl,
  });

  final String id;
  final String nomPrenom;
  final String email;
  final String role;
  final String? photoUrl;

  bool get isAdmin => role == 'Admin';

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'].toString(),
      nomPrenom: json['nom_prenom'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      photoUrl: json['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson({String password = 'sono1234'}) {
    return {
      'nom_prenom': nomPrenom,
      'email': email,
      'role': role,
      'password': password,
    };
  }
}
