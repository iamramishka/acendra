import 'package:acendra/features/marketplace/domain/entities/category.dart';
import 'package:flutter/material.dart';

class CategoryFilter extends StatelessWidget {
  const CategoryFilter({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> categories;
  final String? selectedId;
  final void Function(String? categoryId) onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All Courses'),
            selected: selectedId == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          ...categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(cat.name),
                selected: selectedId == cat.id,
                onSelected: (_) =>
                    onSelected(selectedId == cat.id ? null : cat.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
