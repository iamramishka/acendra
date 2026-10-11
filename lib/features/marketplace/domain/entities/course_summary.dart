import 'package:flutter/foundation.dart';

@immutable
class CourseSummary {
  const CourseSummary({
    required this.id,
    required this.slug,
    required this.title,
    required this.shortDescription,
    required this.priceMinor,
    required this.currencyCode,
    required this.publishedAt,
  });

  final String id;
  final String slug;
  final String title;
  final String shortDescription;
  final int priceMinor;
  final String currencyCode;
  final String publishedAt;

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
