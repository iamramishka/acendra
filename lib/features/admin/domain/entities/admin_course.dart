String formatAdminCourseMinorPrice(String minor) {
  final value = BigInt.parse(minor);
  final cents = (value % BigInt.from(100)).toString().padLeft(2, '0');
  return '${value ~/ BigInt.from(100)}${cents == '00' ? '' : '.$cents'}';
}

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
    this.slug = '',
    this.categoryId,
    this.shortDescription = '',
    this.priceMinor,
    this.rawUpdatedAt,
    this.categories = const {},
  });

  String get priceText {
    if (priceMinor != null) return formatAdminCourseMinorPrice(priceMinor!);
    final decimal = price.toStringAsFixed(2);
    return decimal.endsWith('.00')
        ? decimal.substring(0, decimal.length - 3)
        : decimal;
  }

  final String slug;
  final String? categoryId;
  final String shortDescription;
  final String? priceMinor;
  final String? rawUpdatedAt;
  final Map<String, String> categories;
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
    String? slug,
    String? categoryId,
    String? shortDescription,
    String? priceMinor,
    String? rawUpdatedAt,
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
      slug: slug ?? this.slug,
      categoryId: categoryId ?? this.categoryId,
      shortDescription: shortDescription ?? this.shortDescription,
      priceMinor: priceMinor ?? this.priceMinor,
      rawUpdatedAt: rawUpdatedAt ?? this.rawUpdatedAt,
      categories: categories,
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
      other is AdminCourse &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
