import 'package:acendra/features/marketplace/domain/entities/category.dart';

class CategoryDto {
  static Category fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    slug: json['slug'] as String,
  );
}
