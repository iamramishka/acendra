import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/cards/course_card.dart';
import 'package:acendra/core/widgets/feedback/app_state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap({required Widget child, ThemeData? theme}) {
  return MediaQuery(
    data: const MediaQueryData(),
    child: MaterialApp(
      theme: theme ?? ThemeData(useMaterial3: true),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('CourseCard accessibility', () {
    testWidgets('meets androidTapTargetGuideline', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: CourseCard(
            title: 'Flutter for Beginners',
            instructorName: 'Jane Doe',
            price: '\$49.99',
            onTap: () {},
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('meets labeledTapTargetGuideline', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: CourseCard(
            title: 'Flutter for Beginners',
            instructorName: 'Jane Doe',
            price: '\$49.99',
            onTap: () {},
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('meets textContrastGuideline', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: CourseCard(
            title: 'Flutter for Beginners',
            instructorName: 'Jane Doe',
            price: '\$49.99',
            onTap: () {},
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });

  group('AppButton accessibility', () {
    testWidgets('meets androidTapTargetGuideline', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: AppButton(
            label: 'Continue',
            onPressed: () {},
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('meets labeledTapTargetGuideline', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: AppButton(
            label: 'Continue',
            onPressed: () {},
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });
  });

  group('AppEmptyState accessibility', () {
    testWidgets('meets androidTapTargetGuideline', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: const AppEmptyState(message: 'No courses found'),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });
}
