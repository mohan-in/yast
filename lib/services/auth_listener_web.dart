import 'dart:async';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<String?> listenForAuthToken() {
  final completer = Completer<String?>();

  // Check if token is already there (unlikely race, but good to check)
  final existing = html.window.localStorage['auth_code'];
  if (existing != null) {
    html.window.localStorage.remove('auth_code');
    return Future.value(existing);
  }

  late StreamSubscription<html.StorageEvent> subscription;

  subscription = html.window.onStorage.listen((event) {
    if (event.key == 'auth_code' && event.newValue != null) {
      completer.complete(event.newValue);
      html.window.localStorage.remove('auth_code');
      subscription.cancel();
    }
  });

  // Timeout after 5 minutes to avoid memory leaks if user abandons
  Future.delayed(const Duration(minutes: 5), () {
    if (!completer.isCompleted) {
      subscription.cancel();
      completer.complete(null);
    }
  });

  return completer.future;
}
