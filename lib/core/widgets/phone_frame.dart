import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// On the web, in a window wider than a tablet, shows the app as a centered
/// phone-sized screen, because the layouts are made for a phone. On a phone,
/// in a narrow window, and on every other platform it adds nothing.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child, this.enabled = kIsWeb});

  /// The width of the phone screen, in logical pixels.
  static const double phoneWidth = 390;

  /// Windows narrower than this are already phone-like and stay as they are.
  static const double wideFrom = 700;

  final Widget child;

  /// Off in tests and on the phone and desktop builds.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (!enabled || media.size.width < wideFrom) return child;
    final height = min(media.size.height - 24, 932.0);
    final size = Size(phoneWidth, height);
    return ColoredBox(
      color: const Color(0xFF1B1F1C),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 40,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: SizedBox.fromSize(
              size: size,
              // The app sees a phone-sized screen, so it picks its phone layout.
              child: MediaQuery(
                data: media.copyWith(
                  size: size,
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
