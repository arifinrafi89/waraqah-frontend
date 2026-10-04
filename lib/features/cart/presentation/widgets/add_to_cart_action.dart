import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/auth_routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../cart_routes.dart';
import '../../domain/entities/cart_item_ref.dart';
import '../providers/cart_providers.dart';

/// The one way any page puts something in the cart:
///
/// ```dart
/// ref.addToCart(context, CartItemRef.edition(edition.id));
/// ```
///
/// It tells the reader what happened ("Added to cart · View cart", or why it
/// couldn't). With [openCart] (Buy now) it goes straight to the cart instead.
/// Answers whether the item is in the cart now (false on an error, and for a
/// guest, who is taken to the login page).
extension AddToCartAction on WidgetRef {
  Future<bool> addToCart(
    BuildContext context,
    CartItemRef item, {
    bool openCart = false,
  }) async {
    final l10n = AppL10n.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final busy = read(addingToCartProvider.notifier);
    final cart = read(cartProvider.notifier);

    // The cart belongs to a reader: guests sign in first, then come back.
    if (read(sessionProvider) == null) {
      router.push(AuthRoutes.login);
      return false;
    }

    busy.select(true);
    bool? added;
    try {
      added = await cart.add(item);
    } catch (_) {
      added = null;
    } finally {
      busy.select(false);
    }

    messenger.hideCurrentSnackBar();
    if (added != null && openCart) {
      router.push(CartRoutes.cart);
      if (added) return true;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (added) {
          true => l10n.cartAdded,
          false => l10n.cartLimitReached,
          null => l10n.commonSomethingWentWrong,
        }),
        action: added == true
            ? SnackBarAction(
                label: l10n.cartView,
                onPressed: () => router.push(CartRoutes.cart),
              )
            : null,
        // Flutter keeps snackbars with a button up until dismissed; this one
        // should go by itself so it doesn't sit over the page.
        persist: false,
      ),
    );
    return added != null;
  }
}
