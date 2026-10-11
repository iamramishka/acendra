import 'package:flutter/material.dart';

class AppSkeleton extends StatefulWidget {
  const AppSkeleton({super.key, this.width, this.height, this.borderRadius});
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface.withAlpha(30);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base.withAlpha((_anim.value * 255).round()),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(6),
        ),
      ),
    );
  }
}
