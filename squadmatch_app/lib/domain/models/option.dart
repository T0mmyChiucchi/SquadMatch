class Option {
  final String id;
  final String title;
  final String imageUrl;
  final String description;

  Option({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.description = "",
  });

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      id: json['id'],
      title: json['title'],
      imageUrl: json['imageUrl'],
      description: json['description'] ?? "",
    );
  }
}
