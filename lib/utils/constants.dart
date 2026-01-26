/// Application-wide constants for the YARC Reddit client.
library;

/// Scroll threshold (in pixels) before pagination triggers.
/// When user scrolls within this distance from the bottom, new posts load.
const int kPaginationThreshold = 800;

/// Scroll distance (in pixels) between image precache operations.
/// Throttles precaching to avoid excessive network calls.
const double kPrecacheScrollThreshold = 600;

/// Default number of posts to fetch per API request.
const int kDefaultPostLimit = 10;

/// Estimated height of a post card in pixels.
/// Used for calculating visible post indices during precaching.
const double kEstimatedPostCardHeight = 300;

/// Number of posts to prefetch ahead of the visible area.
const int kPrefetchPostCount = 5;

/// Number of visible posts before prefetch starts.
const int kVisiblePostsBeforePrefetch = 3;

/// Maximum subreddits to fetch for subscriptions list.
const int kMaxSubscribedSubreddits = 100;
