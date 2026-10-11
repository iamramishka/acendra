import 'package:acendra/features/authentication/data/auth_repository.dart';
import 'package:acendra/features/authentication/presentation/widgets/logout_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super.forTesting();

  @override
  Future<void> signOut() async {}
}

Widget _wrap() => ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Center(child: LogoutButton()),
        ),
      ),
    );

void main() {
  testWidgets('renders logout button with sign out tooltip', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.byTooltip('Sign out'), findsOneWidget);
  });

  testWidgets('tapping button completes without error', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Sign out'), findsOneWidget);
  });
}
