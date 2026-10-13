import 'package:acendra/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class PdfPageNavigation extends StatelessWidget {
  const PdfPageNavigation({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.onPrevious,
    this.onNext,
    this.onJumpToPage,
  });

  final int currentPage;
  final int totalPages;

  /// Null when at the first page — disables the button.
  final VoidCallback? onPrevious;

  /// Null when at the last page — disables the button.
  final VoidCallback? onNext;

  final void Function(int page)? onJumpToPage;

  void _showJumpDialog(BuildContext context) {
    final controller = TextEditingController(text: '$currentPage');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Go to page'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Page (1–$totalPages)',
          ),
          onSubmitted: (_) => _commitJump(ctx, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _commitJump(ctx, controller.text),
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  void _commitJump(BuildContext ctx, String text) {
    final page = int.tryParse(text.trim());
    if (page != null && page >= 1 && page <= totalPages) {
      onJumpToPage?.call(page);
    }
    Navigator.of(ctx).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Previous page',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
            tooltip: 'Previous page',
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Semantics(
          label: 'Page $currentPage of $totalPages, tap to jump',
          button: true,
          child: GestureDetector(
            onTap: onJumpToPage != null
                ? () => _showJumpDialog(context)
                : null,
            child: Container(
              constraints: const BoxConstraints(minWidth: 64),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(6)),
              ),
              child: Text(
                '$currentPage / $totalPages',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Semantics(
          label: 'Next page',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
            tooltip: 'Next page',
          ),
        ),
      ],
    );
  }
}
