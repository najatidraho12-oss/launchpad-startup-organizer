class AppUser {
  final int? id;
  final String email;
  final String fullName;

  AppUser({this.id, required this.email, required this.fullName});

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    id: map['id'] as int?,
    email: map['email'] as String,
    fullName: map['fullName'] as String,
  );
}
