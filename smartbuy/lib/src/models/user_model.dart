// This is the user_model.dart file.
class AppUser {
  final String uid;
  final String? email;
  final String? name;
  final String? photoUrl;

  AppUser({required this.uid, this.email, this.name, this.photoUrl});

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'name': name,
    'photoUrl': photoUrl,
  };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    uid: map['uid'] as String,
    email: map['email'] as String?,
    name: map['name'] as String?,
    photoUrl: map['photoUrl'] as String?,
  );
}
