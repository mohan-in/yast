import 'package:flutter/material.dart';
import '../models/subreddit.dart';
import '../utils/image_utils.dart';

class AppDrawer extends StatelessWidget {
  final List<Subreddit> subreddits;
  final String? currentSubreddit;
  final Function(Subreddit?) onSubredditSelected;
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    required this.subreddits,
    this.currentSubreddit,
    required this.onSubredditSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    // Map from DESTINATION index (not child index) to action
    final indexToAction = <int, VoidCallback>{};
    int destinationCount = 0;

    // Helper to add a plain widget (not a destination)
    void addWidget(Widget widget) {
      children.add(widget);
    }

    // Helper to add a destination and map its destination index to an action
    void addDestination(Widget widget, VoidCallback action) {
      children.add(widget);
      // Map the current destination count to this action
      indexToAction[destinationCount] = action;
      destinationCount++;
    }

    // 1. Header "YARC" (Not a destination)
    addWidget(
      Padding(
        padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
        child: Text('YARC', style: Theme.of(context).textTheme.titleSmall),
      ),
    );

    // 2. Home Destination (Destination Index 0)
    addDestination(
      const NavigationDrawerDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: Text('Home'),
      ),
      () {
        debugPrint('Selecting Home');
        onSubredditSelected(null);
      },
    );

    // 3. Divider
    addWidget(
      const Padding(
        padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
        child: Divider(),
      ),
    );

    // 4. Header "Subscriptions"
    addWidget(
      Padding(
        padding: const EdgeInsets.fromLTRB(28, 10, 16, 10),
        child: Text(
          'Subscriptions',
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
    );

    // 5. Subreddits (Destination Indices 1 to N)
    for (final sub in subreddits) {
      addDestination(
        NavigationDrawerDestination(
          icon: sub.iconImg != null
              ? CircleAvatar(
                  radius: 12,
                  backgroundImage: NetworkImage(
                    ImageUtils.getCorsUrl(sub.iconImg!),
                  ),
                )
              : const Icon(Icons.reddit),
          label: Text(sub.displayName),
        ),
        () {
          debugPrint('Selecting Subreddit: ${sub.displayName}');
          onSubredditSelected(sub);
        },
      );
    }

    // 6. Divider
    addWidget(
      const Padding(
        padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
        child: Divider(),
      ),
    );

    // 7. Logout (Standard ListTile, NOT a NavigationDrawerDestination)
    // IMPORTANT: Standard ListTiles in the children list of NavigationDrawer
    // generally do NOT count as destinations for selectedIndex logic,
    // but they handle their own taps.
    // However, if we wanted it to be selectable, we might use NavigationDrawerDestination.
    // Here we treat it as a distinct action (Footer).
    addWidget(
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 28),
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text('Logout', style: TextStyle(color: Colors.red)),
        onTap: () {
          onLogout();
          Navigator.pop(context);
        },
      ),
    );

    // Calculate selected index (Destination Index)
    int selectedIndex = 0; // Default to Home (Destination 0)

    if (currentSubreddit != null) {
      final subIndex = subreddits.indexWhere(
        (s) => s.displayName == currentSubreddit,
      );
      if (subIndex != -1) {
        // Home is 0. Subreddits start at 1.
        selectedIndex = 1 + subIndex;
      }
    } else {
      selectedIndex = 0;
    }

    return NavigationDrawer(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        debugPrint('NavigationDrawer destination selection: $index');
        final action = indexToAction[index];
        if (action != null) {
          action();
        } else {
          debugPrint('No action for destination index $index');
        }
      },
      children: children,
    );
  }
}
