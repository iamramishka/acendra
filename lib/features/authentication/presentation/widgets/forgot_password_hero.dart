import 'package:acendra/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Decorative password recovery illustration, matching the mobile prototype.
class ForgotPasswordHero extends StatelessWidget {
  const ForgotPasswordHero({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 1.28,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: dark
                    ? [AppColors.dark.primaryContainer, AppColors.dark.surface]
                    : [
                        AppColors.light.background,
                        AppColors.light.surfaceTertiary,
                      ],
                radius: 0.85,
              ),
            ),
            child: CustomPaint(
              painter: _RibbonPainter(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tile = constraints.maxHeight * 0.47;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: constraints.maxWidth * 0.18,
                        top: constraints.maxHeight * 0.26,
                        child: const _Dot(size: 20),
                      ),
                      Positioned(
                        right: constraints.maxWidth * 0.16,
                        top: constraints.maxHeight * 0.24,
                        child: const _Dot(size: 14),
                      ),
                      Container(
                        width: tile,
                        height: tile,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF4C8DFF), AppColors.royalBlue],
                          ),
                          borderRadius: BorderRadius.circular(tile * 0.25),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.royalBlue.withValues(
                                alpha: 0.22,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.lock_outline_rounded,
                          size: tile * 0.44,
                          color: Colors.white,
                        ),
                      ),
                      Positioned(
                        left: (constraints.maxWidth + tile) / 2 - tile * 0.25,
                        top: (constraints.maxHeight - tile) / 2 - tile * 0.09,
                        child: Container(
                          width: tile * 0.39,
                          height: tile * 0.39,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF38C9F9), AppColors.skyCyan],
                            ),
                          ),
                          child: Transform.rotate(
                            angle: -0.35,
                            child: Icon(
                              Icons.send_outlined,
                              size: tile * 0.2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF8CE6FF), AppColors.royalBlue],
      ),
    ),
  );
}

class _RibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.69)
      ..cubicTo(
        size.width * 0.32,
        size.height * 0.54,
        size.width * 0.72,
        size.height * 0.48,
        size.width,
        size.height * 0.51,
      )
      ..lineTo(size.width, size.height * 0.67)
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.83,
        size.width * 0.22,
        size.height * 0.88,
        0,
        size.height * 0.84,
      )
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.royalBlue, Color(0xFF59CAFA)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter oldDelegate) => false;
}
