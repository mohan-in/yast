# YARC - Yet Another Reddit Client

A clean and modern Reddit client built with Flutter, designed to provide a seamless browsing experience.

## Features
- **Feed Browsing**: Seamlessly browse your favorite subreddits and custom feeds.
- **Rich Media Support**: Native support for high-quality images, galleries, videos, and YouTube embeds.
- **Markdown Rendering**: Beautiful rendering of text posts and nested comments with proper formatting.
- **Search**: Easily discover new communities with subreddit search.
- **Subreddit Info**: View details, subscriber counts, and descriptions for subreddits.
- **Authentication**: Secure login to access your personal front page and subscriptions.
- **Modern UI**: Polished interface following Material Design guidelines properly adapted for mobile.

## Technology Stack
- **Framework**: Flutter & Dart
- **State Management**: Provider
- **Reddit API**: DRAW (Reddit API Wrapper)
- **Local Storage**: Hive & SharedPreferences
- **Authentication**: Flutter Web Auth 2
- **Media**: Chewie (Video), YouTube Player Flutter
- **Rendering**: Flutter Markdown Plus, Cached Network Image
- **Utils**: Intl, HTML Unescape

## Getting Started

To run this app, you need a Reddit API Client ID.

1.  Create a new app on the [Reddit API website](https://www.reddit.com/prefs/apps/).
2.  Select **"installed app"**.
3.  Set the redirect URI to `com.mohan.reddit.client://callback`.
4.  Copy your **Client ID**.

Run the app using the following command:

```bash
flutter run --dart-define=REDDIT_CLIENT_ID=YOUR_CLIENT_ID
```

Replace `YOUR_CLIENT_ID` with the actual ID you obtained from Reddit.

## Documentation

For detailed architecture and project structure, see [ARCHITECTURE.md](ARCHITECTURE.md).