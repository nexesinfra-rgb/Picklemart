import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LazyImage URL Encoding Logic', () {
    // Copy of the logic from LazyImage._encodeImageUrl
    String encodeImageUrl(String url) {
      if (!url.contains(' ') && !url.contains('[') && !url.contains(']')) {
        return url;
      }

      try {
        final uri = Uri.parse(url);
        final encodedUri = Uri(
          scheme: uri.scheme,
          userInfo: uri.userInfo,
          host: uri.host,
          port: uri.port,
          path: uri.path,
          query: uri.query.isEmpty ? null : uri.query,
          fragment: uri.fragment.isEmpty ? null : uri.fragment,
        );
        return encodedUri.toString();
      } catch (e) {
        return url
            .replaceAll(' ', '%20')
            .replaceAll('[', '%5B')
            .replaceAll(']', '%5D');
      }
    }

    test('should return valid URL as is', () {
      const url = 'https://example.com/image.jpg';
      expect(encodeImageUrl(url), equals(url));
    });

    test('should return encoded URL as is', () {
      const url = 'https://example.com/image%20with%20spaces.jpg';
      expect(encodeImageUrl(url), equals(url));
    });

    test('should encode spaces in URL', () {
      const url = 'https://example.com/image with spaces.jpg';
      const expected = 'https://example.com/image%20with%20spaces.jpg';
      expect(encodeImageUrl(url), equals(expected));
    });

    test('should encode brackets in URL', () {
      const url = 'https://example.com/image[1].jpg';
      const expected = 'https://example.com/image%5B1%5D.jpg';
      expect(encodeImageUrl(url), equals(expected));
    });

    test('should handle mixed spaces and brackets', () {
      const url = 'https://example.com/my image [final].jpg';
      const expected = 'https://example.com/my%20image%20%5Bfinal%5D.jpg';
      expect(encodeImageUrl(url), equals(expected));
    });

    test('should preserve query parameters with spaces encoded', () {
      const url = 'https://example.com/image.jpg?q=foo bar';
      // Uri.parse throws for space in query?
      // If Uri.parse succeeds, it encodes properly?
      // If Uri.parse throws, manual replacement handles it.
      const expected = 'https://example.com/image.jpg?q=foo%20bar';
      expect(encodeImageUrl(url), equals(expected));
    });

    test('should handle empty string', () {
      expect(encodeImageUrl(''), equals(''));
    });
  });
}
