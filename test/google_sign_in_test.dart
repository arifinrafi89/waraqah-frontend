import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:waraqah/features/auth/auth_routes.dart';
import 'package:waraqah/features/auth/data/sources/auth_remote_source.dart';
import 'package:waraqah/features/auth/presentation/providers/google_sign_in_providers.dart';

import 'helpers/app_harness.dart';

/// A backend that records each `/auth/google` body and signs the reader in.
class _Server implements HttpClientAdapter {
  final bodies = <Object?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    bodies.add(options.data);
    return ResponseBody.fromString(
      jsonEncode({
        'id': 'u_g',
        'name': 'Google Reader',
        'email': 'g@example.com',
        'role': 'reader',
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test("Google's ID token goes to /auth/google", () async {
    final server = _Server();
    final source = AuthRemoteSource(Dio()..httpClientAdapter = server);
    final user = await source.signInWithGoogle(idToken: 'google-id-token');
    expect(server.bodies.single, {'idToken': 'google-id-token'});
    expect(user.email, 'g@example.com');
  });

  test('without a token the body is empty (the fake API needs none)', () async {
    final server = _Server();
    await AuthRemoteSource(Dio()..httpClientAdapter = server)
        .signInWithGoogle();
    expect(server.bodies.single, <String, Object?>{});
  });

  testWidgets('on the fake API, Continue with Google signs the demo in', (
    tester,
  ) async {
    final router = await openApp(tester, AuthRoutes.login);
    await tester.tap(find.text('Continue with Google'));
    await settle(tester);
    expect(pathOf(router), isNot(AuthRoutes.login));
  });

  testWidgets('where Google sign-in cannot run, the button says so', (
    tester,
  ) async {
    final router = await openApp(
      tester,
      AuthRoutes.login,
      overrides: [
        googleSignInModeProvider.overrideWithValue(
          GoogleSignInMode.unavailable,
        ),
      ],
    );
    await tester.tap(find.text('Continue with Google'));
    await tester.pump();
    expect(
      find.text(
        'Google sign-in works in the web app for now. '
        'Log in with your email here.',
      ),
      findsOneWidget,
    );
    expect(pathOf(router), AuthRoutes.login);
  });
}
