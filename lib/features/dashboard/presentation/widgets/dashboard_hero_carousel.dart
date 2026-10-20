import 'dart:async';
import 'dart:math' as math;

import 'package:acendra/app/theme/app_breakpoints.dart';
import 'package:acendra/app/theme/app_colors.dart';
import 'package:acendra/app/theme/app_spacing.dart';
import 'package:acendra/features/dashboard/domain/entities/hero_slide.dart';
import 'package:acendra/features/dashboard/presentation/dashboard_copy.dart';
import 'package:flutter/material.dart';

class DashboardHeroCarousel extends StatefulWidget {
  const DashboardHeroCarousel({super.key, required this.slides, this.onAction});

  final List<HeroSlide> slides;
  final ValueChanged<HeroSlide>? onAction;

  @override
  State<DashboardHeroCarousel> createState() => _DashboardHeroCarouselState();
}

class _DashboardHeroCarouselState extends State<DashboardHeroCarousel>
    with WidgetsBindingObserver {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;
  bool _paused = false;
  bool _hovered = false;
  bool _focused = false;
  bool _foreground = true;

  bool get _reduceMotion =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  @override
  void didUpdateWidget(DashboardHeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.slides.length) {
      _index = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(0);
      });
    }
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (widget.slides.length < 2 ||
        _paused ||
        _hovered ||
        _focused ||
        !_foreground ||
        _reduceMotion ||
        !TickerMode.valuesOf(context).enabled) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_controller.hasClients &&
          !_controller.position.isScrollingNotifier.value) {
        _goTo((_index + 1) % widget.slides.length);
      }
    });
  }

  void _goTo(int index) {
    if (!_controller.hasClients) return;
    if (_reduceMotion) {
      _controller.jumpToPage(index);
    } else {
      _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) return const Text(DashboardCopy.noSlides);
    final theme = Theme.of(context);
    final foreground = AppColors.light.onPrimary;
    final labelStyle = theme.textTheme.labelLarge!.copyWith(color: foreground);
    final titleStyle = theme.textTheme.headlineMedium!.copyWith(
      color: foreground,
      fontWeight: FontWeight.bold,
    );
    final bodyStyle = theme.textTheme.bodyLarge!.copyWith(color: foreground);
    return Focus(
      onFocusChange: (focused) {
        _focused = focused;
        _schedule();
      },
      child: MouseRegion(
        onEnter: (_) {
          _hovered = true;
          _schedule();
        },
        onExit: (_) {
          _hovered = false;
          _schedule();
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            gradient: const RadialGradient(
              center: Alignment(0.7, -0.2),
              radius: 1.5,
              colors: [
                Color(0xFF1E6BFF),
                Color(0xFF123A9C),
                Color(0xFF0B1E4F),
              ],
              stops: [0.0, 0.35, 0.75],
            ),
          ),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= AppBreakpoints.compact;
                  final contentWidth = constraints.maxWidth - AppSpacing.xl;
                  final textWidth = wide
                      ? (contentWidth - AppSpacing.lg) * .65
                      : contentWidth;
                  double textHeight(
                    String text,
                    TextStyle style, {
                    double? width,
                  }) {
                    final painter = TextPainter(
                      text: TextSpan(text: text, style: style),
                      textDirection: Directionality.of(context),
                      textScaler: MediaQuery.textScalerOf(context),
                    )..layout(maxWidth: width ?? textWidth);
                    final height = painter.height;
                    painter.dispose();
                    return height;
                  }

                  // Measure every slide so paging and enlarged text never clip.
                  final height = widget.slides.fold<double>(0, (height, slide) {
                    final buttonHeight = math.max(
                      48.0,
                      textHeight(
                            slide.ctaLabel,
                            labelStyle,
                            width: textWidth - AppSpacing.xl,
                          ) +
                          AppSpacing.xl,
                    );
                    return math.max(
                      height,
                      AppSpacing.xl +
                          textHeight(slide.label, labelStyle) +
                          textHeight(slide.headline, titleStyle) +
                          textHeight(slide.subtext, bodyStyle) +
                          buttonHeight +
                          AppSpacing.md * 3,
                    );
                  });
                  return SizedBox(
                    height: height,
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: widget.slides.length,
                      onPageChanged: (index) => setState(() => _index = index),
                      itemBuilder: (context, index) {
                        final slide = widget.slides[index];
                        return Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              SizedBox(
                                width: textWidth,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(slide.label, style: labelStyle),
                                    const SizedBox(height: AppSpacing.md),
                                    Semantics(
                                      header: true,
                                      child: Text(
                                        slide.headline,
                                        style: titleStyle,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(slide.subtext, style: bodyStyle),
                                    const SizedBox(height: AppSpacing.md),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: foreground,
                                        foregroundColor: AppColors.deepNavy,
                                        minimumSize: const Size(48, 48),
                                        padding: const EdgeInsets.all(
                                          AppSpacing.md,
                                        ),
                                        textStyle: labelStyle,
                                      ),
                                      onPressed: widget.onAction == null
                                          ? null
                                          : () => widget.onAction!(slide),
                                      child: Text(slide.ctaLabel),
                                    ),
                                  ],
                                ),
                              ),
                              if (wide) ...[
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(
                                  child: ExcludeSemantics(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.school_outlined,
                                          size: AppSpacing.xxxl,
                                          color: foreground,
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        Wrap(
                                          spacing: AppSpacing.sm,
                                          children: [
                                            for (final icon in const [
                                              Icons.code,
                                              Icons.bar_chart,
                                              Icons.play_circle_outline,
                                              Icons.description_outlined,
                                            ])
                                              Icon(icon, color: foreground),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              if (widget.slides.length > 1)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: IconButtonTheme(
                    data: IconButtonThemeData(
                      style: IconButton.styleFrom(
                        foregroundColor: foreground,
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        IconButton(
                          tooltip: DashboardCopy.previousSlide,
                          onPressed: () => _goTo(
                            (_index - 1 + widget.slides.length) %
                                widget.slides.length,
                          ),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        for (var i = 0; i < widget.slides.length; i++)
                          Semantics(
                            selected: _index == i,
                            child: IconButton(
                              tooltip: DashboardCopy.slide(
                                i + 1,
                                widget.slides.length,
                              ),
                              onPressed: () => _goTo(i),
                              icon: Icon(
                                _index == i
                                    ? Icons.circle
                                    : Icons.circle_outlined,
                                size: 12,
                              ),
                            ),
                          ),
                        IconButton(
                          tooltip: DashboardCopy.nextSlide,
                          onPressed: () =>
                              _goTo((_index + 1) % widget.slides.length),
                          icon: const Icon(Icons.chevron_right),
                        ),
                        if (!_reduceMotion)
                          IconButton(
                            tooltip: _paused
                                ? DashboardCopy.resumeSlides
                                : DashboardCopy.pauseSlides,
                            onPressed: () {
                              setState(() => _paused = !_paused);
                              _schedule();
                            },
                            icon: Icon(
                              _paused ? Icons.play_arrow : Icons.pause,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
