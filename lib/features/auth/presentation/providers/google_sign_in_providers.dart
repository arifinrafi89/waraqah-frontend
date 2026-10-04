import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_config.dart';
import '../../data/sources/google_id_tokens.dart';

/// How "Continue with Google" works in this build.
enum GoogleSignInMode {
  /// The fake API signs in its demo reader; no Google involved.
  fake,

  /// The web build against the backend: Google's own button.
  googleButton,

  /// Desktop against the backend: `google_sign_in` has no Linux or
  /// Windows support, so the button says it works on the web.
  unavailable,
}

final googleSignInModeProvider = Provider<GoogleSignInMode>(
  (ref) => ApiConfig.useFakeApi
      ? GoogleSignInMode.fake
      : kIsWeb
      ? GoogleSignInMode.googleButton
      : GoogleSignInMode.unavailable,
);

/// Google's ID token each time the reader signs in with Google's button.
final googleIdTokensProvider = StreamProvider<String>(
  (ref) => GoogleIdTokens().stream(),
);
