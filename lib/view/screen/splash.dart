import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:irise/providers/auth_provider.dart';
import 'package:irise/route/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _topLeftController;
  late AnimationController _bottomRightController;
  late AnimationController _logoController;

  late Animation<double> _topLeftOpacity;
  late Animation<Offset> _topLeftSlide;

  late Animation<double> _bottomRightOpacity;
  late Animation<Offset> _bottomRightSlide;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // Top-left rectangle animation
    _topLeftController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _topLeftOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _topLeftController, curve: Curves.easeOut),
    );
    _topLeftSlide = Tween<Offset>(
      begin: const Offset(-0.3, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _topLeftController, curve: Curves.easeOutCubic),
    );

    // Bottom-right rectangle animation
    _bottomRightController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bottomRightOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bottomRightController, curve: Curves.easeOut),
    );
    _bottomRightSlide = Tween<Offset>(
      begin: const Offset(0.3, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
          parent: _bottomRightController, curve: Curves.easeOutCubic),
    );

    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    // Start animations and navigation in sequence
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimationsAndNavigate();
    });
  }

  void _startAnimationsAndNavigate() async {
    if (!mounted) return;
    
    // Start animations
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) _topLeftController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) _bottomRightController.forward();

    // Logo appears after 1 second
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _logoController.forward();
    
    // Wait a bit more then navigate
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (!mounted || _hasNavigated) return;
    
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted || _hasNavigated) {
      print('Splash: Skipping navigation - mounted: $mounted, hasNavigated: $_hasNavigated');
      return;
    }

    _hasNavigated = true; // Set this immediately to prevent multiple calls
    
    try {
      print('Splash: Starting auth check...');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Check authentication status
      await authProvider.checkAuthStatus();
      
      if (!mounted) return;
      
      print('Splash: Auth status checked, isAuthenticated: ${authProvider.isAuthenticated}');
      
      // Navigate based on auth status
      if (authProvider.isAuthenticated) {
        print('Splash: Navigating to dashboard');
        context.go(AppRoutes.dashboard);
      } else {
        print('Splash: Navigating to login');
        context.go(AppRoutes.login);
      }
    } catch (e) {
      print('Splash: Error during auth check: $e');
      if (!mounted) return;
      
      // On error, navigate to login screen
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _topLeftController.dispose();
    _bottomRightController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Color.fromARGB(255, 30, 115, 31), // Base bright green
        child: Stack(
          children: [
            // Diagonal dark overlay with gradient line
            Positioned.fill(
              child: CustomPaint(
                painter: _DiagonalGradientPainter(),
              ),
            ),
            // Animated geometric shapes
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _topLeftController,
                  _bottomRightController,
                ]),
                builder: (context, child) {
                  return CustomPaint(
                    painter: _GlassPanelPainter(
                      topLeftOpacity: _topLeftOpacity.value,
                      topLeftOffset: _topLeftSlide.value,
                      bottomRightOpacity: _bottomRightOpacity.value,
                      bottomRightOffset: _bottomRightSlide.value,
                    ),
                  );
                },
              ),
            ),
            // Animated logo (appears after delay)
            Center(
              child: AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Image.asset(
                        'assets/splash/image 2.png',
                        width: 110,
                        height: 150,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Version text
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoOpacity.value,
                    child: const Text(
                      'iVerify 2025 | v2.0.0',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.8,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DiagonalGradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw a gradient stripe along the diagonal line from top-right to bottom-left
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color.fromARGB(255, 25, 107, 31), // Bright green (top-right)
          Color.fromARGB(255, 29, 85, 32), // Medium-bright green
          Color.fromARGB(255, 37, 74, 39), // Medium green
          Color.fromARGB(255, 29, 85, 32),
          Color.fromARGB(255, 21, 91, 27), // Very dark green (bottom-left)
        ],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.8 // Wide stripe along diagonal
      ..strokeCap = StrokeCap.round // Circular ends
      ..maskFilter =
          const MaskFilter.blur(BlurStyle.normal, 80); // Soft blur effect

    // Draw the diagonal line from top-right to bottom-left
    canvas.drawLine(
      Offset(size.width, 0), // Top-right
      Offset(0, size.height), // Bottom-left
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlassPanelPainter extends CustomPainter {
  final double topLeftOpacity;
  final Offset topLeftOffset;
  final double bottomRightOpacity;
  final Offset bottomRightOffset;

  _GlassPanelPainter({
    this.topLeftOpacity = 1.0,
    this.topLeftOffset = Offset.zero,
    this.bottomRightOpacity = 1.0,
    this.bottomRightOffset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Top-left rounded rectangle
    canvas.save();
    canvas.translate(
      topLeftOffset.dx * size.width,
      topLeftOffset.dy * size.height,
    );

    final paint1 = Paint()
      ..color = Colors.white.withOpacity(0.05 * topLeftOpacity)
      ..style = PaintingStyle.fill;

    final rect1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        -size.width * 0.35,
        -size.height * 0.25,
        size.width * 0.75,
        size.height * 0.55,
      ),
      const Radius.circular(50),
    );
    canvas.drawRRect(rect1, paint1);
    canvas.restore();

    // Bottom-right rounded rectangle
    canvas.save();
    canvas.translate(
      bottomRightOffset.dx * size.width,
      bottomRightOffset.dy * size.height,
    );

    final paint2 = Paint()
      ..color = Colors.white.withOpacity(0.05 * bottomRightOpacity)
      ..style = PaintingStyle.fill;

    final rect2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.25,
        size.height * 0.68,
        size.width * 0.85,
        size.height * 0.45,
      ),
      const Radius.circular(50),
    );
    canvas.drawRRect(rect2, paint2);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
