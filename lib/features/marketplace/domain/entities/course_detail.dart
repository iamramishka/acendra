import 'package:acendra/features/marketplace/domain/entities/curriculum_section.dart';
import 'package:flutter/foundation.dart';

@immutable
class CourseDetail {
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
  final int priceMinor;
  final String currencyCode;
  final String publishedAt;
  final String? categoryId;
  final List<CurriculumSection> sections;

  int get totalLessons => sections.fold(0, (sum, s) => sum + s.lessons.length);

  String get formattedPrice {
    final major = priceMinor ~/ 100;
    final cents = priceMinor % 100;
    final majorStr = major.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$currencyCode $majorStr.${cents.toString().padLeft(2, '0')}';
  }
}
