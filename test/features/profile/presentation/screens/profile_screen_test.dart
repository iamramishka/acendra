import 'package:acendra/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:acendra/features/authentication/presentation/providers/logout_provider.dart';
import 'package:acendra/features/profile/presentation/providers/profile_provider.dart';
import 'package:acendra/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap({String? displayName, String? email}) => ProviderScope(
      overrides: [
        displayNameProvider.overrideWithValue(displayName),
        currentEmailProvider.overrideWithValue(email),
        logoutProvider.overrideWith(LogoutNotifier.new),
        authStreamProvider.overrideWith((ref) => const Stream.empty()),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    );

void main() {
  testWidgets('shows initials avatar from display name', (tester) async {
    await tester.pumpWidget(_wrap(displayName: 'Jane Doe', email: 'jane@example.com'));
    await tester.pumpAndSettle();
    expect(find.text('JD'), findsOneWidget);
  });

  testWidgets('shows single initial when display name is one word', (tester) async {
    await tester.pumpWidget(_wrap(displayName: 'Jane', email: 'jane@example.com'));
    await tester.pumpAndSettle();
    expect(find.text('J'), findsOneWidget);
  });

  testWidgets('shows initial from email when display name is null', (tester) async {
    await tester.pumpWidget(_wrap(email: 'alice@example.com'));
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('shows display name and email in profile tiles', (tester) async {
    await tester.pumpWidget(
      _wrap(displayName: 'Jane Doe', email: 'jane@example.com'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Jane Doe'), findsWidgets);
    expect(find.text('jane@example.com'), findsWidgets);
  });

  testWidgets('sign out button is present', (tester) async {
    await tester.pumpWidget(_wrap(email: 'test@example.com'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('edit profile icon button is present in app bar', (tester) async {
    await tester.pumpWidget(_wrap(email: 'test@example.com'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Edit profile'), findsOneWidget);
  });
}
