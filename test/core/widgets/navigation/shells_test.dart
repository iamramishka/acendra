import 'package:acendra/core/widgets/navigation/admin_shell.dart';
import 'package:acendra/core/widgets/navigation/auth_shell.dart';
import 'package:acendra/core/widgets/navigation/learning_shell.dart';
import 'package:acendra/core/widgets/navigation/public_shell.dart';
import 'package:acendra/core/widgets/navigation/student_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: child,
      ),
    );

void main() {
  testWidgets('PublicShell renders child', (tester) async {
    await tester.pumpWidget(_wrap(
      const PublicShell(child: Text('public content')),
    ));
    expect(find.text('public content'), findsOneWidget);
  });

  testWidgets('AuthShell renders child', (tester) async {
    await tester.pumpWidget(_wrap(
      const AuthShell(child: Text('login form')),
    ));
    expect(find.text('login form'), findsOneWidget);
  });

  testWidgets('StudentShell renders child', (tester) async {
    await tester.pumpWidget(_wrap(
      const StudentShell(child: Text('dashboard')),
    ));
    expect(find.text('dashboard'), findsOneWidget);
  });

  testWidgets('LearningShell renders child', (tester) async {
    await tester.pumpWidget(_wrap(
      const LearningShell(child: Text('lesson')),
    ));
    expect(find.text('lesson'), findsOneWidget);
  });

  testWidgets('AdminShell renders child', (tester) async {
    await tester.pumpWidget(_wrap(
      const AdminShell(child: Text('admin panel')),
    ));
    expect(find.text('admin panel'), findsOneWidget);
  });
}
