import 'package:flutter/material.dart';
import 'star_rating_widget.dart';

/// Widget to display product rating information
class RatingDisplay extends StatelessWidget {
  final double? averageRating;
  final int ratingCount;
  final double starSize;
  final bool showCount;
  final bool showNoRatingsMessage;

  const RatingDisplay({
    super.key,
    this.averageRating,
    this.ratingCount = 0,
    this.starSize = 16.0,
    this.showCount = true,
    this.showNoRatingsMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    if (averageRating == null || ratingCount == 0) {
      if (!showNoRatingsMessage) {
        return const SizedBox.shrink();
      }
      return Text(
        'No ratings yet',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
      );
    }

    return StarRatingDisplay(
      rating: averageRating!,
      ratingCount: ratingCount,
      starSize: starSize,
      showCount: showCount,
    );
  }
}

