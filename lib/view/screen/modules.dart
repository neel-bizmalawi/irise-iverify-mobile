import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irise/route/app_routes.dart';

class ModulesScreen extends StatelessWidget {
  const ModulesScreen({super.key});

  final List<Map<String, dynamic>> _modules = const [
    {
      'title': 'Training Point Identification',
      'icon': Icons.location_on_outlined,
    },
    {
      'title': 'Conduct Training',
      'icon': Icons.assignment_outlined,
    },
    {
      'title': 'Beneficiary',
      'icon': Icons.person_add_outlined,
    },
    {
      'title': 'House Hold Distribution',
      'icon': Icons.home_outlined,
    },
    {
      'title': 'Monitoring',
      'icon': Icons.monitor_outlined,
    },
    {
      'title': 'Audit Process',
      'icon': Icons.people_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4EA),
      body: Stack(
        children: [
          // ── Green quarter-circle top-right ──
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 90,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(90),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top bar ──
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios,
                            color: Colors.black87, size: 20),
                      ),
                      // Title centered
                      const Expanded(
                        child: Text(
                          'Modules',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      // Help icon over green circle
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5), width: 1),
                        ),
                        child: const Icon(Icons.question_mark_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Module List ──
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _modules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final module = _modules[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: _ModuleTile(
                          title: module['title'],
                          icon: module['icon'],
                          onTap: () => _navigateTo(context, index),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.push(AppRoutes.training_point_identification);
        break;
      case 1:
        context.push(AppRoutes.conduct_training_list);
        break;
      case 2:
        context.push(AppRoutes.beneficiary);
        break;
      case 3:
        // context.push(AppRoutes.houseHoldDistribution);
        break;
      case 4:
        context.push(AppRoutes.monitoring);
        break;
      case 5:
        // context.push(AppRoutes.audit_process);
        break;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ModuleTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Green icon box
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF4CAF50),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Title
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
