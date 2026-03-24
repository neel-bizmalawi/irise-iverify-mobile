import 'package:flutter/material.dart';

class SyncBadge extends StatefulWidget {
  final bool synced;
  final bool isSyncing;
  final VoidCallback? onSyncTap;
  
  const SyncBadge({
    super.key,
    required this.synced,
    this.isSyncing = false,
    this.onSyncTap,
  });

  @override
  State<SyncBadge> createState() => _SyncBadgeState();
}

class _SyncBadgeState extends State<SyncBadge> with SingleTickerProviderStateMixin {
  late AnimationController _celebrationController;
  late Animation<double> _scaleAnimation;
  bool _previousSyncedState = false;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));
    _previousSyncedState = widget.synced;
  }

  @override
  void didUpdateWidget(SyncBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_previousSyncedState && widget.synced && !widget.isSyncing) {
      _celebrationController.forward().then((_) {
        _celebrationController.reverse();
      });
    }
    _previousSyncedState = widget.synced;
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    String text;
    IconData icon;
    bool isClickable = false;

    if (widget.isSyncing) {
      backgroundColor = const Color(0xFF2196F3);
      text = 'SYNCING...';
      icon = Icons.sync;
    } else if (widget.synced) {
      backgroundColor = const Color(0xFF4CAF50);
      text = 'SYNCED';
      icon = Icons.check_circle_outline;
    } else {
      backgroundColor = const Color(0xFFFF9800);
      text = 'TAP TO SYNC';
      icon = Icons.sync;
      isClickable = true;
    }

    return GestureDetector(
      onTap: isClickable ? widget.onSyncTap : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.synced ? _scaleAnimation.value : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isClickable ? [
                  BoxShadow(
                    color: backgroundColor.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ] : widget.synced ? [
                  BoxShadow(
                    color: backgroundColor.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isSyncing)
                    const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 13,
                    ),
                  const SizedBox(width: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      text,
                      key: ValueKey(text),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
