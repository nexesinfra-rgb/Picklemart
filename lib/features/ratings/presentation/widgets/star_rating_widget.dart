import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

/// Interactive star rating widget for input
class StarRatingInput extends StatefulWidget {
  final int initialRating;
  final ValueChanged<int>? onRatingChanged;
  final double starSize;
  final Color? starColor;
  final bool enabled;

  const StarRatingInput({
    super.key,
    this.initialRating = 0,
    this.onRatingChanged,
    this.starSize = 24.0,
    this.starColor,
    this.enabled = true,
  });

  @override
  State<StarRatingInput> createState() => _StarRatingInputState();
}

class _StarRatingInputState extends State<StarRatingInput> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  void didUpdateWidget(StarRatingInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRating != widget.initialRating) {
      _currentRating = widget.initialRating;
    }
  }

  void _handleTap(int rating) {
    if (!widget.enabled) return;

    setState(() {
      _currentRating = rating;
    });

    widget.onRatingChanged?.call(rating);
  }

  @override
  Widget build(BuildContext context) {
    final starColor = widget.starColor ?? Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        final isFilled = starNumber <= _currentRating;

        return GestureDetector(
          onTap: widget.enabled ? () => _handleTap(starNumber) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Icon(
              isFilled ? Ionicons.star : Ionicons.star_outline,
              size: widget.starSize,
              color:
                  isFilled
                      ? starColor
                      : (widget.enabled
                          ? Colors.grey.shade400
                          : Colors.grey.shade300),
            ),
          ),
        );
      }),
    );
  }
}

/// Display-only star rating widget
class StarRatingDisplay extends StatelessWidget {
  final double rating; // 0.0 to 5.0
  final int? ratingCount;
  final double starSize;
  final Color? starColor;
  final bool showCount;
  final TextStyle? countTextStyle;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.ratingCount,
    this.starSize = 16.0,
    this.starColor,
    this.showCount = true,
    this.countTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    final starColor = this.starColor ?? Theme.of(context).colorScheme.primary;

    // Calculate filled and half stars
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Stars
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Full stars
            ...List.generate(fullStars, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.0),
                child: Icon(Ionicons.star, size: starSize, color: starColor),
              );
            }),
            // Half star
            if (hasHalfStar)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.0),
                child: Icon(
                  Ionicons.star_half,
                  size: starSize,
                  color: starColor,
                ),
              ),
            // Empty stars
            ...List.generate(emptyStars, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.0),
                child: Icon(
                  Ionicons.star_outline,
                  size: starSize,
                  color: Colors.grey.shade400,
                ),
              );
            }),
          ],
        ),
        // Rating text and count
        if (showCount && ratingCount != null && ratingCount! > 0) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            '($ratingCount)',
            style:
                countTextStyle ??
                Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ] else if (showCount && (ratingCount == null || ratingCount! == 0)) ...[
          const SizedBox(width: 4),
          Text(
            'No ratings yet',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }
}
