import 'package:flutter/material.dart';
import 'package:irise/data/services/sync_service.dart';
import 'dart:developer' as developer;

class SyncProvider extends ChangeNotifier {
  final SyncService _syncService = SyncService();
  
  bool _isSyncing = false;
  String? _lastSyncTime;
  String? _errorMessage;
  SyncStatus? _syncStatus;

  bool get isSyncing => _isSyncing;
  String? get lastSyncTime => _lastSyncTime;
  String? get errorMessage => _errorMessage;
  SyncStatus? get syncStatus => _syncStatus;
  bool get hasUnsyncedData => (_syncStatus?.totalUnsynced ?? 0) > 0;

  // Sync from server
  Future<bool> syncFromServer() async {
    if (_isSyncing) return false;

    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _syncService.syncFromServer();
      
      if (result.success) {
        _lastSyncTime = DateTime.now().toIso8601String();
        developer.log('Sync from server completed successfully', name: 'SyncProvider');
      } else {
        _errorMessage = result.error ?? 'Sync failed';
      }

      _isSyncing = false;
      await updateSyncStatus();
      notifyListeners();
      
      return result.success;
    } catch (e) {
      _errorMessage = 'Sync error: $e';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  // Sync to server
  Future<bool> syncToServer() async {
    if (_isSyncing) return false;

    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _syncService.syncToServer();
      
      if (result.success) {
        _lastSyncTime = DateTime.now().toIso8601String();
        developer.log('Sync to server completed successfully', name: 'SyncProvider');
      } else {
        _errorMessage = result.error ?? 'Sync failed';
      }

      _isSyncing = false;
      await updateSyncStatus();
      notifyListeners();
      
      return result.success;
    } catch (e) {
      _errorMessage = 'Sync error: $e';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  // Full bidirectional sync
  Future<bool> fullSync() async {
    if (_isSyncing) return false;

    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _syncService.fullSync();
      
      if (result.success) {
        _lastSyncTime = DateTime.now().toIso8601String();
        developer.log('Full sync completed successfully', name: 'SyncProvider');
      } else {
        _errorMessage = result.error ?? 'Sync failed';
      }

      _isSyncing = false;
      await updateSyncStatus();
      notifyListeners();
      
      return result.success;
    } catch (e) {
      _errorMessage = 'Sync error: $e';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  // Update sync status
  Future<void> updateSyncStatus() async {
    try {
      _syncStatus = await _syncService.getSyncStatus();
      notifyListeners();
    } catch (e) {
      developer.log('Error updating sync status: $e', name: 'SyncProvider');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
