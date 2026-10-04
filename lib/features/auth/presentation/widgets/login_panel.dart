import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/auth_failure.dart';
import '../providers/auth_providers.dart';
import '../providers/google_sign_in_providers.dart';
import 'auth_failure_text.dart';
import 'google_sign_in_button.dart';
import 'login_form.dart';

/// Runs the sign-in and shows its progress and errors.
///
/// There's no navigation here: once the session changes, the router's
/// guard moves the user off the login page by itself.
class LoginPanel extends ConsumerStatefulWidget {
  const LoginPanel({super.key});

  @override
  ConsumerState<LoginPanel> createState() => _LoginPanelState();
}

class _LoginPanelState extends ConsumerState<LoginPanel> {
  bool _busy = false;
  String? _error;

  /// Runs [signIn], showing an [AuthFailure]'s own message or [fallback].
  Future<void> _run(Future<void> Function() signIn, String fallback) async {
    final l10n = AppL10n.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await signIn();
    } on AuthFailure catch (failure) {
      _error = failure.message(l10n);
    } catch (_) {
      _error = fallback;
    }
    if (mounted) setState(() => _busy = false);
  }

  void _google({String? idToken}) => _run(
    () => ref.read(sessionProvider.notifier).signInWithGoogle(idToken: idToken),
    AppL10n.of(context)!.authGoogleFailed,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    if (ref.watch(googleSignInModeProvider) == GoogleSignInMode.googleButton) {
      // Google's button signs the reader in with Google; the server then
      // checks the ID token and signs them in to Waraqah.
      ref.listen(googleIdTokensProvider, (_, next) {
        if (next case AsyncData(:final value)) _google(idToken: value);
        if (next is AsyncError) setState(() => _error = l10n.authGoogleFailed);
      });
    }
    return LoginForm(
      isBusy: _busy,
      errorText: _error,
      onSubmit: (email, password) => _run(
        () => ref
            .read(sessionProvider.notifier)
            .signIn(email: email, password: password),
        l10n.commonSomethingWentWrong,
      ),
      google: GoogleSignInButton(
        isBusy: _busy,
        onPressed: _google,
        onUnavailable: () => setState(() => _error = l10n.authGoogleWebOnly),
      ),
      onForgotPassword: () => context.go('/login?forgot=1'),
    );
  }
}
