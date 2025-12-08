import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbuy/src/ui/routes/home_screen_router.dart';
import 'package:smartbuy/src/ui/screens/insights_screen.dart';
import 'package:smartbuy/src/ui/screens/lists_screen.dart';
import 'package:smartbuy/src/ui/screens/profile_screen.dart';
import 'package:smartbuy/src/ui/screens/settings_screen.dart';
import 'package:smartbuy/src/ui/screens/sign_in_screen.dart';
import 'package:smartbuy/src/ui/screens/invite_screen.dart';
import 'package:smartbuy/src/ui/screens/pantry_screen.dart';
import 'package:smartbuy/src/ui/screens/forgot_password_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  initialLocation: '/sign-in',
  navigatorKey: _rootNavigatorKey,
  routes: [
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/invite/:inviteId',
      builder: (context, state) {
        final inviteId = state.pathParameters['inviteId']!;
        return InviteScreen(inviteId: inviteId);
      },
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return HomeScreenRouter(child: child);
      },
      routes: [
        GoRoute(
          path: '/lists',
          builder: (context, state) => const ListsScreen(),
        ),
        GoRoute(
          path: '/insights',
          builder: (context, state) => const InsightsScreen(),
        ),
        GoRoute(
          path: '/pantry', // Added PantryScreen route
          builder: (context, state) => const PantryScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
