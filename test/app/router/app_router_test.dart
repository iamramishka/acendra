import 'package:acendra/app/router/route_names.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteNames', () {
    test('home is /', () => expect(RouteNames.home, '/'));
    test('marketplace is /marketplace', () {
      expect(RouteNames.marketplace, '/marketplace');
    });
    test('login is /login', () => expect(RouteNames.login, '/login'));
    test('register is /register', () {
      expect(RouteNames.register, '/register');
    });
    test('dashboard is /dashboard', () {
      expect(RouteNames.dashboard, '/dashboard');
    });
  });
}
