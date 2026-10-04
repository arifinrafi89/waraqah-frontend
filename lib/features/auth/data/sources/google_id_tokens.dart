import 'package:google_sign_in/google_sign_in.dart';

/// Google's ID tokens for the reader, one each time they finish Google's
/// sign-in. On the web the reader signs in with Google's own button
/// (`google_web_button.dart`), which reads the client id from the
/// `google-signin-client_id` meta tag in `web/index.html`.
class GoogleIdTokens {
  static Future<void>? _ready;

  Stream<String> stream() async* {
    await (_ready ??= GoogleSignIn.instance.initialize());
    yield* GoogleSignIn.instance.authenticationEvents
        .where((event) => event is GoogleSignInAuthenticationEventSignIn)
        .map(
          (event) => (event as GoogleSignInAuthenticationEventSignIn)
              .user
              .authentication
              .idToken,
        )
        .where((token) => token != null)
        .cast<String>();
  }
}
