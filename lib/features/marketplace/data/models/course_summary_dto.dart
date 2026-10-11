import 'package:acendra/features/marketplace/domain/entities/course_summary.dart';

class CourseSummaryDto {
  static CourseSummary fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id == null) throw ArgumentError('Missing required field: id');
    return CourseSummary(
      id: id as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      shortDescription: (json['short_description'] as String?) ?? '',
      priceMinor: json['price_minor'] as int,
      currencyCode: json['currency_code'] as String,
      publishedAt: json['published_at'] as String,
    );
  }
}
