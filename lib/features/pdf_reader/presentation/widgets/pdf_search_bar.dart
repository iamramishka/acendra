import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Compact page-number navigation bar for the PDF reader.
///
/// Accepts a page number string and navigates when submitted.
/// Real in-PDF text search is not supported by pdfx on Flutter Web.
class PdfSearchBar extends StatefulWidget {
  const PdfSearchBar({
    super.key,
    required this.totalPages,
    required this.onGoToPage,
  });

  final int totalPages;
  final ValueChanged<int> onGoToPage;

  @override
  State<PdfSearchBar> createState() => _PdfSearchBarState();
}

class _PdfSearchBarState extends State<PdfSearchBar> {
  final TextEditingController _controller = TextEditingController();

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value != null && value >= 1 && value <= widget.totalPages) {
      widget.onGoToPage(value);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                labelText: 'Go to page',
                border: const OutlineInputBorder(),
                hintText: '1–${widget.totalPages}',
              ),
            ),
          ),
          const SizedBox(width: 4),
          Semantics(
            label: 'Go to page',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Go to page',
              onPressed: _submit,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
        ],
      ),
    );
  }
}
