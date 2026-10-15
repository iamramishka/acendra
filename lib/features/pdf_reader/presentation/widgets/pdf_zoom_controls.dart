import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/features/pdf_reader/presentation/providers/pdf_reader_provider.dart';
import 'package:flutter/material.dart';

class PdfZoomControls extends StatelessWidget {
  const PdfZoomControls({
    super.key,
    required this.currentZoom,
    required this.currentPreset,
    this.onZoomIn,
    this.onZoomOut,
    this.onPresetSelected,
  });

  final double currentZoom;
  final PdfZoomPreset currentPreset;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final void Function(PdfZoomPreset preset)? onPresetSelected;

  static const double _minZoom = 0.25;
  static const double _maxZoom = 4.0;

  String get _zoomLabel => '${(currentZoom * 100).round()}%';

  String _presetLabel(PdfZoomPreset p) => switch (p) {
    PdfZoomPreset.fitPage => 'Fit Page',
    PdfZoomPreset.fitWidth => 'Fit Width',
    PdfZoomPreset.zoom100 => '100%',
    PdfZoomPreset.zoom150 => '150%',
    PdfZoomPreset.zoom200 => '200%',
  };

  @override
  Widget build(BuildContext context) {
    final canZoomOut = currentZoom > _minZoom;
    final canZoomIn = currentZoom < _maxZoom;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Zoom out',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.remove),
            onPressed: canZoomOut ? onZoomOut : null,
            tooltip: 'Zoom out',
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Semantics(
          label: '${(currentZoom * 100).round()} percent zoom',
          child: SizedBox(
            width: 56,
            child: Text(
              _zoomLabel,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Semantics(
          label: 'Zoom in',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.add),
            onPressed: canZoomIn ? onZoomIn : null,
            tooltip: 'Zoom in',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (onPresetSelected != null)
          Semantics(
            label: 'Zoom preset selector',
            explicitChildNodes: false,
            child: DropdownButton<PdfZoomPreset>(
              value: currentPreset,
              underline: const SizedBox.shrink(),
              isDense: true,
              items: PdfZoomPreset.values
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        _presetLabel(p),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (p) {
                if (p != null) onPresetSelected!(p);
              },
            ),
          ),
      ],
    );
  }
}
