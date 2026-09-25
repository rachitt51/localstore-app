import '../core/auth/session.dart';
import '../core/models/user.dart';

/// Route prefixes that need a signed-in user.
const protectedPrefixes = [
  '/cart',
  '/checkout',
  '/orders',
  '/account',
  '/owner',
  '/visit',
];

bool isProtectedPath(String path) =>
    protectedPrefixes.any((p) => path == p || path.startsWith('$p/'));

bool isOwnerPath(String path) => path == '/owner' || path.startsWith('/owner/');

/// Where a user lands right after signing in.
String landingFor(User user, {String? from}) {
  // Owner/staff go to owner mode unless they were heading somewhere in it.
  if (user.isStaff) {
    return from != null && isOwnerPath(Uri.parse(from).path) ? from : '/owner';
  }
  if (from != null && from.isNotEmpty && from != '/') return from;
  return '/';
}

/// Pure redirect rule for the router (unit-tested). Returns the location to
/// go to, or null to stay.
String? redirectFor({required SessionState session, required Uri uri}) {
  final path = uri.path;
  final isLogin = path == '/login';
  switch (session.status) {
    case SessionStatus.unknown:
      // Session restore is awaited in main(); nothing to decide yet.
      return null;
    case SessionStatus.guest:
      if (isProtectedPath(path)) {
        return '/login?from=${Uri.encodeComponent(uri.toString())}';
      }
      return null;
    case SessionStatus.signedIn:
      final user = session.user!;
      if (isLogin) {
        return landingFor(user, from: uri.queryParameters['from']);
      }
      if (isOwnerPath(path) && !user.isStaff) return '/';
      return null;
  }
}
