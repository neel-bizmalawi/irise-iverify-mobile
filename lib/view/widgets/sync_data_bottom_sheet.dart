import 'package:flutter/material.dart';

enum SyncStatus {
  checking,
  available,
  downloading,
  completed,
  upToDate,
  error,
}

class SyncDataBottomSheet extends StatefulWidget {
  final String moduleName;
  final Future<SyncCheckResult> Function() onCheckForData;
  final Future<bool> Function(Function(int existing, int downloaded, int remaining) onProgress)? onDownload;

  const SyncDataBottomSheet({
    super.key,
    required this.moduleName,
    required this.onCheckForData,
    this.onDownload,
  });

  @override
  State<SyncDataBottomSheet> createState() => _SyncDataBottomSheetState();
}

class _SyncDataBottomSheetState extends State<SyncDataBottomSheet>
    with SingleTickerProviderStateMixin {
  SyncStatus _status = SyncStatus.checking;
  String _message = '';
  int _newRecordsCount = 0;
  
  // Download progress tracking
  int _existingRecords = 0;
  int _downloadedRecords = 0;
  int _remainingRecords = 0;
  double _downloadProgress = 0.0;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _checkForNewData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkForNewData() async {
    setState(() {
      _status = SyncStatus.checking;
      _message = 'Checking for new data...';
    });

    try {
      final result = await widget.onCheckForData();
      
      if (!mounted) return;
      
      setState(() {
        if (result.hasNewData) {
          _status = SyncStatus.available;
          _newRecordsCount = result.newRecordsCount;
          _existingRecords = result.existingRecords;
          _remainingRecords = result.newRecordsCount;
          _message = result.message ?? 'New data available!';
        } else {
          _status = SyncStatus.upToDate;
          _message = result.message ?? 'You\'re up to date!';
        }
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _status = SyncStatus.error;
        _message = 'Failed to check for new data: $e';
      });
    }
  }

  Future<void> _handleDownload() async {
    if (widget.onDownload == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _status = SyncStatus.downloading;
      _message = 'Downloading data...';
      _downloadProgress = 0.0;
    });

    try {
      final success = await widget.onDownload!((existing, downloaded, remaining) {
        if (!mounted) return;
        
        setState(() {
          _existingRecords = existing;
          _downloadedRecords = downloaded;
          _remainingRecords = remaining;
          
          final total = existing + downloaded + remaining;
          if (total > 0) {
            _downloadProgress = (existing + downloaded) / total;
          }
        });
      });
      
      if (!mounted) return;
      
      if (success) {
        // Show finalizing state briefly
        setState(() {
          _message = 'Finalizing data sync...';
          _downloadProgress = 1.0;
        });
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (!mounted) return;
        
        // Show success state
        setState(() {
          _status = SyncStatus.completed;
          _message = 'All data Downloaded Successfully!';
        });
      } else {
        setState(() {
          _status = SyncStatus.error;
          _message = 'Download failed. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _status = SyncStatus.error;
        _message = 'Download error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Syncing New Data...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (_status != SyncStatus.downloading)
                    IconButton(
                      onPressed: () {
                        // Return true if sync was completed successfully, false otherwise
                        final shouldReturnTrue = _status == SyncStatus.completed;
                        Navigator.of(context).pop(shouldReturnTrue);
                      },
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Content based on status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildContent(),
            ),

            const SizedBox(height: 24),

            // Action buttons with extra bottom padding for navigation bar
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                0,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24, // Add extra padding for keyboard/nav bar
              ),
              child: _buildActionButtons(),
            ),
            
            // Additional safe area padding at the bottom
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_status) {
      case SyncStatus.checking:
        return Column(
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4CAF50),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we check the server...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        );

      case SyncStatus.downloading:
        return Column(
          children: [
            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _downloadProgress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DownloadStatCard(
                  icon: Icons.storage_rounded,
                  label: 'Existing',
                  count: _existingRecords,
                  color: const Color(0xFF4CAF50),
                ),
                _DownloadStatCard(
                  icon: Icons.download_rounded,
                  label: 'Downloading',
                  count: _downloadedRecords,
                  color: const Color(0xFF2196F3),
                ),
                _DownloadStatCard(
                  icon: Icons.access_time,
                  label: 'Remaining',
                  count: _remainingRecords,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ],
        );

      case SyncStatus.available:
        return Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.download_rounded,
                  size: 40,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'New Data Available!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            if (_newRecordsCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '$_newRecordsCount new ${widget.moduleName.toLowerCase()} records',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        );

      case SyncStatus.completed:
        return Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'All data Downloaded\nSuccessfully!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ],
        );

      case SyncStatus.upToDate:
        return Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 40,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'You\'re Up to Date!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        );

      case SyncStatus.error:
        return Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sync Error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildActionButtons() {
    switch (_status) {
      case SyncStatus.checking:
      case SyncStatus.downloading:
        return const SizedBox.shrink();

      case SyncStatus.available:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleDownload,
                icon: const Icon(Icons.download_rounded, size: 20),
                label: const Text(
                  'Download',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4CAF50),
                  side: const BorderSide(color: Color(0xFF4CAF50)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );

      case SyncStatus.completed:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4CAF50),
              side: const BorderSide(color: Color(0xFF4CAF50)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Back',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );

      case SyncStatus.upToDate:
      case SyncStatus.error:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: ElevatedButton.styleFrom(
              backgroundColor: _status == SyncStatus.error
                  ? Colors.grey.shade400
                  : const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              _status == SyncStatus.error ? 'Close' : 'OK',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
    }
  }
}

// Download stat card widget
class _DownloadStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _DownloadStatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 28,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Result class for sync check
class SyncCheckResult {
  final bool hasNewData;
  final int newRecordsCount;
  final int existingRecords;
  final String? message;

  SyncCheckResult({
    required this.hasNewData,
    this.newRecordsCount = 0,
    this.existingRecords = 0,
    this.message,
  });
}

// Helper function to show the bottom sheet
Future<bool?> showSyncDataBottomSheet({
  required BuildContext context,
  required String moduleName,
  required Future<SyncCheckResult> Function() onCheckForData,
  Future<bool> Function(Function(int existing, int downloaded, int remaining) onProgress)? onDownload,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    useSafeArea: true, // Changed to true for better safe area handling
    builder: (context) => SyncDataBottomSheet(
      moduleName: moduleName,
      onCheckForData: onCheckForData,
      onDownload: onDownload,
    ),
  );
}
