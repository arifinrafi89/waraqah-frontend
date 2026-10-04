import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/cover_gradient.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../p2p/presentation/widgets/listing_cover.dart';
import '../../../p2p/presentation/widgets/listing_photo_viewer.dart';
import '../../domain/entities/queued_listing.dart';
import 'moderation_labels.dart';

/// The seller's photos, one tile each, named by what they show. A slot
/// the server has a photo for shows it (tap to see it larger); the fake
/// API only names the slots, so those show a coloured tile.
class ListingPhotoStrip extends StatelessWidget {
  const ListingPhotoStrip({super.key, required this.listing});

  final QueuedListing listing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context)!;
    if (listing.photos.isEmpty) {
      return Text(
        l10n.moderationNoPhotos,
        style: AppFonts.ui(size: 12, color: palette.danger),
      );
    }
    return GridView.extent(
      maxCrossAxisExtent: 72,
      childAspectRatio: 3 / 4,
      mainAxisSpacing: Insets.sm,
      crossAxisSpacing: Insets.sm,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final (i, slot) in listing.photos.indexed)
          _PhotoTile(
            label: l10n.photoLabel(slot),
            url: listing.photoUrls[slot],
            seed: listing.coverSeed + i,
          ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.label,
    required this.url,
    required this.seed,
  });

  final String label;
  final String? url;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final photo = url;
    final tile = ClipRRect(
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ListingCover(
            photoUrl: photo,
            art: DecoratedBox(
              decoration: BoxDecoration(
                gradient: CoverGradient.of(palette.chipFor(seed)),
              ),
            ),
          ),
          Container(
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.all(6),
            child: Text(
              label,
              style:
                  AppFonts.ui(
                    size: 10,
                    weight: FontWeight.w800,
                    color: photo == null ? palette.accentInk : Colors.white,
                  ).copyWith(
                    // Readable over any photo.
                    shadows: [
                      if (photo != null)
                        Shadow(color: palette.scrim, blurRadius: 4),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
    if (photo == null) return tile;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () => showListingPhoto(context, url: photo, label: label),
        child: tile,
      ),
    );
  }
}
