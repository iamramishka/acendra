import 'package:acendra/features/video_player/domain/entities/video_progress.dart';
import 'package:acendra/features/video_player/presentation/widgets/video_controls.dart';
import 'package:acendra/features/video_player/presentation/widgets/video_error_state.dart';
import 'package:acendra/features/video_player/presentation/widgets/video_loading_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VideoLoadingState', () {
    testWidgets('shows CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 400, height: 225, child: VideoLoadingState()),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows Buffering label by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 225,
              child: VideoLoadingState(label: 'Buffering…'),
            ),
          ),
        ),
      );

      expect(find.text('Buffering…'), findsOneWidget);
    });

    testWidgets('hides label when label is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 225,
              child: VideoLoadingState(label: ''),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Buffering…'), findsNothing);
    });
  });

  group('VideoErrorState', () {
    testWidgets('shows error icon and message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 225,
              child: VideoErrorState(errorMessage: 'Network error'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
    });

    testWidgets('shows Retry button when onRetry is provided', (tester) async {
      var retryCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 225,
              child: VideoErrorState(
                errorMessage: 'Timeout',
                onRetry: () => retryCalled = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retryCalled, isTrue);
    });

    testWidgets('hides Retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 225,
              child: VideoErrorState(errorMessage: 'Error'),
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('shows default message when errorMessage is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 400, height: 225, child: VideoErrorState()),
          ),
        ),
      );

      expect(
        find.text('An error occurred while loading the video.'),
        findsOneWidget,
      );
    });
  });

  group('VideoControls', () {
    const pausedProgress = VideoProgress(
      status: VideoPlayerStatus.paused,
      position: Duration(seconds: 10),
      duration: Duration(seconds: 120),
    );

    const playingProgress = VideoProgress(
      status: VideoPlayerStatus.playing,
      position: Duration(seconds: 30),
      duration: Duration(seconds: 120),
    );

    testWidgets('shows play icon when paused', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoControls(
              progress: pausedProgress,
              onPlayPause: () {},
              onSeek: (_) {},
              onFullscreen: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('shows pause icon when playing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoControls(
              progress: playingProgress,
              onPlayPause: () {},
              onSeek: (_) {},
              onFullscreen: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('shows formatted position and duration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoControls(
              progress: pausedProgress,
              onPlayPause: () {},
              onSeek: (_) {},
              onFullscreen: () {},
            ),
          ),
        ),
      );

      expect(find.text('00:10'), findsOneWidget);
      expect(find.text('02:00'), findsOneWidget);
    });

    testWidgets('calls onPlayPause when play button is tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoControls(
              progress: pausedProgress,
              onPlayPause: () => called = true,
              onSeek: (_) {},
              onFullscreen: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.play_arrow));
      expect(called, isTrue);
    });

    testWidgets('shows fullscreen icon when not fullscreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoControls(
              progress: pausedProgress,
              onPlayPause: () {},
              onSeek: (_) {},
              onFullscreen: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
    });

    testWidgets('shows fullscreen_exit icon when fullscreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoControls(
              progress: pausedProgress,
              onPlayPause: () {},
              onSeek: (_) {},
              onFullscreen: () {},
              isFullscreen: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);
    });
  });
}
