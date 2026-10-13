import 'package:acendra/features/learning/presentation/widgets/text_lesson_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sampleTitle = 'Introduction to Flutter';
  const sampleContent =
      'Flutter is an open-source UI software development kit created by Google. '
      'It is used to develop cross-platform applications from a single codebase.';

  Widget buildWidget({VoidCallback? onNext, VoidCallback? onPrevious}) {
    return MaterialApp(
      home: Scaffold(
        body: TextLessonViewer(
          title: sampleTitle,
          content: sampleContent,
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

  testWidgets('renders lesson content', (tester) async {
    await tester.pumpWidget(buildWidget());

    expect(find.text(sampleContent), findsOneWidget);
  });

  testWidgets('shows Next button when onNext is provided', (tester) async {
    await tester.pumpWidget(buildWidget(onNext: () {}));

    expect(find.text('Next →'), findsOneWidget);
  });

  testWidgets('hides Next button when onNext is null', (tester) async {
    await tester.pumpWidget(buildWidget());

    expect(find.text('Next →'), findsNothing);
  });

  testWidgets('shows Previous button when onPrevious is provided', (
    tester,
  ) async {
    await tester.pumpWidget(buildWidget(onPrevious: () {}));

    expect(find.text('← Previous'), findsOneWidget);
  });

  testWidgets('hides Previous button when onPrevious is null', (tester) async {
    await tester.pumpWidget(buildWidget());

    expect(find.text('← Previous'), findsNothing);
  });
}
