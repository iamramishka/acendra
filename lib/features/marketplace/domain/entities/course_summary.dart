import 'package:acendra/features/marketplace/domain/entities/price_format_mixin.dart';
import 'package:flutter/foundation.dart';

@immutable
class CourseSummary with PriceFormatMixin {
  const CourseSummary({
    required this.id,
    required this.slug,
    required this.title,
    required this.shortDescription,
    required this.priceMinor,
    required this.currencyCode,
    required this.publishedAt,
    this.categoryId,
  });

  final String id;
  final String slug;
  final String title;
  final String shortDescription;
  @override
  final int priceMinor;
  @override
  final String currencyCode;
  final String publishedAt;
  final String? categoryId;

}
