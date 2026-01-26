# YARC - Yet Another Reddit Client

A Flutter Reddit client following clean architecture principles.

## Architecture Overview

```
lib/
├── main.dart              # App entry point and dependency injection
├── models/                # Data classes (immutable data representations)
├── services/              # External API & persistence layer
├── repositories/          # Business logic combining services
├── notifiers/             # State management (ChangeNotifier)
├── screens/               # Full page widgets (routes)
├── widgets/               # Reusable UI components
├── theme/                 # App theming configuration
└── utils/                 # Utility functions and constants
```

## Layer Responsibilities

### Models (`models/`)
Pure Dart data classes representing domain entities. No business logic.
- `Post` - Reddit post with media extraction
- `Comment` - Nested comment structure
- `Subreddit` - Subreddit metadata

### Services (`services/`)
Low-level external interactions. Each service handles one concern:
- `AuthService` - OAuth authentication with Reddit
- `RedditService` - Reddit API calls via DRAW library
- `CacheService` - Local persistence with Hive

### Repositories (`repositories/`)
Orchestrate services and implement business logic:
- `AuthRepository` - Authentication state management
- `PostRepository` - Post fetching with caching strategy
- `SubredditRepository` - Subreddit operations

### Notifiers (`notifiers/`)
State management using `ChangeNotifier` pattern:
- `AuthNotifier` - Login/logout state
- `FeedNotifier` - Post feed with pagination
- `SubredditsNotifier` - Subscribed subreddits
- `SearchNotifier` - Subreddit search state

### Screens (`screens/`)
Full-page widgets that compose smaller widgets:
- `HomeScreen` - Main feed with navigation
- `PostDetailScreen` - Post content and comments

### Widgets (`widgets/`)
Reusable UI components. Each widget is focused and composable.

### Theme (`theme/`)
Centralized theming configuration using Material 3.

### Utils (`utils/`)
Shared utilities and constants:
- `constants.dart` - App-wide magic numbers
- `html_utils.dart` - HTML entity decoding
- `image_utils.dart` - Image URL processing
- `date_utils.dart` - Date formatting

## Data Flow

```
User Action → Screen → Notifier → Repository → Service → API/Cache
                                      ↓
                              Updates State
                                      ↓
                     Screen rebuilds via Provider.watch()
```

## Key Patterns

1. **Dependency Injection**: All dependencies provided via Provider
2. **Repository Pattern**: Abstracts data sources from business logic
3. **Notifier Pattern**: Reactive state management with ChangeNotifier
4. **Composition**: Widgets composed of smaller, reusable widgets
