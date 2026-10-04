import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/cover_gradient.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/listing_rules.dart';
import '../../domain/entities/p2p_listing.dart';
import 'listing_cover.dart';
import 'listing_photo_viewer.dart';
import 'p2p_labels.dart';

/// The seller's photos of their copy, in slot order (front, back, spine,
/// inside, damage). Tapping one opens it larger. Nothing shows when the
/// server has no photos for the Listing.
class ListingPhotoGallery extends StatelessWidget {
  const ListingPhotoGallery({super.key, required this.listing});

  final P2pListing listing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final palette = context.palette;
    final slots = [
      for (final slot in ListingRules.photoSlots)
        if (listing.photoUrls[slot] case final url?) (slot, url),
    ];
    if (slots.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.listingStepPhotos),
        GridView.extent(
          maxCrossAxisExtent: 96,
          childAspectRatio: 3 / 4,
          mainAxisSpacing: Insets.sm,
          crossAxisSpacing: Insets.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final (i, (slot, url)) in slots.indexed)
              Semantics(
                button: true,
                label: l10n.photoSlot(slot),
                child: InkWell(
                  borderRadius: BorderRadius.circular(Radii.sm),
                  onTap: () => showListingPhoto(
                    context,
                    url: url,
                    label: l10n.photoSlot(slot),
                  ),
                  child: ListingCover(
                    photoUrl: url,
                    radius: Radii.sm,
                    art: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: CoverGradient.of(
                          palette.chipFor(listing.coverSeed + i),
                        ),
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                    ),
                    tag: _SlotTag(l10n.photoSlot(slot)),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SlotTag extends StatelessWidget {
  const _SlotTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: context.palette.scrim,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: AppFonts.ui(size: 9, weight: FontWeight.w800, color: Colors.white),
    ),
  );
}
