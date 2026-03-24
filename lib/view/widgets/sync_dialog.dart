import 'package:flutter/material.dart';

class SyncDialog extends StatefulWidget {
  final String title;
  final Future<void> Function() onSyncPressed;
  final VoidCallback? onCancelPressed;
  final Stream<String>? progressStream;

  const SyncDialog({
    super.key,
    required this.title,
    required this.onSyncPressed,
    this.onCancelPressed,
    this.progressStream,
  });

  @override
  State<SyncDialog> createState() => _SyncDialogState();
}

class _SyncDialogState extends State<SyncDialog>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isCompleted = false;
  String _progressText = '';
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Listen to progress stream if provided
    widget.progressStream?.listen((progress) {
      if (mounted) {
        setState(() {
          _progressText = progress;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startSync() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Call the actual sync function
      await widget.onSyncPressed();
      
      setState(() {
        _isLoading = false;
        _isCompleted = true;
      });

      // Start success animation
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.close,
                    color: Colors.black54,
                    size: 20,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 4),

            if (_isLoading) ...[
              // Loading State
              _buildLoadingState(),
            ] else if (_isCompleted) ...[
              // Success State
              _buildSuccessState(),
            ] else ...[
              // Initial State
              _buildInitialState(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Column(
      children: [
        // Download icon with green background
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.download_rounded,
            color: Color(0xFF4CAF50),
            size: 24,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Title
        const Text(
          'New Data Available!',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Description
        Text(
          'New ${widget.title.toLowerCase()} data is available to sync.\nWould you like to sync now to keep your\nrecords up to date?',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
            height: 1.3,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Sync Now button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: _startSync,
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text(
              'Sync Now',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ),
        
        const SizedBox(height: 10),
        
        // Cancel button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            onPressed: widget.onCancelPressed ?? () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF4CAF50)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        // Loading spinner
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Loading text
        const Text(
          'Syncing Data...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          _progressText.isNotEmpty 
              ? _progressText 
              : 'Please wait while we download the latest\n${widget.title.toLowerCase()} data.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
            height: 1.3,
          ),
        ),
        
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        // Success icon with animation
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Success title
        const Text(
          'Your data has been downloaded\nsuccessfully.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            height: 1.3,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Back button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF4CAF50)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Back',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Helper function to show the sync dialog
void showSyncDialog(
  BuildContext context, {
  required String title,
  required Future<void> Function() onSync,
  VoidCallback? onCancel,
  Stream<String>? progressStream,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => SyncDialog(
      title: title,
      onSyncPressed: onSync,
      onCancelPressed: onCancel,
      progressStream: progressStream,
    ),
  );
}