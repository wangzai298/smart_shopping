class User {
  final String id;
  final String phone;
  final String? nickname;
  final String? avatarUrl;

  User({required this.id, required this.phone, this.nickname, this.avatarUrl});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      phone: json['phone'] as String? ?? '',
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'nickname': nickname,
        'avatarUrl': avatarUrl,
      };
}
