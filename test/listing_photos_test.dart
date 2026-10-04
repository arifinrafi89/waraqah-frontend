import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:waraqah/core/theme/app_theme.dart';
import 'package:waraqah/features/moderation/data/models/queued_listing_model.dart';
import 'package:waraqah/features/p2p/data/models/p2p_listing_model.dart';
import 'package:waraqah/features/p2p/domain/entities/p2p_listing.dart';
import 'package:waraqah/features/p2p/presentation/widgets/listing_cover.dart';
import 'package:waraqah/features/p2p/presentation/widgets/listing_photo_gallery.dart';
import 'package:waraqah/l10n/app_localizations.dart';

const _front = 'https://res.cloudinary.com/demo/front.jpg';
const _back = 'https://res.cloudinary.com/demo/back.jpg';

Map<String, dynamic> _json([Map<String, Object?> extra = const {}]) => {
  'id': 'p2p-1',
  'title': 'Clean Code',
  'sellerId': 'u-1',
  'sellerName': 'Rafi',
  'priceBdt': 500,
  'condition': 'good',
  'photos': ['front', 'back'],
  ...extra,
};

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: Scaffold(body: child),
  ),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('a listing keeps the photo URLs the server sends (contract v1.1)', () {
    final listing = P2pListingModel.fromJson(
      _json({
        'photoUrls': {'front': _front, 'back': _back},
      }),
    ).toEntity();
    expect(listing.photoUrls, {'front': _front, 'back': _back});
    expect(listing.photos, ['front', 'back']);
  });

  test('no photo URLs (the fake API, or v1) is an empty map', () {
    expect(P2pListingModel.fromJson(_json()).toEntity().photoUrls, isEmpty);
    expect(
      P2pListingModel.fromJson(_json({'photoUrls': null})).photoUrls,
      isEmpty,
    );
  });

  test('the moderation queue keeps the photo URLs too', () {
    final queued = QueuedListingModel.fromJson(
      _json({
        'photoUrls': {'front': _front},
      }),
    ).toEntity();
    expect(queued.photoUrls, {'front': _front});
  });

  testWidgets('a cover without a photo shows the gradient art', (
    tester,
  ) async {
    await _pump(
      tester,
      const ListingCover(photoUrl: null, art: Text('art')),
    );
    expect(find.text('art'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('a photo that fails to load falls back to the art', (
    tester,
  ) async {
    await _pump(
      tester,
      const SizedBox(
        width: 100,
        height: 150,
        child: ListingCover(photoUrl: _front, art: Text('art')),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
    // Tests answer every image request with an error.
    await tester.pumpAndSettle();
    expect(find.text('art'), findsOneWidget);
  });

  testWidgets('the gallery shows the photos in slot order and opens one', (
    tester,
  ) async {
    const listing = P2pListing(
      id: 'p2p-1',
      title: 'Clean Code',
      sellerId: 'u-1',
      sellerName: 'Rafi',
      priceBdt: 500,
      photos: ['back', 'front', 'spine'],
      photoUrls: {'back': _back, 'front': _front},
    );
    await _pump(tester, const ListingPhotoGallery(listing: listing));
    final front = tester.getTopLeft(find.text('Front cover'));
    final back = tester.getTopLeft(find.text('Back cover'));
    expect(front.dx, lessThan(back.dx));
    // A slot without an uploaded photo has no tile.
    expect(find.text('Spine'), findsNothing);

    await tester.tap(find.text('Back cover'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('the gallery is empty without photo URLs', (tester) async {
    const listing = P2pListing(
      id: 'p2p-1',
      title: 'Clean Code',
      sellerId: 'u-1',
      sellerName: 'Rafi',
      priceBdt: 500,
      photos: ['front'],
    );
    await _pump(tester, const ListingPhotoGallery(listing: listing));
    expect(find.byType(ListingCover), findsNothing);
  });
}
