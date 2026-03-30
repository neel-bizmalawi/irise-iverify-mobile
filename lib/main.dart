import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irise/providers/auth_provider.dart';
import 'package:irise/providers/sync_provider.dart';
import 'package:irise/providers/dashboard_provider.dart';
import 'package:irise/core/services/connectivity_service.dart';
import 'package:irise/view/widgets/connectivity_banner.dart';
import 'package:irise/route/app_router.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = createRouter(_authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            title: 'Ecook Stove',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4CAF50)),
              useMaterial3: true,
              fontFamily: 'Roboto',
              // Set cursor color to white globally
              textSelectionTheme: const TextSelectionThemeData(
                cursorColor: Colors.white,
                selectionColor: Colors.white24,
                selectionHandleColor: Colors.white,
              ),
            ),
            routerConfig: _router,
            // builder: (context, child) {
            //   return
            //     child: child ?? const SizedBox.shrink(),
            
            // },
          );
        },
      ),
    );
  }
}