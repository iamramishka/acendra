/// Semantic icon keys; the presentation layer chooses the Flutter icons.
enum DashboardCategoryIcon { development, design, business, languages, general }

/// Dashboard presentation metadata without changing the marketplace category.
class DashboardCategory {
  const DashboardCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
  });

  final String id;
  final String name;
  final String slug;
  final DashboardCategoryIcon icon;
}
