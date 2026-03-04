import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A lazy-loading image widget that handles both network and asset images
/// with automatic caching, placeholders, and error handling.
/// Now supports JPG, PNG, WEBP, and SVG formats.
class LazyImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final bool useOriginalQuality;

  const LazyImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.fill,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
    this.borderRadius,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.fadeOutDuration = const Duration(milliseconds: 100),
    this.useOriginalQuality = false,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _defaultErrorWidget();
    }

    // Check for unsupported extensions (HEIC, TIFF, etc.)
    // We do this check before network request to save bandwidth and show specific error
    final lowerUrl = imageUrl.toLowerCase();
    String extension = '';
    try {
      if (lowerUrl.contains('?')) {
        extension = lowerUrl.split('?').first.split('.').last;
      } else {
        extension = lowerUrl.split('.').last;
      }
    } catch (e) {
      // Ignore parsing errors here
    }

    if ([
      'heic',
      'tiff',
      'tif',
      'raw',
      'cr2',
      'nef',
      'orf',
      'sr2',
    ].contains(extension)) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: borderRadius,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.broken_image_outlined,
              color: Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'Format .$extension\nnot supported',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    Widget imageWidget;
    final isSvg = lowerUrl.contains('.svg');
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    // Handle network images (HTTP/HTTPS URLs)
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      // Encode the URL to properly handle spaces and special characters in filenames
      final encodedUrl = _encodeImageUrl(imageUrl);

      if (isSvg) {
        imageWidget = SvgPicture.network(
          encodedUrl,
          width: width,
          height: height,
          fit: fit,
          placeholderBuilder: (context) => placeholder ?? _defaultPlaceholder(),
        );
      } else {
        // Calculate cache dimensions based on device pixel ratio to ensure sharpness
        // If useOriginalQuality is true, we pass null to load original size
        final int? cacheWidth =
            useOriginalQuality || width == null || !width!.isFinite
                ? null
                : (width! * devicePixelRatio).toInt();
        final int? cacheHeight =
            useOriginalQuality || height == null || !height!.isFinite
                ? null
                : (height! * devicePixelRatio).toInt();

        imageWidget = CachedNetworkImage(
          imageUrl: encodedUrl,
          width: width,
          height: height,
          fit: fit,
          fadeInDuration: fadeInDuration,
          fadeOutDuration: fadeOutDuration,
          placeholder: (context, url) => placeholder ?? _defaultPlaceholder(),
          errorWidget:
              (context, url, error) => errorWidget ?? _defaultErrorWidget(),
          memCacheWidth: cacheWidth,
          memCacheHeight: cacheHeight,
        );
      }
    } else {
      // Handle asset images
      final assetPath =
          imageUrl.startsWith('assets/')
              ? imageUrl
              : imageUrl.startsWith('product/')
              ? 'assets/$imageUrl'
              : 'assets/$imageUrl';

      if (isSvg) {
        imageWidget = SvgPicture.asset(
          assetPath,
          width: width,
          height: height,
          fit: fit,
          placeholderBuilder: (context) => placeholder ?? _defaultPlaceholder(),
        );
      } else {
        imageWidget = Image.asset(
          assetPath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder:
              (context, error, stackTrace) =>
                  errorWidget ?? _defaultErrorWidget(),
        );
      }
    }

    // Apply border radius if provided
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  /// Encodes the URL path to properly handle spaces and special characters in filenames
  String _encodeImageUrl(String url) {
    try {
      // Check if URL is valid by parsing it
      final uri = Uri.parse(url);
      // If parsing succeeds, we return the original URL to avoid double-encoding
      // which happens when using the Uri constructor with an already encoded path.
      // For example, if path is "/foo%20bar.jpg", Uri(path: ...) would encode it to "/foo%2520bar.jpg"
      return url;
    } catch (e) {
      // If parsing fails, it's likely due to spaces or special chars.
      // We manually encode them.
      return url
          .replaceAll(' ', '%20')
          .replaceAll('[', '%5B')
          .replaceAll(']', '%5D')
          .replaceAll('(', '%28')
          .replaceAll(')', '%29');
    }
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFE5E7EB),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9CA3AF)),
        ),
      ),
    );
  }

  Widget _defaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFE5E7EB),
      child: const Center(
        child: Icon(
          Icons.image, // Use mountain icon which is cleaner than broken_image
          color: Color(0xFF9CA3AF),
          size: 32,
        ),
      ),
    );
  }
}
