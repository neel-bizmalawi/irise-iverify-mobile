import 'package:irise/core/network/dio_client.dart';
import 'package:irise/data/repositories/training_site_repository.dart';
import 'package:irise/data/repositories/beneficiary_repository.dart';
import 'package:irise/data/repositories/training_repository.dart';
import 'package:irise/data/repositories/sync_queue_repository.dart';
import 'package:irise/data/models/training_site.dart';
import 'package:irise/data/models/beneficiary.dart';
import 'package:irise/data/models/training.dart';
import 'package:irise/data/services/data_service.dart';
import 'dart:developer' as developer;

class SyncService {
  final DioClient _dioClient = DioClient.instance;
  final DataService _dataService = DataService();
  final TrainingSiteRepository _trainingSiteRepo = TrainingSiteRepository();
  final BeneficiaryRepository _beneficiaryRepo = BeneficiaryRepository();
  final TrainingRepository _trainingRepo = TrainingRepository();
  final SyncQueueRepository _syncQueueRepo = SyncQueueRepository();

  // Sync all data from server to local DB using paginated API
  Future<SyncResult> syncFromServer() async {
    try {
      developer.log('Starting sync from server using paginated API...', name: 'SyncService');
      
      int trainingSitesCount = 0;
      int beneficiariesCount = 0;
      int trainingsCount = 0;

      // Sync training sites using the comprehensive sync method
      final trainingSitesResponse = await _dataService.syncAllTrainingSites(
        limit: 10,
        onProgress: (status, current, total) {
          developer.log('Training sites sync: $status ($current/$total)', name: 'SyncService');
        },
        clearExisting: false, // Don't clear existing data, just update/insert
      );
      
      if (trainingSitesResponse.success && trainingSitesResponse.data != null) {
        trainingSitesCount = trainingSitesResponse.data!['totalProcessed'] ?? 0;
        developer.log('Successfully synced $trainingSitesCount training sites', name: 'SyncService');
      } else {
        developer.log('Failed to sync training sites: ${trainingSitesResponse.message}', name: 'SyncService');
        
        // Fallback: Try the old sync endpoint
        developer.log('Falling back to sync endpoint...', name: 'SyncService');
        final payload = await _prepareUnsyncedDataPayload();
        final syncResponse = await _dataService.getSyncData(payload: payload);
        
        if (syncResponse.success && syncResponse.data != null) {
          final syncData = syncResponse.data!.data;
          
          if (syncData != null) {
            // Sync training sites from sync endpoint
            if (syncData.trainingSites != null && syncData.trainingSites!.isNotEmpty) {
              try {
                final sites = syncData.trainingSites!
                    .map((json) => TrainingSite.fromJson(json))
                    .toList();
                
                // Mark all as synced since they come from server
                final sitesWithSyncStatus = sites.map((site) => 
                  site.copyWith(sIsSync: 1)
                ).toList();
                
                await _trainingSiteRepo.insertBulk(sitesWithSyncStatus);
                trainingSitesCount = sites.length;
              } catch (e) {
                developer.log('Error syncing training sites from sync endpoint: $e', name: 'SyncService');
              }
            }

            // Sync beneficiaries
            if (syncData.beneficiaries != null && syncData.beneficiaries!.isNotEmpty) {
              try {
                final beneficiaries = syncData.beneficiaries!
                    .map((json) => Beneficiary.fromJson(json))
                    .toList();
                
                // Mark all as synced since they come from server
                final beneficiariesWithSyncStatus = beneficiaries.map((beneficiary) => 
                  beneficiary.copyWith(sIsSync: 1)
                ).toList();
                
                await _beneficiaryRepo.insertBulk(beneficiariesWithSyncStatus);
                beneficiariesCount = beneficiaries.length;
              } catch (e) {
                developer.log('Error syncing beneficiaries: $e', name: 'SyncService');
              }
            }

            // Sync trainings
            if (syncData.trainings != null && syncData.trainings!.isNotEmpty) {
              try {
                final trainings = syncData.trainings!
                    .map((json) => Training.fromJson(json))
                    .toList();
                
                // Note: Trainings from server are assumed to be synced
                // The model should handle s_is_sync in fromJson or we need to add copyWith
                await _trainingRepo.insertBulk(trainings);
                trainingsCount = trainings.length;
              } catch (e) {
                developer.log('Error syncing trainings: $e', name: 'SyncService');
              }
            }
          }
        }
      }

      developer.log(
        'Sync completed: $trainingSitesCount sites, $beneficiariesCount beneficiaries, $trainingsCount trainings',
        name: 'SyncService',
      );

      return SyncResult(
        success: true,
        trainingSitesCount: trainingSitesCount,
        beneficiariesCount: beneficiariesCount,
        trainingsCount: trainingsCount,
      );
    } catch (e) {
      developer.log('Sync from server failed: $e', name: 'SyncService');
      return SyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Sync local changes to server
  Future<SyncResult> syncToServer() async {
    try {
      developer.log('Starting sync to server...', name: 'SyncService');
      
      int trainingSitesSynced = 0;
      int beneficiariesSynced = 0;
      int trainingsSynced = 0;

      // Sync unsynced training sites
      final unsyncedSites = await _trainingSiteRepo.getUnsynced();
      if (unsyncedSites.isNotEmpty) {
        developer.log('Syncing ${unsyncedSites.length} training sites to server...', name: 'SyncService');
        
        final sitesPayload = unsyncedSites.map((site) => site.toApiJson()).toList();
        final response = await _dataService.syncTrainingSites(sitesPayload);
        
        if (response.success && response.data != null) {
          // Mark sites as synced
          for (var site in unsyncedSites) {
            if (site.offlineId != null) {
              await _trainingSiteRepo.update(site.copyWith(sIsSync: 1));
            }
          }
          trainingSitesSynced = unsyncedSites.length;
          developer.log('Successfully synced $trainingSitesSynced training sites', name: 'SyncService');
        }
      }

      // Sync unsynced beneficiaries using the dedicated method
      final beneficiaryResponse = await _dataService.syncBeneficiariesToServer();
      if (beneficiaryResponse.success && beneficiaryResponse.data != null) {
        beneficiariesSynced = beneficiaryResponse.data!['synced'] ?? 0;
        developer.log('Successfully synced $beneficiariesSynced beneficiaries', name: 'SyncService');
      }

      // Sync unsynced trainings
      final unsyncedTrainings = await _trainingRepo.getUnsynced();
      if (unsyncedTrainings.isNotEmpty) {
        developer.log('Syncing ${unsyncedTrainings.length} trainings to server...', name: 'SyncService');
        
        final trainingsPayload = unsyncedTrainings.map((training) => training.toJson()).toList();
        final response = await _dataService.syncTrainings(trainingsPayload);
        
        if (response.success && response.data != null) {
          // Mark trainings as synced by updating s_is_sync field
          for (var training in unsyncedTrainings) {
            if (training.offlineId != null) {
              final updatedTraining = Training(
                trainingId: training.trainingId,
                trainingPointId: training.trainingPointId,
                trainingDate: training.trainingDate,
                trainerName: training.trainerName,
                participantsCount: training.participantsCount,
                malesCount: training.malesCount,
                femalesCount: training.femalesCount,
                trainingType: training.trainingType,
                trainingNotes: training.trainingNotes,
                sIsSync: 1, // Mark as synced
                createdBy: training.createdBy,
                modifiedBy: training.modifiedBy,
                createdDate: training.createdDate,
                modifiedDate: training.modifiedDate,
                status: training.status,
                offlineId: training.offlineId,
                serverTime: training.serverTime,
              );
              await _trainingRepo.update(updatedTraining);
            }
          }
          trainingsSynced = unsyncedTrainings.length;
          developer.log('Successfully synced $trainingsSynced trainings', name: 'SyncService');
        }
      }

      // Process sync queue items
      int queueSynced = 0;
      final pendingItems = await _syncQueueRepo.getPendingItems();
      for (var item in pendingItems) {
        try {
          final success = await _processSyncItem(item);
          
          if (success) {
            await _syncQueueRepo.removeFromQueue(item['id']);
            queueSynced++;
          } else {
            final retryCount = (item['retry_count'] ?? 0) + 1;
            await _syncQueueRepo.updateRetryCount(
              item['id'],
              retryCount,
              'Sync failed',
            );
          }
        } catch (e) {
          developer.log('Error processing sync item: $e', name: 'SyncService');
          final retryCount = (item['retry_count'] ?? 0) + 1;
          await _syncQueueRepo.updateRetryCount(
            item['id'],
            retryCount,
            e.toString(),
          );
        }
      }

      final totalSynced = trainingSitesSynced + beneficiariesSynced + trainingsSynced + queueSynced;
      developer.log('Synced $totalSynced items to server', name: 'SyncService');

      return SyncResult(
        success: true,
        trainingSitesCount: trainingSitesSynced,
        beneficiariesCount: beneficiariesSynced,
        trainingsCount: trainingsSynced,
        syncedToServerCount: totalSynced,
      );
    } catch (e) {
      developer.log('Sync to server failed: $e', name: 'SyncService');
      return SyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> _processSyncItem(Map<String, dynamic> item) async {
    final tableName = item['table_name'];
    final operation = item['operation'];
    final data = item['data'];

    // Map table names to API endpoints
    String endpoint = '';
    switch (tableName) {
      case 'training_sites':
        endpoint = '/training-sites';
        break;
      case 'beneficiaries':
        endpoint = '/beneficiaries';
        break;
      case 'trainings':
        endpoint = '/trainings';
        break;
      default:
        return false;
    }

    try {
      switch (operation) {
        case 'insert':
          await _dioClient.post(endpoint, data: data);
          break;
        case 'update':
          final id = item['record_id'];
          await _dioClient.put('$endpoint/$id', data: data);
          break;
        case 'delete':
          final id = item['record_id'];
          await _dioClient.delete('$endpoint/$id');
          break;
      }
      return true;
    } catch (e) {
      developer.log('Error processing $operation on $tableName: $e', name: 'SyncService');
      return false;
    }
  }

  // Prepare payload with unsynced data to send to server
  Future<Map<String, dynamic>> _prepareUnsyncedDataPayload() async {
    try {
      final payload = <String, dynamic>{};

      // Get unsynced training sites
      final unsyncedSites = await _trainingSiteRepo.getUnsynced();
      if (unsyncedSites.isNotEmpty) {
        payload['training_sites'] = unsyncedSites.map((site) {
          final json = site.toApiJson();
          // Ensure created_date is included
          json['created_date'] = json['created_date'] ?? DateTime.now().toIso8601String();
          return json;
        }).toList();
      }

      // Get unsynced beneficiaries
      final unsyncedBeneficiaries = await _beneficiaryRepo.getUnsynced();
      if (unsyncedBeneficiaries.isNotEmpty) {
        payload['beneficiaries'] = unsyncedBeneficiaries.map((beneficiary) {
          // Use toJsonForSync() which excludes national_id
          return beneficiary.toJsonForSync();
        }).toList();
      }

      // Get unsynced trainings
      final unsyncedTrainings = await _trainingRepo.getUnsynced();
      if (unsyncedTrainings.isNotEmpty) {
        payload['trainings'] = unsyncedTrainings.map((training) {
          final json = training.toJson();
          json['created_date'] = json['created_date'] ?? DateTime.now().toIso8601String();
          return json;
        }).toList();
      }

      developer.log('Prepared sync payload with ${payload.keys.length} data types', name: 'SyncService');
      return payload;
    } catch (e) {
      developer.log('Error preparing sync payload: $e', name: 'SyncService');
      return {};
    }
  }

  // Full bidirectional sync
  Future<SyncResult> fullSync() async {
    try {
      // First sync from server
      final fromServerResult = await syncFromServer();
      
      // Then sync to server
      final toServerResult = await syncToServer();

      return SyncResult(
        success: fromServerResult.success && toServerResult.success,
        trainingSitesCount: fromServerResult.trainingSitesCount,
        beneficiariesCount: fromServerResult.beneficiariesCount,
        trainingsCount: fromServerResult.trainingsCount,
        syncedToServerCount: toServerResult.syncedToServerCount,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Get sync status
  Future<SyncStatus> getSyncStatus() async {
    try {
      final pendingCount = await _syncQueueRepo.getQueueCount();
      final unsyncedSites = await _trainingSiteRepo.getUnsynced();
      final unsyncedBeneficiaries = await _beneficiaryRepo.getUnsynced();
      final unsyncedTrainings = await _trainingRepo.getUnsynced();

      return SyncStatus(
        pendingOperations: pendingCount,
        unsyncedSites: unsyncedSites.length,
        unsyncedBeneficiaries: unsyncedBeneficiaries.length,
        unsyncedTrainings: unsyncedTrainings.length,
      );
    } catch (e) {
      return SyncStatus();
    }
  }

  // Verify that data has been fetched and persisted before allowing sync
  Future<DataVerificationResult> verifyDataBeforeSync() async {
    try {
      developer.log('Verifying data before sync...', name: 'SyncService');
      
      // Check if there are synced training sites in the database
      final syncedSites = await _trainingSiteRepo.getSyncedCount();
      
      if (syncedSites == 0) {
        developer.log('No synced training sites found in database', name: 'SyncService');
        return DataVerificationResult(
          isVerified: false,
          message: 'No data found in local database. Please sync data from the dashboard first before conducting training.',
        );
      }
      
      developer.log('Data verification successful: $syncedSites synced training sites found', name: 'SyncService');
      return DataVerificationResult(
        isVerified: true,
        syncedCount: syncedSites,
        message: 'Data verification successful',
      );
    } catch (e) {
      developer.log('Error verifying data: $e', name: 'SyncService');
      return DataVerificationResult(
        isVerified: false,
        message: 'Failed to verify data: $e',
      );
    }
  }
}

class SyncResult {
  final bool success;
  final String? error;
  final int trainingSitesCount;
  final int beneficiariesCount;
  final int trainingsCount;
  final int syncedToServerCount;

  SyncResult({
    required this.success,
    this.error,
    this.trainingSitesCount = 0,
    this.beneficiariesCount = 0,
    this.trainingsCount = 0,
    this.syncedToServerCount = 0,
  });
}

class SyncStatus {
  final int pendingOperations;
  final int unsyncedSites;
  final int unsyncedBeneficiaries;
  final int unsyncedTrainings;

  SyncStatus({
    this.pendingOperations = 0,
    this.unsyncedSites = 0,
    this.unsyncedBeneficiaries = 0,
    this.unsyncedTrainings = 0,
  });

  int get totalUnsynced =>
      pendingOperations + unsyncedSites + unsyncedBeneficiaries + unsyncedTrainings;
}

class DataVerificationResult {
  final bool isVerified;
  final int syncedCount;
  final String message;

  DataVerificationResult({
    required this.isVerified,
    this.syncedCount = 0,
    required this.message,
  });
}
