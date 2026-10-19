import 'package:flutter/material.dart';

/// Brand illustration, not a claim that the course has uploaded photography.
class CourseArt extends StatelessWidget {
  const CourseArt({super.key, this.height = 160});
  final double height;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.tertiary],
        ),
      ),
      child: Icon(
        Icons.school_outlined,
        color: cs.onPrimary,
        size: height * .4,
      ),
    );
  }
}
