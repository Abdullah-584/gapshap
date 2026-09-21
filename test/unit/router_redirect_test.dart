import 'package:flutter_test/flutter_test.dart';
import 'package:gapshap/core/router/app_router.dart';

void main() {
  group('resolveAuthRedirect', () {
    test('routes authenticated users without a profile to onboarding', () {
      expect(
        resolveAuthRedirect(
          isAuthenticated: true,
          location: RouteNames.login,
          isProfileLoading: false,
          hasProfile: false,
          user: null,
        ),
        RouteNames.onboarding,
      );
    });

    test('routes authenticated users with a profile to the home tab', () {
      expect(
        resolveAuthRedirect(
          isAuthenticated: true,
          location: RouteNames.login,
          isProfileLoading: false,
          hasProfile: true,
          user: null,
        ),
        RouteNames.home,
      );
    });

    test(
      'keeps the email verification screen available while the user is unverified',
      () {
        expect(
          resolveAuthRedirect(
            isAuthenticated: true,
            location: RouteNames.emailVerification,
            isProfileLoading: false,
            hasProfile: false,
            user: null,
          ),
          isNull,
        );
      },
    );

    test('redirects unauthenticated people away from protected screens', () {
      expect(
        resolveAuthRedirect(
          isAuthenticated: false,
          location: '/profile',
          isProfileLoading: false,
          hasProfile: false,
          user: null,
        ),
        RouteNames.login,
      );
    });

    test('requires authentication before onboarding is accessible', () {
      expect(
        resolveAuthRedirect(
          isAuthenticated: false,
          location: RouteNames.onboarding,
          isProfileLoading: false,
          hasProfile: false,
          user: null,
        ),
        RouteNames.login,
      );
    });
  });
}
