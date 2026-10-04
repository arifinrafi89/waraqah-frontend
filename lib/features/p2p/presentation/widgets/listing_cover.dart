import 'package:flutter/material.dart';

/// A Listing's picture: the seller's photo at [photoUrl] when the server
/// has one, otherwise [art] (the seeded gradient cover). [art] also shows
/// while the photo loads and if it fails, so a card never goes blank.
/// [tag] sits in the top corner over the photo, as on [art].
class ListingCover extends StatelessWidget {
  const ListingCover({
    super.key,
    required this.photoUrl,
    required this.art,
    this.radius = 0,
    this.tag,
  });

  final String? photoUrl;
  final Widget art;
  final double radius;
  final Widget? tag;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    if (url == null) return _withTag(art);
    return _withTag(
      ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          frameBuilder: (_, image, frame, sync) =>
              frame == null && !sync ? art : image,
          errorBuilder: (_, _, _) => art,
        ),
      ),
    );
  }

  Widget _withTag(Widget child) => tag == null
      ? child
      : Stack(
          fit: StackFit.expand,
          children: [
            child,
            Positioned(top: 7, right: 7, child: tag!),
          ],
        );
}
