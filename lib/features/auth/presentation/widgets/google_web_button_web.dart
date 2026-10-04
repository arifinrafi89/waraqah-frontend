import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart';

/// Google's own "Continue with Google" button. On the web only Google's
/// button can start the sign-in that gives an ID token.
Widget googleWebButton() => renderButton(
  configuration: GSIButtonConfiguration(
    size: GSIButtonSize.large,
    text: GSIButtonText.continueWith,
    shape: GSIButtonShape.pill,
    minimumWidth: 280,
  ),
);
