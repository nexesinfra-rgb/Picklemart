import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A lazy-loading image widget that handles both network and asset images
/// with automatic caching, placeholders, and error handling.
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
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    // Handle network images (HTTP/HTTPS URLs)
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      // Encode the URL to properly handle spaces and special characters in filenames
      final encodedUrl = _encodeImageUrl(imageUrl);

      imageWidget = CachedNetworkImage(
        imageUrl: encodedUrl,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: fadeInDuration,
        fadeOutDuration: fadeOutDuration,
        placeholder: (context, url) => placeholder ?? _defaultPlaceholder(),
        errorWidget: (context, url, error) =>
            errorWidget ?? _defaultErrorWidget(),
        memCacheWidth: width != null && width!.isFinite ? width!.toInt() : null,
        memCacheHeight: height != null && height!.isFinite ? height!.toInt() : null,
      );
    } else {
      // Handle asset images
      final assetPath = imageUrl.startsWith('assets/')
          ? imageUrl
          : imageUrl.startsWith('product/')
              ? 'assets/$imageUrl'
              : 'assets/$imageUrl';

      imageWidget = Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            errorWidget ?? _defaultErrorWidget(),
      );
    }

    // Apply border radius if provided
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Encodes the URL path to properly handle spaces and special characters in filenames
  String _encodeImageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      // Encode each path segment to handle spaces and special characters
      final encodedPath = uri.pathSegments
          .map((segment) => Uri.encodeComponent(segment))
          .join('/');
      // Reconstruct the URL with encoded path
      final buffer = StringBuffer('${uri.scheme}://${uri.host}');
      if (uri.hasPort && uri.port != 80 && uri.port != 443) {
        buffer.write(':${uri.port}');
      }
      buffer.write('/$encodedPath');
      if (uri.hasQuery) {
        buffer.write('?${uri.query}');
      }
      return buffer.toString();
    } catch (e) {
      // If encoding fails, return original URL
      return url;
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
          Icons.broken_image,
          color: Color(0xFF9CA3AF),
          size: 32,
        ),
      ),
    );
  }
}

