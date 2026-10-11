import 'package:acendra/core/widgets/cards/course_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: ThemeData(useMaterial3: true),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('CourseCard renders title and instructor', (tester) async {
    await tester.pumpWidget(
      _wrap(
        CourseCard(
          title: 'Flutter Basics',
          instructorName: 'Jane Doe',
          price: r'$49',
          onTap: () {},
        ),
      ),
    );
    expect(find.text('Flutter Basics'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
  });

  testWidgets('CourseCard fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        CourseCard(
          title: 'X',
          instructorName: 'Y',
          price: r'$0',
          onTap: () => tapped = true,
        ),
      ),
    );
    await tester.tap(find.byType(InkWell));
    expect(tapped, isTrue);
  });

  testWidgets('CourseCard renders price', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const CourseCard(
          title: 'X',
          instructorName: 'Y',
          price: r'$99',
          onTap: null,
        ),
      ),
    );
    expect(find.text(r'$99'), findsOneWidget);
  });
}
