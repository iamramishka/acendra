class AdminCourse {
  const AdminCourse({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.isPublished,
    required this.enrollmentCount,
    required this.sectionCount,
    required this.lessonCount,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailUrl,
    this.currency = 'LKR',
  });

  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final double price;
  final String currency;
  final bool isPublished;
  final int enrollmentCount;
  final int sectionCount;
  final int lessonCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdminCourse copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    double? price,
    String? currency,
    bool? isPublished,
    int? enrollmentCount,
    int? sectionCount,
    int? lessonCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminCourse(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      isPublished: isPublished ?? this.isPublished,
      enrollmentCount: enrollmentCount ?? this.enrollmentCount,
      sectionCount: sectionCount ?? this.sectionCount,
      lessonCount: lessonCount ?? this.lessonCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminCourse && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
