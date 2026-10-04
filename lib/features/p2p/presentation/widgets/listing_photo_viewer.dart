import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

/// Opens one listing photo over the page, to zoom in on its condition.
Future<void> showListingPhoto(
  BuildContext context, {
  required String url,
  required String label,
}) => showDialog<void>(
  context: context,
  builder: (context) => _ListingPhotoViewer(url: url, label: label),
);

class _ListingPhotoViewer extends StatelessWidget {
  const _ListingPhotoViewer({required this.url, required this.label});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(Insets.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(width: Insets.md),
              Expanded(
                child: Text(
                  label,
                  style: AppFonts.ui(
                    size: 14,
                    weight: FontWeight.w800,
                    color: palette.text,
                  ),
                ),
              ),
              const CloseButton(),
            ],
          ),
          Flexible(
            child: InteractiveViewer(
              maxScale: 4,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Padding(
                  padding: const EdgeInsets.all(Insets.xl),
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: palette.textFaint,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
