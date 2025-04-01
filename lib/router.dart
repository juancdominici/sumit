import 'package:go_router/go_router.dart';
import 'package:sumit/utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:june/june.dart';
import 'package:sumit/state/settings.dart';

import 'screens/home_screen.dart';
import 'screens/auth/module.dart';
import 'screens/groups/group_list_screen.dart';

final supabase = Supabase.instance.client;

bool isAuthenticated() => supabase.auth.currentUser != null;

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final uri = state.uri;

    logger.i('Router redirect: ${uri.toString()}');

    // Deep link handling for auth callbacks and group joins
    if (uri.toString().startsWith('ar.com.sumit')) {
      if (uri.toString().contains('/auth-callback')) {
        return '/auth-callback';
      }
    }

    // Standard authentication flow
    final isLoggedIn = isAuthenticated();
    final isOnAuthScreen =
        state.uri.path == '/auth' || state.uri.path == '/auth-callback';
    final isOnSignupConfigScreen = state.uri.path == '/signup-config';
    final isOnGroupCreationScreen = state.uri.path == '/group-creation';
    final isOnGroupJoinScreen = state.uri.path.startsWith('/join/');

    logger.i(
      'Auth state: isLoggedIn=$isLoggedIn, isOnAuthScreen=$isOnAuthScreen, path=${state.uri.path}',
    );

    if (!isLoggedIn && !isOnAuthScreen && !isOnGroupJoinScreen) {
      logger.i('Not logged in, redirecting to auth');
      return '/auth';
    }

    if (isLoggedIn) {
      final settingsState = June.getState(() => SettingsState());

      // If settings are still loading, don't redirect
      if (settingsState.isLoading) {
        return null;
      }

      // If we're already on signup-config, group-creation, or group-join, stay there
      if (isOnSignupConfigScreen ||
          isOnGroupCreationScreen ||
          isOnGroupJoinScreen) {
        return null;
      }

      // Check if user needs to complete signup config
      if (!settingsState.userPreferences.hasFirstLogin) {
        return '/signup-config';
      }

      // Check if user needs to create a group
      if (!settingsState.userPreferences.hasCreatedGroup) {
        return '/group-creation';
      }

      // If on auth screen, redirect to home
      if (isOnAuthScreen) {
        return '/';
      }
    }

    logger.i('No redirection needed');
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/auth',
      builder: (context, state) {
        final error = state.uri.queryParameters['error'];
        return AuthScreen(error: error);
      },
    ),
    GoRoute(
      path: '/auth-callback',
      builder: (context, state) {
        final error = state.uri.queryParameters['error'];
        return AuthScreen(error: error, isCallback: true);
      },
    ),
    GoRoute(
      path: '/signup-config',
      builder: (context, state) => const SignupConfigScreen(),
    ),
    GoRoute(
      path: '/group-creation',
      builder: (context, state) => const GroupCreationScreen(),
    ),
    GoRoute(
      path: '/groups',
      builder: (context, state) => const GroupListScreen(),
    ),
  ],
);
