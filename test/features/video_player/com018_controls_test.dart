import 'package:acendra/features/video_player/domain/entities/video_progress.dart';
import 'package:acendra/features/video_player/presentation/widgets/video_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _controls({ValueChanged<double>? onSpeed}) => MaterialApp(
  home: Scaffold(
    body: VideoControls(
      progress: const VideoProgress(
        status: VideoPlayerStatus.paused,
        duration: Duration(hours: 1, minutes: 2, seconds: 3),
        position: Duration(hours: 1, minutes: 1, seconds: 2),
      ),
      onPlayPause: () {},
      onSeek: (_) {},
      onFullscreen: () {},
      onSpeed: onSpeed,
    ),
  ),
);

void main() {
  testWidgets('long lessons show hours without wrapping to minute zero', (
    tester,
  ) async {
    await tester.pumpWidget(_controls());
    expect(find.text('1:01:02'), findsOneWidget);
    expect(find.text('1:02:03'), findsOneWidget);
  });

  testWidgets(
    'playback speed has an accessible target and offers the approved rates',
    (tester) async {
      double? speed;
      await tester.pumpWidget(_controls(onSpeed: (value) => speed = value));
      expect(
        tester.getSize(find.byTooltip('Playback speed')).height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.byTooltip('Playback speed'));
      await tester.pumpAndSettle();
      for (final label in ['1.0x', '1.25x', '1.5x', '2.0x']) {
        expect(find.text(label), findsWidgets);
      }
      await tester.tap(find.text('1.25x'));
      await tester.pumpAndSettle();
      expect(speed, 1.25);
    },
  );

  testWidgets('controls fit a narrow player with doubled text', (tester) async {
    tester.view.physicalSize = const Size(320, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: _controls(onSpeed: (_) {}),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
