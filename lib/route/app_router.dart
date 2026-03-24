import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irise/route/app_routes.dart';
import 'package:irise/view/screen/beneficiary.dart';
import 'package:irise/view/screen/conduct_training.dart';
import 'package:irise/view/screen/home.dart';
import 'package:irise/view/screen/login.dart';
import 'package:irise/view/screen/modules.dart';
import 'package:irise/view/screen/monitoring.dart';
import 'package:irise/view/screen/splash.dart';
import 'package:irise/view/screen/training_point_identification.dart';
import 'package:irise/providers/auth_provider.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      // ─── Splash ───────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ─── Login ────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ─── Forgot Password ──────────────────────────────────
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),

      // ─── Dashboard Shell ──────────────────────────────────
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DashboardScreen(),
          transitionsBuilder: _fadeTransition,
        ),
        routes: [
          // Modules
          GoRoute(
            path: 'modules',
            name: 'modules',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ModulesScreen(),
              transitionsBuilder: _slideUpTransition,
            ),
          ),
          
          // Beneficiary
          GoRoute(
            path: 'beneficiary_list',
            name: 'beneficiary_list',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const BeneficiaryListScreen(),
              transitionsBuilder: _slideRightTransition,
            ),
            routes: [
              GoRoute(
                path: ':id',
                name: 'beneficiary-detail',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: BeneficiaryDetailScreen(
                    id: state.pathParameters['id']!,
                  ),
                  transitionsBuilder: _slideRightTransition,
                ),
              ),
            ],
          ),

          // Monitoring
          GoRoute(
            path: 'monitoring',
            name: 'monitoring',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const MonitoringScreen(),
              transitionsBuilder: _slideRightTransition,
            ),
            routes: [
              GoRoute(
                path: ':id',
                name: 'monitoring-detail',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: MonitoringDetailScreen(
                    id: state.pathParameters['id']!,
                  ),
                  transitionsBuilder: _slideRightTransition,
                ),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: AppRoutes.training_point_identification,
        name: 'training_point_identification',
        pageBuilder: (context, state) {
          final trainingPointId = state.uri.queryParameters['trainingPointId'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: TrainingPointIdentificationScreen(
              trainingPointId: trainingPointId,
            ),
            transitionsBuilder: _slideUpTransition,
          );
        },
      ),

      GoRoute(
        path: AppRoutes.training_site,
        name: 'training_site',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ConductTrainingScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),

      GoRoute(
        path: AppRoutes.conduct_training_list,
        name: 'conduct_training_list',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ConductTrainingScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),

      // ─── Profile ──────────────────────────────────────────
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ProfileScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),

      // ─── Notifications ────────────────────────────────────
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NotificationsScreen(),
          transitionsBuilder: _slideRightTransition,
        ),
      ),
    ],
  );
}

// ─── Transition Builders ──────────────────────────────────────────────────────

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

Widget _slideRightTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
    child: child,
  );
}

Widget _slideUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
    child: child,
  );
}

// ─── Error Screen ─────────────────────────────────────────────────────────────

class _ErrorScreen extends StatelessWidget {
  final Exception? error;
  const _ErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Page Not Found',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error?.toString() ?? 'Unknown error',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50)),
              child:
                  const Text('Go Home', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder screens — replace with real implementations
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Forgot Password')));
}

class BeneficiaryDetailScreen extends StatelessWidget {
  final String id;
  const BeneficiaryDetailScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Beneficiary #$id')));
}

class TrainingDetailScreen extends StatelessWidget {
  final String id;
  const TrainingDetailScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Training #$id')));
}

class MonitoringDetailScreen extends StatelessWidget {
  final String id;
  const MonitoringDetailScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Monitoring #$id')));
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Profile')));
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Notifications')));
}
