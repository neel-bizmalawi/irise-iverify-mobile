import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isConnected = true;

  bool get isConnected => _isConnected;

  ConnectivityService() {
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      developer.log('Error checking connectivity: $e', name: 'ConnectivityService');
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final wasConnected = _isConnected;
    
    // Check if result indicates connectivity
    _isConnected = result != ConnectivityResult.none;
    
    if (wasConnected != _isConnected) {
      developer.log('Connectivity changed: ${_isConnected ? "Connected" : "Disconnected"}', name: 'ConnectivityService');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
