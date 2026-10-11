import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:flutter/material.dart';

extension ScreenLayoutExtension on BuildContext {
  ScreenLayout get layout {
    final w = MediaQuery.sizeOf(this).width;
    if (w < AppBreakpoints.compact) return ScreenLayout.compact;
    if (w < AppBreakpoints.medium) return ScreenLayout.medium;
    return ScreenLayout.expanded;
  }

  double get pageMargin => switch (layout) {
    ScreenLayout.compact => AppBreakpoints.marginCompact,
    ScreenLayout.medium => AppBreakpoints.marginMedium,
    ScreenLayout.expanded => AppBreakpoints.marginExpanded,
  };
}

class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({super.key, required this.child, this.maxWidth});
  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final margin = context.pageMargin;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? AppBreakpoints.maxContentWidth,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: margin),
          child: child,
        ),
      ),
    );
  }
}
