import 'package:acendra/features/video_player/domain/entities/video_progress.dart';
import 'package:acendra/features/video_player/presentation/providers/video_player_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VideoPlayerNotifier', () {
    test('initial state is idle with zero position and duration', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(videoPlayerProvider);

      expect(state.status, VideoPlayerStatus.idle);
      expect(state.position, Duration.zero);
      expect(state.duration, Duration.zero);
      expect(state.buffered, 0.0);
      expect(state.errorMessage, isNull);
    });

    test('progress returns 0 when duration is zero', () {
      const progress = VideoProgress();
      expect(progress.progress, 0.0);
    });

    test('progress returns correct ratio when position and duration are set', () {
      const progress = VideoProgress(
        position: Duration(seconds: 30),
        duration: Duration(seconds: 60),
      );
      expect(progress.progress, closeTo(0.5, 0.001));
    });

    test('progress clamps to 1.0 if position exceeds duration', () {
      const progress = VideoProgress(
        position: Duration(seconds: 70),
        duration: Duration(seconds: 60),
      );
      expect(progress.progress, 1.0);
    });

    test('initialize sets loading status then transitions to error on bad URL', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Kick off initialization with an invalid URL; the controller will error.
      await container
          .read(videoPlayerProvider.notifier)
          .initialize('not-a-valid-url');

      final state = container.read(videoPlayerProvider);
      expect(state.status, VideoPlayerStatus.error);
      expect(state.errorMessage, isNotNull);
    });
  });
}
