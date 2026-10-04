import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_buttons.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/google_sign_in_providers.dart';
import 'auth_divider.dart';
import 'google_web_button.dart';

/// "Continue with Google", as this build can do it
/// ([googleSignInModeProvider]). [onPressed] runs for the fake API's demo
/// sign-in; [onUnavailable] where Google sign-in can't run.
class GoogleSignInButton extends ConsumerWidget {
  const GoogleSignInButton({
    super.key,
    required this.isBusy,
    required this.onPressed,
    required this.onUnavailable,
  });

  final bool isBusy;
  final VoidCallback onPressed;
  final VoidCallback onUnavailable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context)!;
    return switch (ref.watch(googleSignInModeProvider)) {
      GoogleSignInMode.googleButton => Center(
        child: SizedBox(
          height: 44,
          child: IgnorePointer(ignoring: isBusy, child: googleWebButton()),
        ),
      ),
      final mode => SecondaryButton(
        label: l10n.authContinueWithGoogle,
        icon: const GoogleGlyph(),
        onPressed: isBusy
            ? null
            : mode == GoogleSignInMode.fake
            ? onPressed
            : onUnavailable,
      ),
    };
  }
}
