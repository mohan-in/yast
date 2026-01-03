import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/service_locator.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'services/post_cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  setupServiceLocator();
  await PostCacheService.init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YARC - Yet Another Reddit Client',
      theme: appTheme,
      home: const HomeScreen(),
    );
  }
}
