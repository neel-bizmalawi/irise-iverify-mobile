import 'package:flutter/material.dart';
import 'package:irise/data/repositories/training_site_repository.dart';
import 'package:irise/data/repositories/beneficiary_repository.dart';
import 'package:irise/data/repositories/training_repository.dart';
import 'package:irise/data/services/data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class DashboardProvider extends ChangeNotifier {
  final TrainingSiteRepository _trainingSiteRepository = TrainingSiteRepository();
  final BeneficiaryRepository _beneficiaryRepository = BeneficiaryRepository();
  final TrainingRepository _trainingRepository = TrainingRepository();
  final DataService _dataService = DataService();

  // Counts
  int _totalTrainingSites = 0;  // Total synced records only (s_is_sync = 1)
  int _unsyncedTrainingSites = 0;
  int _totalBeneficiaries = 0;
  int _unsyncedBeneficiaries = 0;
  int _totalTrainings = 0;
  int _unsyncedTrainings = 0;

  // Last sync timestamps
  DateTime? _lastTrainingSiteSync;
  DateTime? _lastBeneficiarySync;
  DateTime? _lastMonitoringSync;
  DateTime? _lastAuditSync;

  bool _isLoading = false;
  bool _isSyncing = false;

  // Getters
  int get totalTrainingSites => _totalTrainingSites;  // Returns synced count only
  int get unsyncedTrainingSites => _unsyncedTrainingSites;
  int get totalBeneficiaries => _totalBeneficiaries;
  int get unsyncedBeneficiaries => _unsyncedBeneficiaries;
  int get totalTrainings => _totalTrainings;
  int get unsyncedTrainings => _unsyncedTrainings;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;

  // Last sync time getters
  DateTime? get lastTrainingSiteSync => _lastTrainingSiteSync;
  DateTime? get lastBeneficiarySync => _lastBeneficiarySync;
  DateTime? get lastMonitoringSync => _lastMonitoringSync;
  DateTime? get lastAuditSync => _lastAuditSync;

  // For monitoring and audit (placeholder values since we don't have these tables yet)
  int get totalMonitoring => 233;
  int get unsyncedMonitoring => 22;
  int get totalAudit => 289;
  int get unsyncedAudit => 55;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load counts and sync times in parallel
      final results = await Future.wait([
        _trainingSiteRepository.getSyncedCount(),  // Total count = only synced records
        _trainingSiteRepository.getUnsyncedCount(),
        _beneficiaryRepository.getSyncedCount(),  // LOCAL SAVED = synced records only
        _beneficiaryRepository.getUnsyncedCount(),  // OFFLINE SAVED = unsynced records
        _trainingRepository.getCount(),
        _trainingRepository.getUnsyncedCount(),
      ]);

      // Load sync times separately
      await _loadLastSyncTimes();

      _totalTrainingSites = results[0];  // Total count = synced only
      _unsyncedTrainingSites = results[1];
      _totalBeneficiaries = results[2];
      _unsyncedBeneficiaries = results[3];
      _totalTrainings = results[4];
      _unsyncedTrainings = results[5];

      // IMPORTANT: Sync districts and authorities to local database on dashboard load
      // This ensures reference data is available for forms
      await _syncReferenceData();

      // Debug logging
      developer.log('Dashboard Data Loaded:', name: 'DashboardProvider');
      developer.log('Training Sites - Total (Synced): $_totalTrainingSites, Unsynced: $_unsyncedTrainingSites', name: 'DashboardProvider');
      developer.log('Beneficiaries - Total: $_totalBeneficiaries, Unsynced: $_unsyncedBeneficiaries', name: 'DashboardProvider');
      developer.log('Trainings - Total: $_totalTrainings, Unsynced: $_unsyncedTrainings', name: 'DashboardProvider');
      developer.log('Last Training Site Sync: $_lastTrainingSiteSync', name: 'DashboardProvider');
    } catch (e) {
      // Handle error - could show a snackbar or log
      developer.log('Error loading dashboard data: $e', name: 'DashboardProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sync reference data (districts and authorities) to local database
  /// This is called when dashboard loads to ensure forms have access to reference data
  Future<void> _syncReferenceData() async {
    try {
      developer.log('========================================', name: 'DashboardProvider');
      developer.log('Syncing reference data (districts & authorities)...', name: 'DashboardProvider');
      
      // Sync districts and authorities in parallel
      final results = await Future.wait([
        _dataService.syncDistrictsToLocal(),
        _dataService.syncAuthoritiesToLocal(),
      ]);
      
      final districtsResult = results[0];
      final authoritiesResult = results[1];
      
      if (districtsResult.success) {
        developer.log('✅ Synced ${districtsResult.data ?? 0} districts to local database', name: 'DashboardProvider');
      } else {
        developer.log('⚠️ Failed to sync districts: ${districtsResult.message}', name: 'DashboardProvider');
      }
      
      if (authoritiesResult.success) {
        developer.log('✅ Synced ${authoritiesResult.data ?? 0} authorities to local database', name: 'DashboardProvider');
      } else {
        developer.log('⚠️ Failed to sync authorities: ${authoritiesResult.message}', name: 'DashboardProvider');
      }
      
      developer.log('========================================', name: 'DashboardProvider');
    } catch (e) {
      developer.log('Error syncing reference data: $e', name: 'DashboardProvider');
      // Don't fail the entire dashboard load if reference data sync fails
    }
  }

  // Load last sync times from SharedPreferences
  Future<void> _loadLastSyncTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final trainingSiteTimestamp = prefs.getString('last_training_site_sync');
      final beneficiaryTimestamp = prefs.getString('last_beneficiary_sync');
      final monitoringTimestamp = prefs.getString('last_monitoring_sync');
      final auditTimestamp = prefs.getString('last_audit_sync');
      
      _lastTrainingSiteSync = trainingSiteTimestamp != null 
          ? DateTime.parse(trainingSiteTimestamp) 
          : null;
      _lastBeneficiarySync = beneficiaryTimestamp != null 
          ? DateTime.parse(beneficiaryTimestamp) 
          : null;
      _lastMonitoringSync = monitoringTimestamp != null 
          ? DateTime.parse(monitoringTimestamp) 
          : null;
      _lastAuditSync = auditTimestamp != null 
          ? DateTime.parse(auditTimestamp) 
          : null;
          
      developer.log('Loaded sync times from preferences', name: 'DashboardProvider');
    } catch (e) {
      developer.log('Error loading sync times: $e', name: 'DashboardProvider');
    }
  }

  // Save last sync time for a specific module
  Future<void> _saveLastSyncTime(String moduleType, DateTime syncTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_${moduleType}_sync', syncTime.toIso8601String());
      
      // Update local state
      switch (moduleType) {
        case 'training_site':
          _lastTrainingSiteSync = syncTime;
          break;
        case 'beneficiary':
          _lastBeneficiarySync = syncTime;
          break;
        case 'monitoring':
          _lastMonitoringSync = syncTime;
          break;
        case 'audit':
          _lastAuditSync = syncTime;
          break;
      }
      
      developer.log('Saved $moduleType sync time: $syncTime', name: 'DashboardProvider');
      notifyListeners();
    } catch (e) {
      developer.log('Error saving sync time for $moduleType: $e', name: 'DashboardProvider');
    }
  }

  // Public method to save training sync time (called from UI)
  Future<void> saveTrainingSyncTime() async {
    await _saveLastSyncTime('training_site', DateTime.now());
  }

  // Refresh data (can be called after sync operations)
  Future<void> refreshData() async {
    developer.log('Refreshing dashboard data...', name: 'DashboardProvider');
    await loadDashboardData();
  }

  // Check if initial sync has been completed
  Future<bool> isInitialSyncCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('initial_sync_completed') ?? false;
    } catch (e) {
      developer.log('Error checking initial sync status: $e', name: 'DashboardProvider');
      return false;
    }
  }

  // Mark initial sync as completed
  Future<void> markInitialSyncCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('initial_sync_completed', true);
      developer.log('Marked initial sync as completed', name: 'DashboardProvider');
    } catch (e) {
      developer.log('Error marking initial sync completed: $e', name: 'DashboardProvider');
    }
  }

  // Perform initial full sync using getAllTrainingSitesPaginated
  Future<SyncResult> performInitialSync({
    Function(String status, int current, int total)? onProgress,
  }) async {
    _isSyncing = true;
    notifyListeners();

    try {
      developer.log('========================================', name: 'DashboardProvider');
      developer.log('STARTING INITIAL FULL SYNC', name: 'DashboardProvider');
      developer.log('========================================', name: 'DashboardProvider');
      
      onProgress?.call('Starting initial sync...', 0, 0);
      
      // Fetch all training sites from server
      final response = await _dataService.getAllTrainingSitesPaginated(
        limit: 100,
        onProgress: (currentRecords, totalRecords) {
          // Report progress with actual record counts
          onProgress?.call('Downloading records...', currentRecords, totalRecords);
        },
        storeInDatabase: true,
      );
      
      if (response.success && response.data != null) {
        final recordsProcessed = response.data!.length;
        
        developer.log('========================================', name: 'DashboardProvider');
        developer.log('INITIAL SYNC COMPLETED', name: 'DashboardProvider');
        developer.log('========================================', name: 'DashboardProvider');
        developer.log('✅ Successfully synced $recordsProcessed training sites', name: 'DashboardProvider');
        
        // Mark initial sync as completed
        await markInitialSyncCompleted();
        
        // Save sync time
        await _saveLastSyncTime('training_site', DateTime.now());
        
        // Reset page counter for future paginated syncs
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('training_sites_current_page', 1);
        
        // Refresh dashboard data
        await loadDashboardData();
        
        onProgress?.call('Initial sync completed', recordsProcessed, recordsProcessed);
        
        return SyncResult(
          success: true,
          recordsProcessed: recordsProcessed,
          message: 'Initial sync completed successfully! Synced $recordsProcessed training sites.',
        );
      } else {
        developer.log('========================================', name: 'DashboardProvider');
        developer.log('INITIAL SYNC FAILED', name: 'DashboardProvider');
        developer.log('========================================', name: 'DashboardProvider');
        developer.log('Error: ${response.message}', name: 'DashboardProvider');
        
        return SyncResult(
          success: false,
          message: response.message ?? 'Failed to perform initial sync',
        );
      }
    } catch (e) {
      developer.log('========================================', name: 'DashboardProvider');
      developer.log('INITIAL SYNC EXCEPTION', name: 'DashboardProvider');
      developer.log('========================================', name: 'DashboardProvider');
      developer.log('Error: $e', name: 'DashboardProvider');
      
      return SyncResult(
        success: false,
        message: 'Error during initial sync: $e',
      );
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Perform incremental sync using update_data API
  Future<SyncResult> performIncrementalSync({
    Function(String status, int current, int total)? onProgress,
  }) async {
    _isSyncing = true;
    notifyListeners();

    try {
      developer.log('========================================', name: 'DashboardProvider');
      developer.log('STARTING INCREMENTAL SYNC', name: 'DashboardProvider');
      developer.log('========================================', name: 'DashboardProvider');
      
      // Get last sync time
      if (_lastTrainingSiteSync == null) {
        developer.log('No last sync time found, falling back to initial sync', name: 'DashboardProvider');
        return await performInitialSync(onProgress: onProgress);
      }
      
      // Capture the current time BEFORE making the API call
      // This will be our new sync timestamp if the sync succeeds
      final newSyncTime = DateTime.now();
      
      // Format last sync date for API in ISO 8601 format (UTC)
      // Example: 2026-03-20T04:30:00.000Z
      final lastSyncDate = _lastTrainingSiteSync!.toUtc().toIso8601String();
      
      developer.log('Last sync date (ISO 8601): $lastSyncDate', name: 'DashboardProvider');
      developer.log('New sync time will be: ${newSyncTime.toUtc().toIso8601String()}', name: 'DashboardProvider');
      onProgress?.call('Checking for updates since $lastSyncDate...', 0, 0);
      
      // Fetch updated training sites
      final response = await _dataService.syncUpdatedTrainingSites(lastSyncDate);
      
      if (response.success) {
        final recordsProcessed = response.data ?? 0;
        
        developer.log('========================================', name: 'DashboardProvider');
        developer.log('INCREMENTAL SYNC COMPLETED', name: 'DashboardProvider');
        developer.log('========================================', name: 'DashboardProvider');
        developer.log('✅ Successfully synced $recordsProcessed updated training sites', name: 'DashboardProvider');
        
        // Save the sync time that was captured BEFORE the API call
        // This ensures we don't miss any records that were modified during the sync
        await _saveLastSyncTime('training_site', newSyncTime);
        
        // Refresh dashboard data
        await loadDashboardData();
        
        // Report actual progress: downloaded records out of total records
        onProgress?.call('Incremental sync completed', recordsProcessed, recordsProcessed);
        
        return SyncResult(
          success: true,
          recordsProcessed: recordsProcessed,
          message: recordsProcessed > 0 
              ? 'Synced $recordsProcessed updated training sites'
              : 'All data is up to date',
        );
      } else {
        developer.log('========================================', name: 'DashboardProvider');
        developer.log('INCREMENTAL SYNC FAILED', name: 'DashboardProvider');
        developer.log('========================================', name: 'DashboardProvider');
        developer.log('Error: ${response.message}', name: 'DashboardProvider');
        
        return SyncResult(
          success: false,
          message: response.message ?? 'Failed to perform incremental sync',
        );
      }
    } catch (e) {
      developer.log('========================================', name: 'DashboardProvider');
      developer.log('INCREMENTAL SYNC EXCEPTION', name: 'DashboardProvider');
      developer.log('========================================', name: 'DashboardProvider');
      developer.log('Error: $e', name: 'DashboardProvider');
      
      return SyncResult(
        success: false,
        message: 'Error during incremental sync: $e',
      );
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Sync training sites from server
  // This method intelligently chooses between initial and incremental sync based on last sync date
  Future<SyncResult> syncTrainingSites({
    Function(String status, int current, int total)? onProgress,
  }) async {
    try {
      // Check if we have a last sync timestamp
      // If no last sync time exists, perform initial sync
      // If last sync time exists, perform incremental sync
      
      if (_lastTrainingSiteSync == null) {
        developer.log('No last sync time found, performing initial full sync...', name: 'DashboardProvider');
        return await performInitialSync(onProgress: onProgress);
      } else {
        developer.log('Last sync time found: $_lastTrainingSiteSync, performing incremental sync...', name: 'DashboardProvider');
        return await performIncrementalSync(onProgress: onProgress);
      }
    } catch (e) {
      developer.log('Error in syncTrainingSites: $e', name: 'DashboardProvider');
      return SyncResult(
        success: false,
        message: 'Error syncing training sites: $e',
      );
    }
  }

  // Legacy method - kept for backward compatibility but now uses the new sync logic
  Future<SyncResult> syncTrainingSitesLegacy({
    Function(String status, int current, int total)? onProgress,
  }) async {
    _isSyncing = true;
    notifyListeners();

    try {
      developer.log('========================================', name: 'DashboardProvider');
      developer.log('Starting training sites sync...', name: 'DashboardProvider');
      developer.log('========================================', name: 'DashboardProvider');
      
      // Get the current page from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      int currentPage = prefs.getInt('training_sites_current_page') ?? 1;
      
      developer.log('📄 Fetching page: $currentPage', name: 'DashboardProvider');
      developer.log('📊 Limit per page: 100', name: 'DashboardProvider');
      
      // Fetch the next page with limit 100
      final result = await _dataService.getTrainingSetPaginated(
        page: currentPage,
        limit: 100,
      );

      // Print detailed response
      developer.log('========================================', name: 'DashboardProvider');
      developer.log('📥 API RESPONSE:', name: 'DashboardProvider');
      developer.log('========================================', name: 'DashboardProvider');
      developer.log('✅ Success: ${result.success}', name: 'DashboardProvider');
      developer.log('📝 Message: ${result.message}', name: 'DashboardProvider');
      
      if (result.success && result.data != null) {
        final paginatedData = result.data!;
        final recordsProcessed = paginatedData.data.length;
        
        developer.log('========================================', name: 'DashboardProvider');
        developer.log('📊 PAGINATION INFO:', name: 'DashboardProvider');
        developer.log('========================================', name: 'DashboardProvider');
        developer.log('📄 Current Page: ${paginatedData.currentPage}', name: 'DashboardProvider');
        developer.log('📄 Total Pages: ${paginatedData.totalPages}', name: 'DashboardProvider');
        developer.log('📦 Records in this page: $recordsProcessed', name: 'DashboardProvider');
        developer.log('📊 Total Records on server: ${paginatedData.totalRecords}', name: 'DashboardProvider');
        developer.log('📏 Limit: ${paginatedData.limit}', name: 'DashboardProvider');
        
        // Print sample records (first 3)
        if (paginatedData.data.isNotEmpty) {
          developer.log('========================================', name: 'DashboardProvider');
          developer.log('📋 SAMPLE RECORDS (first 3):', name: 'DashboardProvider');
          developer.log('========================================', name: 'DashboardProvider');
          
          final sampleCount = paginatedData.data.length > 3 ? 3 : paginatedData.data.length;
          for (int i = 0; i < sampleCount; i++) {
            final site = paginatedData.data[i];
            developer.log('Record ${i + 1}:', name: 'DashboardProvider');
            developer.log('  - ID: ${site.trainingPointId}', name: 'DashboardProvider');
            developer.log('  - Name: ${site.trainingSite}', name: 'DashboardProvider');
            developer.log('  - District: ${site.district}', name: 'DashboardProvider');
            developer.log('  - Authority: ${site.traditionalAuthority}', name: 'DashboardProvider');
            developer.log('  - Latitude: ${site.latitude}', name: 'DashboardProvider');
            developer.log('  - Longitude: ${site.longitude}', name: 'DashboardProvider');
            developer.log('  - Households: ${site.houseHoldsCount}', name: 'DashboardProvider');
            developer.log('  - Total People: ${site.totalPeople}', name: 'DashboardProvider');
            developer.log('  - Cookstoves: ${site.cookstovesCount}', name: 'DashboardProvider');
            developer.log('  ---', name: 'DashboardProvider');
          }
        }
        
        // Store the fetched data in local database
        if (paginatedData.data.isNotEmpty) {
          try {
            developer.log('========================================', name: 'DashboardProvider');
            developer.log('💾 STORING TO DATABASE:', name: 'DashboardProvider');
            developer.log('========================================', name: 'DashboardProvider');
            
            // Mark all fetched records as synced (s_is_sync = 1)
            final syncedRecords = paginatedData.data.map((site) {
              return site.copyWith(sIsSync: 1);
            }).toList();
            
            developer.log('📝 Marking $recordsProcessed records as synced (s_is_sync = 1)', name: 'DashboardProvider');
            
            await _trainingSiteRepository.insertBulk(syncedRecords);
            
            developer.log('✅ Successfully stored $recordsProcessed training sites in local database', name: 'DashboardProvider');
          } catch (e) {
            developer.log('❌ Error storing training sites: $e', name: 'DashboardProvider');
          }
        }
        
        // Check if all pages are fetched
        bool isComplete = paginatedData.currentPage >= paginatedData.totalPages;
        
        developer.log('========================================', name: 'DashboardProvider');
        developer.log('📊 SYNC STATUS:', name: 'DashboardProvider');
        developer.log('========================================', name: 'DashboardProvider');
        developer.log('🔄 Is Complete: $isComplete', name: 'DashboardProvider');
        developer.log('📄 Current Page: ${paginatedData.currentPage}', name: 'DashboardProvider');
        developer.log('📄 Total Pages: ${paginatedData.totalPages}', name: 'DashboardProvider');
        
        // Save last sync time after every successful fetch
        await _saveLastSyncTime('training_site', DateTime.now());
        
        if (isComplete) {
          // All pages fetched - reset to page 1 for next sync cycle
          await prefs.setInt('training_sites_current_page', 1);
          
          developer.log('========================================', name: 'DashboardProvider');
          developer.log('🎉 SYNC COMPLETE!', name: 'DashboardProvider');
          developer.log('========================================', name: 'DashboardProvider');
          developer.log('✅ All pages fetched successfully', name: 'DashboardProvider');
          developer.log('🔄 Reset page counter to 1 for next sync', name: 'DashboardProvider');
          
          // Refresh dashboard data
          await loadDashboardData();
          
          return SyncResult(
            success: true,
            recordsProcessed: recordsProcessed,
            message: 'Successfully synced $recordsProcessed records. All data is up to date!',
          );
        } else {
          // More pages pending - increment page number
          await prefs.setInt('training_sites_current_page', currentPage + 1);
          
          developer.log('========================================', name: 'DashboardProvider');
          developer.log('⏭️  MORE PAGES PENDING', name: 'DashboardProvider');
          developer.log('========================================', name: 'DashboardProvider');
          developer.log('📄 Next page will be: ${currentPage + 1}', name: 'DashboardProvider');
          developer.log('📊 Remaining pages: ${paginatedData.totalPages - currentPage}', name: 'DashboardProvider');
          
          // Refresh dashboard data
          await loadDashboardData();
          
          return SyncResult(
            success: true,
            recordsProcessed: recordsProcessed,
            message: 'Fetched $recordsProcessed records (Page ${paginatedData.currentPage}/${paginatedData.totalPages}). Records are still pending on the server.',
          );
        }
      } else {
        developer.log('========================================', name: 'DashboardProvider');
        developer.log('❌ SYNC FAILED', name: 'DashboardProvider');
        developer.log('========================================', name: 'DashboardProvider');
        developer.log('Error: ${result.message}', name: 'DashboardProvider');
        
        return SyncResult(
          success: false,
          message: result.message ?? 'Failed to sync training sites',
        );
      }
    } catch (e) {
      developer.log('========================================', name: 'DashboardProvider');
      developer.log('❌ EXCEPTION OCCURRED', name: 'DashboardProvider');
      developer.log('========================================', name: 'DashboardProvider');
      developer.log('Error: $e', name: 'DashboardProvider');
      developer.log('Stack trace: ${StackTrace.current}', name: 'DashboardProvider');
      
      // Check if it's a database schema issue
      if (e.toString().contains('has no column named')) {
        developer.log('⚠️  Database schema issue detected, attempting to fix...', name: 'DashboardProvider');
        
        try {
          // Try to update the database schema
          final schemaResult = await _dataService.updateDatabaseSchema();
          if (schemaResult.success) {
            return SyncResult(
              success: false,
              message: 'Database schema updated. Please try syncing again.',
            );
          } else {
            return SyncResult(
              success: false,
              message: 'Database schema issue detected. Please restart the app and try again.',
            );
          }
        } catch (schemaError) {
          return SyncResult(
            success: false,
            message: 'Database schema issue. Please restart the app and try again.',
          );
        }
      }
      
      return SyncResult(
        success: false,
        message: 'Error syncing training sites: $e',
      );
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Reset training sites page counter (useful for starting fresh sync)
  Future<void> resetTrainingSitesPageCounter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('training_sites_current_page', 1);
      developer.log('Reset training sites page counter to 1', name: 'DashboardProvider');
    } catch (e) {
      developer.log('Error resetting page counter: $e', name: 'DashboardProvider');
    }
  }

  // Sync monitoring data from server (placeholder for future implementation)
  Future<SyncResult> syncMonitoring({
    Function(String status, int current, int total)? onProgress,
  }) async {
    _isSyncing = true;
    notifyListeners();

    try {
      developer.log('Starting monitoring sync...', name: 'DashboardProvider');
      
      // TODO: Implement monitoring sync when API is available
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      // Save sync timestamp for placeholder
      await _saveLastSyncTime('monitoring', DateTime.now());
      
      // Refresh dashboard data
      await loadDashboardData();
      
      return SyncResult(
        success: true,
        recordsProcessed: 0,
        message: 'Monitoring sync not yet implemented',
      );
    } catch (e) {
      developer.log('Error syncing monitoring: $e', name: 'DashboardProvider');
      return SyncResult(
        success: false,
        message: 'Error syncing monitoring: $e',
      );
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Sync audit data from server (placeholder for future implementation)
  Future<SyncResult> syncAudit({
    Function(String status, int current, int total)? onProgress,
  }) async {
    _isSyncing = true;
    notifyListeners();

    try {
      developer.log('Starting audit sync...', name: 'DashboardProvider');
      
      // TODO: Implement audit sync when API is available
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      // Save sync timestamp for placeholder
      await _saveLastSyncTime('audit', DateTime.now());
      
      // Refresh dashboard data
      await loadDashboardData();
      
      return SyncResult(
        success: true,
        recordsProcessed: 0,
        message: 'Audit sync not yet implemented',
      );
    } catch (e) {
      developer.log('Error syncing audit: $e', name: 'DashboardProvider');
      return SyncResult(
        success: false,
        message: 'Error syncing audit: $e',
      );
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Method to manually test database queries
  Future<void> testDatabaseQueries() async {
    try {
      final trainingSiteCount = await _trainingSiteRepository.getCount();
      final syncedTrainingSiteCount = await _trainingSiteRepository.getSyncedCount();
      final unsyncedTrainingSiteCount = await _trainingSiteRepository.getUnsyncedCount();
      final beneficiaryCount = await _beneficiaryRepository.getCount();
      final unsyncedBeneficiaryCount = await _beneficiaryRepository.getUnsyncedCount();
      
      developer.log('Manual Test Results:', name: 'DashboardProvider');
      developer.log('Training Sites - Total: $trainingSiteCount, Synced: $syncedTrainingSiteCount, Unsynced: $unsyncedTrainingSiteCount', name: 'DashboardProvider');
      developer.log('Beneficiaries: $beneficiaryCount (Unsynced: $unsyncedBeneficiaryCount)', name: 'DashboardProvider');
    } catch (e) {
      developer.log('Error in manual test: $e', name: 'DashboardProvider');
    }
  }

  // Get formatted last sync time for a module
  String getLastSyncTimeFormatted(String moduleType) {
    DateTime? lastSync;
    
    switch (moduleType.toLowerCase()) {
      case 'training':
        lastSync = _lastTrainingSiteSync;
        break;
      case 'beneficiary':
        lastSync = _lastBeneficiarySync;
        break;
      case 'monitoring':
        lastSync = _lastMonitoringSync;
        break;
      case 'audit':
        lastSync = _lastAuditSync;
        break;
      default:
        return 'Never synced';
    }
    
    if (lastSync == null) {
      return 'Never synced';
    }
    
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // Format as date for older syncs
      return '${lastSync.day}/${lastSync.month}/${lastSync.year}';
    }
  }

  // Get detailed last sync time for a module
  String getLastSyncTimeDetailed(String moduleType) {
    DateTime? lastSync;
    
    switch (moduleType.toLowerCase()) {
      case 'training':
        lastSync = _lastTrainingSiteSync;
        break;
      case 'beneficiary':
        lastSync = _lastBeneficiarySync;
        break;
      case 'monitoring':
        lastSync = _lastMonitoringSync;
        break;
      case 'audit':
        lastSync = _lastAuditSync;
        break;
      default:
        return 'Never synced';
    }
    
    if (lastSync == null) {
      return 'Never synced';
    }
    
    // Format as "Today • 2:30 PM" or "Mar 15 • 2:30 PM"
    final now = DateTime.now();
    final isToday = now.year == lastSync.year && 
                   now.month == lastSync.month && 
                   now.day == lastSync.day;
    
    final timeFormat = lastSync.hour > 12 
        ? '${lastSync.hour - 12}:${lastSync.minute.toString().padLeft(2, '0')} PM'
        : '${lastSync.hour == 0 ? 12 : lastSync.hour}:${lastSync.minute.toString().padLeft(2, '0')} ${lastSync.hour < 12 ? 'AM' : 'PM'}';
    
    if (isToday) {
      return 'Today • $timeFormat';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[lastSync.month - 1]} ${lastSync.day} • $timeFormat';
    }
  }

  // Sync beneficiaries from server
  Future<SyncResult> syncBeneficiaries({
    Function(String status, int current, int total)? onProgress,
  }) async {
    _isSyncing = true;
    notifyListeners();

    try {
      developer.log('========================================', name: 'DashboardProvider');
      developer.log('STARTING BENEFICIARY SYNC', name: 'DashboardProvider');
      developer.log('========================================', name: 'DashboardProvider');
      
      onProgress?.call('Starting beneficiary sync...', 0, 0);
      
      // Check if this is initial sync or incremental sync
      final isInitialSync = _lastBeneficiarySync == null;
      
      if (isInitialSync) {
        developer.log('Performing INITIAL FULL SYNC using pagination', name: 'DashboardProvider');
        
        // Fetch all beneficiaries from server using pagination
        final response = await _dataService.getAllBeneficiariesPaginated(
          limit: 50,
          onProgress: (currentRecords, totalRecords) {
            // Report progress with actual record counts
            onProgress?.call('Downloading records...', currentRecords, totalRecords);
          },
          storeInDatabase: true,
        );
        
        if (response.success && response.data != null) {
          final recordsProcessed = response.data!.length;
          
          developer.log('========================================', name: 'DashboardProvider');
          developer.log('INITIAL BENEFICIARY SYNC COMPLETED', name: 'DashboardProvider');
          developer.log('========================================', name: 'DashboardProvider');
          developer.log('✅ Successfully synced $recordsProcessed beneficiaries', name: 'DashboardProvider');
          
          // Save sync time
          await _saveLastSyncTime('beneficiary', DateTime.now());
          
          // Refresh dashboard data
          await loadDashboardData();
          
          onProgress?.call('Beneficiary sync completed', recordsProcessed, recordsProcessed);
          
          return SyncResult(
            success: true,
            recordsProcessed: recordsProcessed,
            message: recordsProcessed > 0 
                ? 'Successfully synced $recordsProcessed beneficiaries'
                : 'All data is up to date',
          );
        } else {
          developer.log('========================================', name: 'DashboardProvider');
          developer.log('INITIAL BENEFICIARY SYNC FAILED', name: 'DashboardProvider');
          developer.log('========================================', name: 'DashboardProvider');
          developer.log('Error: ${response.message}', name: 'DashboardProvider');
          
          return SyncResult(
            success: false,
            message: response.message ?? 'Failed to sync beneficiaries',
          );
        }
      } else {
        developer.log('Performing INCREMENTAL SYNC using Beneficiary_data endpoint', name: 'DashboardProvider');
        
        // Capture the current time BEFORE making the API call
        final newSyncTime = DateTime.now();
        
        // Format last sync date for API in ISO 8601 format (UTC)
        final lastSyncDate = _lastBeneficiarySync!.toUtc().toIso8601String();
        
        developer.log('Last sync date (ISO 8601): $lastSyncDate', name: 'DashboardProvider');
        developer.log('New sync time will be: ${newSyncTime.toUtc().toIso8601String()}', name: 'DashboardProvider');
        
        onProgress?.call('Checking for updates since $lastSyncDate...', 0, 0);
        
        // Use incremental sync endpoint
        final response = await _dataService.syncUpdatedBeneficiaries(lastSyncDate);
        
        if (response.success) {
          final recordsProcessed = response.data ?? 0;
          
          developer.log('========================================', name: 'DashboardProvider');
          developer.log('INCREMENTAL BENEFICIARY SYNC COMPLETED', name: 'DashboardProvider');
          developer.log('========================================', name: 'DashboardProvider');
          developer.log('✅ Successfully synced $recordsProcessed updated beneficiaries', name: 'DashboardProvider');
          
          // Save the sync time that was captured BEFORE the API call
          await _saveLastSyncTime('beneficiary', newSyncTime);
          
          // Refresh dashboard data
          await loadDashboardData();
          
          onProgress?.call('Beneficiary sync completed', recordsProcessed, recordsProcessed);
          
          return SyncResult(
            success: true,
            recordsProcessed: recordsProcessed,
            message: recordsProcessed > 0 
                ? 'Successfully synced $recordsProcessed updated beneficiaries'
                : 'All data is up to date',
          );
        } else {
          developer.log('========================================', name: 'DashboardProvider');
          developer.log('INCREMENTAL BENEFICIARY SYNC FAILED', name: 'DashboardProvider');
          developer.log('========================================', name: 'DashboardProvider');
          developer.log('Error: ${response.message}', name: 'DashboardProvider');
          
          return SyncResult(
            success: false,
            message: response.message ?? 'Failed to sync updated beneficiaries',
          );
        }
      }
    } catch (e) {
      developer.log('========================================', name: 'DashboardProvider');
      developer.log('BENEFICIARY SYNC EXCEPTION', name: 'DashboardProvider');
      developer.log('========================================', name: 'DashboardProvider');
      developer.log('Error: $e', name: 'DashboardProvider');
      
      return SyncResult(
        success: false,
        message: 'Error syncing beneficiaries: $e',
      );
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}

// Result class for sync operations
class SyncResult {
  final bool success;
  final int recordsProcessed;
  final String message;

  SyncResult({
    required this.success,
    this.recordsProcessed = 0,
    required this.message,
  });
}