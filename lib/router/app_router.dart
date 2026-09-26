import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/book_detail_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/scan_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'book/:id',
          name: 'book-detail',
          builder: (context, state) {
            final idString = state.pathParameters['id'] ?? '';
            final bookId = int.tryParse(idString);
            if (bookId == null) {
              return const Scaffold(
                body: Center(child: Text('Identifiant de livre invalide.'))
              );
            }
            return BookDetailScreen(bookId: bookId);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/scan',
      name: 'scan',
      builder: (context, state) => const ScanScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
