// CSA-194: Keyboard navigation and focus management tests.
// Verifies NFR-ACC-006 (keyboard operability) and NFR-ACC-007 (semantic labels
// for interactive widgets). Complements accessibility_test.dart, which covers
// tap-target sizing and text contrast.
//
// Assumptions:
// - LoginScreen and RegisterScreen are tested via isolated form layouts that
//   mirror each screen's field order but omit Riverpod / go_router dependencies,
//   which require full integration-test infrastructure to stub properly.
// - AppPasswordField exposes a visibility-toggle IconButton as a separate Tab
//   stop between the text field and the next field; tests account for this.
// - ElevatedButton internal focus is verified via
//   FocusManager.instance.primaryFocus?.context
//       ?.findAncestorWidgetOfExactType<ElevatedButton>()
//   because ElevatedButton does not expose its FocusNode publicly.

import 'package:acendra/core/widgets/buttons/app_button.dart';
import 'package:acendra/core/widgets/dialogs/app_dialog.dart';
import 'package:acendra/core/widgets/inputs/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap({required Widget child, ThemeData? theme}) {
  return MediaQuery(
    data: const MediaQueryData(),
    child: MaterialApp(
      theme: theme ?? ThemeData(useMaterial3: true),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  // ------------------------------------------------------------------ //
  // AppTextField – keyboard focus and input
  // ------------------------------------------------------------------ //
  group('AppTextField keyboard accessibility', () {
    testWidgets('receives focus via Tab from no initial focus', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        _wrap(
          child: AppTextField(label: 'Email', focusNode: focusNode),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(
        focusNode.hasFocus,
        isTrue,
        reason: 'AppTextField should become focused on first Tab',
      );
    });

    testWidgets('Tab transfers focus from one field to the next', (
      tester,
    ) async {
      final firstNode = FocusNode(debugLabel: 'first');
      final secondNode = FocusNode(debugLabel: 'second');
      addTearDown(firstNode.dispose);
      addTearDown(secondNode.dispose);

      await tester.pumpWidget(
        _wrap(
          child: Column(
            children: [
              AppTextField(label: 'First field', focusNode: firstNode),
              AppTextField(label: 'Second field', focusNode: secondNode),
            ],
          ),
        ),
      );

      firstNode.requestFocus();
      await tester.pump();
      expect(firstNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(firstNode.hasFocus, isFalse);
      expect(
        secondNode.hasFocus,
        isTrue,
        reason: 'Focus should advance to the next field on Tab',
      );
    });

    testWidgets('accepts keyboard input when focused', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        _wrap(
          child: AppTextField(
            label: 'Email',
            controller: controller,
            focusNode: focusNode,
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'hello@example.com');
      await tester.pump();

      expect(
        controller.text,
        'hello@example.com',
        reason: 'TextField should accept keyboard input when focused',
      );
    });

    testWidgets('label is announced in the widget tree for screen readers', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(child: const AppTextField(label: 'Email address')),
      );

      expect(
        find.text('Email address'),
        findsOneWidget,
        reason: 'Label text must be present for assistive technology',
      );
    });

    testWidgets('error text is announced in the widget tree', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: const AppTextField(
            label: 'Email',
            errorText: 'Invalid email address',
          ),
        ),
      );

      expect(find.text('Invalid email address'), findsOneWidget);
    });
  });

  // ------------------------------------------------------------------ //
  // AppButton – keyboard focus and activation
  // ------------------------------------------------------------------ //
  group('AppButton keyboard accessibility', () {
    testWidgets('is reachable via Tab', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: AppButton(label: 'Continue', onPressed: () {}),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<ElevatedButton>(),
        isNotNull,
        reason: 'AppButton (ElevatedButton) should receive focus via Tab',
      );
    });

    testWidgets('activates on Enter key', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        _wrap(
          child: AppButton(label: 'Submit', onPressed: () => pressed = true),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(pressed, isTrue, reason: 'Button should fire onPressed on Enter');
    });

    testWidgets('activates on Space key', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        _wrap(
          child: AppButton(label: 'Submit', onPressed: () => pressed = true),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(pressed, isTrue, reason: 'Button should fire onPressed on Space');
    });

    testWidgets('has button semantic role', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: AppButton(label: 'Continue', onPressed: () {}),
        ),
      );

      final semantics = tester.getSemantics(find.byType(AppButton));
      expect(
        semantics.getSemanticsData().flagsCollection.isButton,
        isTrue,
        reason: 'AppButton must advertise the button role to screen readers',
      );
    });

    testWidgets('button text is present in the accessibility tree', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          child: AppButton(label: 'Create account', onPressed: () {}),
        ),
      );

      expect(
        find.text('Create account'),
        findsOneWidget,
        reason: 'Button label must be accessible to screen readers',
      );
    });

    testWidgets('two sequential buttons are both reachable via Tab', (
      tester,
    ) async {
      var firstPressed = false;
      var secondPressed = false;

      await tester.pumpWidget(
        _wrap(
          child: Column(
            children: [
              AppButton(label: 'First', onPressed: () => firstPressed = true),
              AppButton(label: 'Second', onPressed: () => secondPressed = true),
            ],
          ),
        ),
      );

      // Tab to first button and activate
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(firstPressed, isTrue);

      // Tab to second button and activate
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(secondPressed, isTrue);
    });
  });

  // ------------------------------------------------------------------ //
  // AppDialog – focus management
  // ------------------------------------------------------------------ //
  group('AppDialog keyboard accessibility', () {
    testWidgets('focus is established inside dialog on open', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => AppDialog.show(
                ctx,
                title: 'Delete',
                body: 'Cannot be undone.',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
      expect(
        FocusManager.instance.primaryFocus,
        isNotNull,
        reason: 'A widget inside the dialog should hold keyboard focus',
      );
    });

    testWidgets('Tab reaches a dialog action button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => AppDialog.show(
                ctx,
                title: 'Confirm',
                body: 'Proceed?',
                cancelLabel: 'Cancel',
                confirmLabel: 'OK',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tab until an ElevatedButton inside the dialog receives focus
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        if (FocusManager.instance.primaryFocus?.context
                ?.findAncestorWidgetOfExactType<ElevatedButton>() !=
            null) {
          break;
        }
      }

      // Dialog must still be open (focus has not escaped to the opener)
      expect(find.text('Confirm'), findsOneWidget);
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<ElevatedButton>(),
        isNotNull,
        reason: 'Focus should land on a dialog action button via Tab',
      );
    });

    testWidgets('Cancel button can be activated via keyboard', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => TextButton(
              onPressed: () async {
                result = await AppDialog.show(
                  ctx,
                  title: 'Confirm',
                  body: 'Proceed?',
                  cancelLabel: 'Cancel',
                  confirmLabel: 'OK',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tab to the Cancel button (first action button in AlertDialog)
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        if (FocusManager.instance.primaryFocus?.context
                ?.findAncestorWidgetOfExactType<ElevatedButton>() !=
            null) {
          break;
        }
      }

      // Activate via Enter
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(result, isFalse, reason: 'Cancel button should return false');
    });

    testWidgets('Confirm button can be activated via keyboard', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => TextButton(
              onPressed: () async {
                result = await AppDialog.show(
                  ctx,
                  title: 'Confirm',
                  body: 'Proceed?',
                  cancelLabel: 'Cancel',
                  confirmLabel: 'Delete',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tab to Confirm (second action button — one Tab past Cancel)
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(result, isTrue, reason: 'Confirm button should return true');
    });

    testWidgets('dialog action buttons have accessible labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => AppDialog.show(
                ctx,
                title: 'Delete course',
                body: 'This action cannot be undone.',
                cancelLabel: 'Cancel',
                confirmLabel: 'Delete',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });

  // ------------------------------------------------------------------ //
  // Login form – Tab order
  //
  // Mirrors LoginScreen field structure (email → password → submit) using an
  // isolated layout. Full-screen tests are deferred to integration tests because
  // LoginScreen is a ConsumerStatefulWidget requiring Supabase / go_router stubs.
  // ------------------------------------------------------------------ //
  group('Login form tab order', () {
    testWidgets('Tab traverses email → password → submit in document order', (
      tester,
    ) async {
      final emailNode = FocusNode(debugLabel: 'login-email');
      final passwordNode = FocusNode(debugLabel: 'login-password');
      addTearDown(emailNode.dispose);
      addTearDown(passwordNode.dispose);

      await tester.pumpWidget(
        _wrap(
          child: Column(
            children: [
              AppTextField(
                label: 'Email',
                focusNode: emailNode,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              AppPasswordField(
                label: 'Password',
                focusNode: passwordNode,
                textInputAction: TextInputAction.done,
              ),
              AppButton(label: 'Sign in', onPressed: () {}),
            ],
          ),
        ),
      );

      // Step 1 – Email field
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        emailNode.hasFocus,
        isTrue,
        reason: 'Email should be first tab stop in login form',
      );

      // Step 2 – Password field
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(emailNode.hasFocus, isFalse);
      expect(
        passwordNode.hasFocus,
        isTrue,
        reason: 'Password should follow Email',
      );

      // Step 3 – Password visibility toggle (intermediate tab stop)
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(passwordNode.hasFocus, isFalse);

      // Step 4 – Submit button
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<ElevatedButton>(),
        isNotNull,
        reason: 'Submit button should be the final tab stop in login form',
      );
    });

    testWidgets('email field accepts typed input when focused', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(
          child: AppTextField(
            label: 'Email',
            controller: controller,
            keyboardType: TextInputType.emailAddress,
          ),
        ),
      );

      await tester.tap(find.byType(AppTextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'user@acendra.com');
      await tester.pump();

      expect(controller.text, 'user@acendra.com');
    });

    testWidgets('all login form widgets have semantic labels', (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: Column(
            children: [
              const AppTextField(label: 'Email'),
              const AppPasswordField(label: 'Password'),
              AppButton(label: 'Sign in', onPressed: () {}),
            ],
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });
  });

  // ------------------------------------------------------------------ //
  // Register form – Tab order
  //
  // Mirrors RegisterScreen field structure
  // (fullName → email → password → confirmPassword → submit).
  // Isolated layout for the same reasons as the login form tests above.
  // ------------------------------------------------------------------ //
  group('Register form tab order', () {
    testWidgets(
      'Tab traverses name → email → password → confirm → submit in order',
      (tester) async {
        final nameNode = FocusNode(debugLabel: 'register-name');
        final emailNode = FocusNode(debugLabel: 'register-email');
        final passwordNode = FocusNode(debugLabel: 'register-password');
        final confirmNode = FocusNode(debugLabel: 'register-confirm');
        addTearDown(nameNode.dispose);
        addTearDown(emailNode.dispose);
        addTearDown(passwordNode.dispose);
        addTearDown(confirmNode.dispose);

        await tester.pumpWidget(
          _wrap(
            child: Column(
              children: [
                AppTextField(
                  label: 'Full name',
                  focusNode: nameNode,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                ),
                AppTextField(
                  label: 'Email',
                  focusNode: emailNode,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                AppPasswordField(
                  label: 'Password',
                  focusNode: passwordNode,
                  textInputAction: TextInputAction.next,
                ),
                AppPasswordField(
                  label: 'Confirm password',
                  focusNode: confirmNode,
                  textInputAction: TextInputAction.done,
                ),
                AppButton(label: 'Create account', onPressed: () {}),
              ],
            ),
          ),
        );

        // Step 1 – Full name
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          nameNode.hasFocus,
          isTrue,
          reason: 'Full name should be first tab stop in register form',
        );

        // Step 2 – Email
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(nameNode.hasFocus, isFalse);
        expect(
          emailNode.hasFocus,
          isTrue,
          reason: 'Email should follow Full name',
        );

        // Step 3 – Password field
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(emailNode.hasFocus, isFalse);
        expect(
          passwordNode.hasFocus,
          isTrue,
          reason: 'Password should follow Email',
        );

        // Step 4 – Password visibility toggle (intermediate tab stop)
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(passwordNode.hasFocus, isFalse);

        // Step 5 – Confirm password field
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          confirmNode.hasFocus,
          isTrue,
          reason: 'Confirm password should follow Password (after its toggle)',
        );

        // Step 6 – Confirm visibility toggle (intermediate tab stop)
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(confirmNode.hasFocus, isFalse);

        // Step 7 – Submit button
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(nameNode.hasFocus, isFalse);
        expect(emailNode.hasFocus, isFalse);
        expect(passwordNode.hasFocus, isFalse);
        expect(confirmNode.hasFocus, isFalse);
        expect(
          FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<ElevatedButton>(),
          isNotNull,
          reason: 'Submit button should be the final tab stop in register form',
        );
      },
    );

    testWidgets('all register form widgets have semantic labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          child: Column(
            children: [
              const AppTextField(label: 'Full name'),
              const AppTextField(label: 'Email'),
              const AppPasswordField(label: 'Password'),
              const AppPasswordField(label: 'Confirm password'),
              AppButton(label: 'Create account', onPressed: () {}),
            ],
          ),
        ),
      );

      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsAtLeastNWidgets(1));
      expect(find.text('Confirm password'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
    });
  });

  // ------------------------------------------------------------------ //
  // Focus order – general traversal guarantee
  // ------------------------------------------------------------------ //
  group('Focus traversal', () {
    testWidgets('Shift+Tab moves focus backward through form fields', (
      tester,
    ) async {
      final firstNode = FocusNode(debugLabel: 'backward-first');
      final secondNode = FocusNode(debugLabel: 'backward-second');
      addTearDown(firstNode.dispose);
      addTearDown(secondNode.dispose);

      await tester.pumpWidget(
        _wrap(
          child: Column(
            children: [
              AppTextField(label: 'First', focusNode: firstNode),
              AppTextField(label: 'Second', focusNode: secondNode),
            ],
          ),
        ),
      );

      // Focus second field directly
      secondNode.requestFocus();
      await tester.pump();
      expect(secondNode.hasFocus, isTrue);

      // Shift+Tab should move focus back to first
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pump();

      expect(secondNode.hasFocus, isFalse);
      expect(
        firstNode.hasFocus,
        isTrue,
        reason: 'Shift+Tab should move focus to the previous field',
      );
    });
  });
}
