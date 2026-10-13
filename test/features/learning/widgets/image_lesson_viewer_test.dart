import 'package:acendra/features/learning/presentation/widgets/image_lesson_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sampleTitle = 'Flutter Architecture Overview';
  const sampleImageUrl = 'https://example.com/flutter-arch.png';
  const sampleCaption = 'Figure 1: Flutter layered architecture';

  Widget buildWidget({
    String? caption,
    VoidCallback? onNext,
    VoidCallback? onPrevious,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ImageLessonViewer(
          title: sampleTitle,
          imageUrl: sampleImageUrl,
          caption: caption,
          onNext: onNext,
          onPrevious: onPrevious,
        ),
      ),
    );
  }

  testWidgets('renders lesson title', (tester) async {
    await tester.pumpWidget(buildWidget());

    expect(find.text(sampleTitle), findsOneWidget);
  });

  testWidgets('renders Image.network widget', (tester) async {
    await tester.pumpWidget(buildWidget());

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('shows caption when provided', (tester) async {
    await tester.pumpWidget(buildWidget(caption: sampleCaption));

    expect(find.text(sampleCaption), findsOneWidget);
  });

  testWidgets('hides caption when not provided', (tester) async {
    await tester.pumpWidget(buildWidget());

    expect(find.text(sampleCaption), findsNothing);
  });

  testWidgets('shows Next button when onNext is provided', (tester) async {
    await tester.pumpWidget(buildWidget(onNext: () {}));

    expect(find.text('Next →'), findsOneWidget);
  });

  testWidgets('shows Previous button when onPrevious is provided',
      (tester) async {
    await tester.pumpWidget(buildWidget(onPrevious: () {}));

    expect(find.text('← Previous'), findsOneWidget);
  });
}
