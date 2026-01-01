import 'package:flutter/foundation.dart';

class ImageUtils {
  static String getCorsUrl(String url) {
    if (kIsWeb) {
      // Use images.weserv.nl as a CORS proxy/cache.
      // It is robust and handles SSL/CORS correctly for embedding.
      // Remove 'https://' from the url for weserv (it expects the host directly or encoded)
      // Standard format: https://images.weserv.nl/?url=example.com/image.jpg
      return 'https://images.weserv.nl/?url=${Uri.encodeComponent(url)}';
    }
    return url;
  }
}
