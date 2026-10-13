import 'package:flutter/foundation.dart';

@immutable
class Category {
  const Category({required this.id, required this.name, required this.slug});

  final String id;
  final String name;
  final String slug;
}
