import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/image_utils.dart';
import 'full_screen_image_view.dart';

class LinkableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? linkStyle;

  const LinkableText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
    this.linkStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: _parseText(text, context)),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  List<InlineSpan> _parseText(String text, BuildContext context) {
    // Regex to match URLs
    final RegExp urlRegex = RegExp(
      r'((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?',
      caseSensitive: false,
    );

    final List<InlineSpan> spans = [];
    int start = 0;
    Iterable<Match> matches = urlRegex.allMatches(text);

    for (Match match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }

      final String url = match.group(0)!;
      final bool isImage = _isImageUrl(url);

      if (isImage) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImageView(imageUrls: [url]),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    ImageUtils.getCorsUrl(url),
                    headers: kIsWeb
                        ? null
                        : const {
                            'User-Agent':
                                'flutter_reddit_demo/1.0.0 (by /u/antigravity)',
                          },
                    height: 200, // Constrain height for inline images
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to text link if image fails to load
                      return Text(
                        url,
                        style:
                            linkStyle ??
                            TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: url,
            style:
                linkStyle ??
                TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                String launchUrlString = url;
                if (!url.startsWith('http')) {
                  launchUrlString = 'https://$url';
                }
                final Uri uri = Uri.parse(launchUrlString);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
          ),
        );
      }
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return spans;
  }

  bool _isImageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final path = uri.path.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.gif') ||
        path.endsWith('.webp');
  }
}
