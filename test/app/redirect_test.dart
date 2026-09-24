import 'package:flutter_test/flutter_test.dart';
import 'package:localstore_app/app/redirect.dart';
import 'package:localstore_app/core/auth/session.dart';
import 'package:localstore_app/core/models/user.dart';

void main() {
  const customer = User(
    id: 'u1',
    phone: '+919999999990',
    name: 'S',
    role: 'CUSTOMER',
  );
  const owner = User(
    id: 'u2',
    phone: '+919999999999',
    name: 'O',
    role: 'OWNER',
  );
  const staff = User(
    id: 'u3',
    phone: '+919999999998',
    name: 'T',
    role: 'STAFF',
  );

  String? redirect(SessionState s, String location) =>
      redirectFor(session: s, uri: Uri.parse(location));

  group('guest', () {
    const guest = SessionState.guest();

    test('browses public routes freely', () {
      expect(redirect(guest, '/'), isNull);
      expect(redirect(guest, '/products/p1'), isNull);
      expect(redirect(guest, '/login'), isNull);
    });

    test('is sent to /login?from= for protected routes', () {
      expect(
        redirect(guest, '/orders'),
        '/login?from=${Uri.encodeComponent('/orders')}',
      );
      expect(
        redirect(guest, '/checkout/address'),
        '/login?from=${Uri.encodeComponent('/checkout/address')}',
      );
      expect(
        redirect(guest, '/orders/o1/pay'),
        '/login?from=${Uri.encodeComponent('/orders/o1/pay')}',
      );
      expect(redirect(guest, '/cart'), startsWith('/login?from='));
      expect(redirect(guest, '/account/addresses'), startsWith('/login?from='));
      expect(redirect(guest, '/owner'), startsWith('/login?from='));
    });
  });

  group('customer', () {
    const session = SessionState.signedIn(customer);

    test('reaches customer routes', () {
      expect(redirect(session, '/'), isNull);
      expect(redirect(session, '/orders'), isNull);
      expect(redirect(session, '/orders/o1'), isNull);
      expect(redirect(session, '/checkout'), isNull);
    });

    test('is blocked from /owner/**', () {
      expect(redirect(session, '/owner'), '/');
      expect(redirect(session, '/owner/orders/o1'), '/');
      expect(redirect(session, '/owner/products/new'), '/');
    });

    test('leaves /login for the from target, else home', () {
      expect(
        redirect(session, '/login?from=${Uri.encodeComponent('/orders/o1')}'),
        '/orders/o1',
      );
      expect(redirect(session, '/login'), '/');
    });
  });

  group('owner and staff', () {
    test('reach /owner/**', () {
      expect(redirect(const SessionState.signedIn(owner), '/owner'), isNull);
      expect(
        redirect(const SessionState.signedIn(staff), '/owner/products'),
        isNull,
      );
    });

    test('land on /owner after login unless an owner deep link was requested', () {
      expect(redirect(const SessionState.signedIn(owner), '/login'), '/owner');
      expect(
        redirect(
          const SessionState.signedIn(owner),
          '/login?from=${Uri.encodeComponent('/')}',
        ),
        '/owner',
      );
      // A customer-side `from` (e.g. the Orders tab) still lands in owner mode.
      expect(
        redirect(
          const SessionState.signedIn(staff),
          '/login?from=${Uri.encodeComponent('/orders')}',
        ),
        '/owner',
      );
      expect(
        redirect(
          const SessionState.signedIn(staff),
          '/login?from=${Uri.encodeComponent('/owner/orders/o1')}',
        ),
        '/owner/orders/o1',
      );
    });
  });

  test('unknown session never redirects', () {
    expect(redirect(const SessionState.unknown(), '/orders'), isNull);
    expect(redirect(const SessionState.unknown(), '/owner'), isNull);
  });

  test('path helpers', () {
    expect(isProtectedPath('/ordersx'), isFalse);
    expect(isProtectedPath('/orders'), isTrue);
    expect(isOwnerPath('/ownerx'), isFalse);
    expect(isOwnerPath('/owner/orders/1'), isTrue);
  });
}
