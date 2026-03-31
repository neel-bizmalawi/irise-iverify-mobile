import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/connectivity_service.dart';
import 'dart:developer' as developer;

/// A network image widget that automatically retries loading when connectivity is restored
class NetworkImageWithRetry extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const NetworkImageWithRetry({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<NetworkImageWithRetry> createState() => _NetworkImageWithRetryState();
}

class _NetworkImageWithRetryState extends State<NetworkImageWithRetry> {
  int _retryCount = 0;
  bool _hasError = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Listen to connectivity changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final connectivityService = context.read<ConnectivityService>();
        connectivityService.addListener(_onConnectivityChanged);
      }
    });
  }

  @override
  void dispose() {
    // Remove listener before disposing
    if (mounted) {
      try {
        final connectivityService = context.read<ConnectivityService>();
        connectivityService.removeListener(_onConnectivityChanged);
      } catch (e) {
        developer.log('Error removing connectivity listener: $e', name: 'NetworkImageWithRetry');
      }
    }
    super.dispose();
  }

  void _onConnectivityChanged() {
    // Check if widget is still mounted before accessing context
    if (!mounted) return;
    
    final connectivityService = context.read<ConnectivityService>();
    
    // If we had an error and now we're connected, retry loading
    if (_hasError && connectivityService.isConnected) {
      developer.log('Connectivity restored, retrying image load: ${widget.imageUrl}', name: 'NetworkImageWithRetry');
      setState(() {
        _retryCount++;
        _hasError = false;
        _isLoading = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use a unique key based on retry count to force image reload
    final imageKey = Key('${widget.imageUrl}_$_retryCount');
    
    return Image.network(
      widget.imageUrl,
      key: imageKey,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // Image loaded successfully
          if (_isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = false;
                });
              }
            });
          }
          return child;
        }
        
        // Show loading indicator
        return widget.placeholder ??
            Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        developer.log('Error loading image: $error', name: 'NetworkImageWithRetry');
        
        // Mark that we have an error
        if (!_hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _hasError = true;
                _isLoading = false;
              });
            }
          });
        }
        
        // Show error widget
        return widget.errorWidget ??
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Will retry when online',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            );
      },
    );
  }
}
