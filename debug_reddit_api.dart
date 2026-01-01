// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'lib/models/post.dart';

void main() async {
  final subreddit = 'vanlife';
  final url = Uri.parse('https://www.reddit.com/r/$subreddit/hot.json');
  print('Fetching from $url...');

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> children = data['data']['children'];

      print('Found ${children.length} posts.');

      for (var i = 0; i < children.length && i < 5; i++) {
        final item = children[i];
        final post = Post.fromJson(item);

        print('\n--- Post $i ---');
        print('Title: ${post.title}');
        print('Raw URL: ${item['data']['url']}');
        print('Thumbnail: ${post.thumbnail}');
        print('Has Preview: ${item['data']['preview'] != null}');
        if (item['data']['preview'] != null) {
          final images = item['data']['preview']['images'];
          if (images != null && images.isNotEmpty) {
            print('Preview Source URL: ${images[0]['source']['url']}');
          }
        }
        if (item['data']['media_metadata'] != null) {
          print('Has Media Metadata: true');
          final metadata = item['data']['media_metadata'] as Map;
          print('Media keys: ${metadata.keys.toList()}');
          if (metadata.isNotEmpty) {
            final firstKey = metadata.keys.first;
            print('First media item status: ${metadata[firstKey]['status']}');
            if (metadata[firstKey]['s'] != null) {
              print('First media item URL: ${metadata[firstKey]['s']['u']}');
            }
          }
        }
        print('Parsed ImageURL: ${post.imageUrl}');
      }
    } else {
      print('Failed to load: ${response.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
