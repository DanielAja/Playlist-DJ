class User {
  final String id;
  final String displayName;
  final String email;
  final String? imageUrl;
  final String country;
  final String? product; // 'premium', 'free', etc.

  User({
    required this.id,
    required this.displayName,
    required this.email,
    this.imageUrl,
    required this.country,
    this.product,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      displayName: json['display_name'],
      email: json['email'],
      imageUrl: json['images'] != null && (json['images'] as List).isNotEmpty
          ? (json['images'] as List).first['url']
          : null,
      country: json['country'],
      product: json['product'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'email': email,
      'image_url': imageUrl,
      'country': country,
      'product': product,
    };
  }

  bool get isPremium => product == 'premium';
}