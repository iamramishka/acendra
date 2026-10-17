import 'package:acendra/core/widgets/navigation/admin_shell.dart';
import 'package:acendra/core/widgets/navigation/auth_shell.dart';
import 'package:acendra/core/widgets/navigation/learning_shell.dart';
import 'package:acendra/core/widgets/navigation/public_shell.dart';
import 'package:acendra/core/widgets/navigation/student_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget shell) => ProviderScope(
  child: MaterialApp(theme: ThemeData(useMaterial3: true), home: shell),
);

void main() {
  group('PublicShell responsive', () {
    testWidgets('mobile 390: shows hamburger, hides nav links', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const PublicShell(child: SizedBox())));

      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.text('Courses'), findsNothing);
    });

    testWidgets('desktop 1440: shows nav links, hides hamburger', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const PublicShell(child: SizedBox())));

      expect(find.text('Courses'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsNothing);
    });
  });

  group('StudentShell responsive', () {
    testWidgets('mobile 390: shows NavigationBar', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const StudentShell(child: SizedBox())));

      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('desktop 1440: hides NavigationBar, shows AppBar links', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const StudentShell(child: SizedBox())));

      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('My Learning'), findsOneWidget);
    });
  });

  group('AdminShell responsive', () {
    testWidgets('mobile 390: has AppBar', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const AdminShell(child: SizedBox())));

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('desktop 1440: no AppBar, shows sidebar items', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const AdminShell(child: SizedBox())));

      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Students'), findsOneWidget);
    });
  });

  group('AuthShell responsive (same at all widths)', () {
    testWidgets('mobile 390: shows Acedra text', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const AuthShell(child: SizedBox())));

      expect(find.text('Acedra'), findsOneWidget);
    });

    testWidgets('desktop 1440: shows Acedra text', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const AuthShell(child: SizedBox())));

      expect(find.text('Acedra'), findsOneWidget);
    });
  });

  group('LearningShell responsive (same at all widths)', () {
    testWidgets('mobile 390: has AppBar', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const LearningShell(child: SizedBox())));

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('desktop 1440: has AppBar', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const LearningShell(child: SizedBox())));

      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
