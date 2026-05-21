import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/results_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/search_history_screen.dart';
import 'screens/price_alerts_screen.dart';
import 'screens/profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', name: 'splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', name: 'login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/', name: 'home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/camera', name: 'camera', builder: (_, __) => const CameraScreen()),
      GoRoute(path: '/results', name: 'results', builder: (_, __) => const ResultsScreen()),
      GoRoute(path: '/detail/:id', name: 'detail',
          builder: (_, state) => DetailScreen(productId: state.pathParameters['id'] ?? '')),
      GoRoute(path: '/favorites', name: 'favorites', builder: (_, __) => const FavoritesScreen()),
      GoRoute(path: '/search-history', name: 'search-history', builder: (_, __) => const SearchHistoryScreen()),
      GoRoute(path: '/price-alerts', name: 'price-alerts', builder: (_, __) => const PriceAlertsScreen()),
      GoRoute(path: '/profile', name: 'profile', builder: (_, __) => const ProfileScreen()),
    ],
  );
});

class SmartShoppingApp extends ConsumerWidget {
  const SmartShoppingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '识物比价',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      routerConfig: router,
    );
  }
}
