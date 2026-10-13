import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:acendra/features/marketplace/domain/entities/price_format_mixin.dart';
import 'package:flutter/foundation.dart';

@immutable
class CourseDetail with PriceFormatMixin {
  const CourseDetail({
    required this.id,
    required this.slug,
    required this.title,
    required this.shortDescription,
    this.description,
    required this.priceMinor,
    required this.currencyCode,
    required this.publishedAt,
    this.categoryId,
    required this.sections,
  });

  final String id;
  final String slug;
  final String title;
  final String shortDescription;
  final String? description;
  @override
  final int priceMinor;
  @override
  final String currencyCode;
  final String publishedAt;
  final String? categoryId;
  final List<CurriculumSection> sections;

  int get totalLessons =>
      sections.fold(0, (sum, s) => sum + s.lessons.length);
}
