import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irise/providers/auth_provider.dart';
import 'package:irise/route/app_router.dart';
import 'package:provider/provider.dart';
import 'app_routes.dart';

String? authGuard(BuildContext context, GoRouterState state) {
  final auth = Provider.of<AuthProvider>(context, listen: false);

  final isAuthRoute = state.matchedLocation == AppRoutes.login ||
      state.matchedLocation == AppRoutes.forgotPassword ||
      state.matchedLocation == AppRoutes.splash;

  switch (auth.status) {
    case AuthStatus.unknown:
      // Still initializing — go to splash
      return state.matchedLocation == AppRoutes.splash
          ? null
          : AppRoutes.splash;

    case AuthStatus.unauthenticated:
      // Not logged in — force login, but allow splash to handle its own navigation
      if (state.matchedLocation == AppRoutes.splash) {
        return null; // Let splash screen handle navigation
      }
      return isAuthRoute ? null : AppRoutes.login;

    case AuthStatus.authenticated:
      // Logged in — don't allow going back to login/splash
      if (isAuthRoute) return AppRoutes.dashboard;
      return null;
  }
}
