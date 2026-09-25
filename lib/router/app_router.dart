import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/scan_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/scan',
      name: 'scan',
      builder: (context, state) => const ScanScreen(),
    ),
  ],
);
