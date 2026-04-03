import 'package:dio/dio.dart';
import 'package:irise/core/constants/api_constants.dart';
import 'package:irise/core/network/dio_client.dart';
import 'package:irise/data/models/training_site.dart';
import 'package:irise/data/models/district.dart';
import 'package:irise/data/models/authority.dart';
import 'package:irise/data/models/language.dart';
import 'package:irise/data/models/cookstove.dart';
import 'package:irise/data/models/training_site_list.dart';
import 'package:irise/data/models/sync_response.dart';
import 'package:irise/data/models/paginated_response.dart';
import 'package:irise/data/repositories/training_site_repository.dart';
import 'package:irise/data/repositories/district_repository.dart';
import 'package:irise/data/repositories/authority_repository.dart';
import 'package:irise/data/repositories/language_repository.dart';
import 'package:irise/data/repositories/cookstove_repository.dart';
import 'package:irise/data/repositories/training_site_list_repository.dart';
import 'package:irise/data/repositories/beneficiary_repository.dart';
import 'package:irise/data/models/beneficiary.dart';
import 'package:irise/core/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'dart:io';

class DataService {
  final DioClient _dioClient = DioClient.instance;

  /// Check network connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('admin.iverifycarbon.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      developer.log('Network connectivity check failed: $e', name: 'DataService');
      return false;
    }
  }

  /// GET /training_set
  /// Fetches all training sites from the server
  Future<DataResponse<List<TrainingSite>>> getTrainingSet() async {
    try {
      developer.log('Fetching training set...', name: 'DataService');
      
      final response = await _dioClient.get(ApiConstants.trainingSet);
      
      if (response.data != null) {
        List<TrainingSite> trainingSites = [];
        
        // Handle different response structures
        if (response.data is Map && response.data['data'] != null) {
          final data = response.data['data'];
          if (data is List) {
            trainingSites = data
                .map((json) => TrainingSite.fromJson(json))
                .toList();
          }
        } else if (response.data is List) {
          trainingSites = (response.data as List)
              .map((json) => TrainingSite.fromJson(json))
              .toList();
        }
        
        developer.log('Fetched ${trainingSites.length} training sites', name: 'DataService');
        
        return DataResponse(
          success: true,
          data: trainingSites,
          message: 'Training sites fetched successfully',
        );
      }
      
      return DataResponse(
        success: false,
        message: 'No data received',
      );
    } on DioException catch (e) {
      developer.log('Error fetching training set: \${e.message}', name: 'DataService');
      return DataResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Failed to fetch training sites',
      );
    } catch (e) {
      developer.log('Unexpected error: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  /// POST /sync
  /// Sends data for synchronization with dynamic payload
  Future<DataResponse<SyncResponse>> getSyncData({Map<String, dynamic>? payload}) async {
    try {
      developer.log('Sending sync data...', name: 'DataService');
      
      // Default empty payload if none provided
      final requestBody = payload ?? {};
      
      developer.log('Sync payload: $requestBody', name: 'DataService');
      
      final response = await _dioClient.post(
        ApiConstants.sync,
        data: requestBody,
      );
      
      if (response.data != null) {
        final syncResponse = SyncResponse.fromJson(response.data);
        
        developer.log('Sync data sent successfully', name: 'DataService');
        
        return DataResponse(
          success: true,
          data: syncResponse,
          message: 'Sync data sent successfully',
        );
      }
      
      return DataResponse(
        success: false,
        message: 'No sync response received',
      );
    } on DioException catch (e) {
      developer.log('Error sending sync data: ${e.message}', name: 'DataService');
      return DataResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Failed to send sync data',
      );
    } catch (e) {
      developer.log('Unexpected error: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  /// GET /training-site/training_set with pagination
  /// Fetches training sites from server with pagination support
  Future<DataResponse<PaginatedResponse<TrainingSite>>> getTrainingSetPaginated({
    int page = 1,
    int limit = 100,
  }) async {
    try {
      developer.log('Fetching paginated training set - page: $page, limit: $limit', name: 'DataService');
      
      final response = await _dioClient.get(
        ApiConstants.trainingSetPaginated,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      
      if (response.data != null) {
        final paginatedResponse = PaginatedResponse<TrainingSite>.fromJson(
          response.data,
          (json) => TrainingSite.fromJson(json),
        );
        
        developer.log(
          'Fetched ${paginatedResponse.data.length} training sites (page $page/${paginatedResponse.totalPages})',
          name: 'DataService',
        );
        
        return DataResponse(
          success: true,
          data: paginatedResponse,
          message: 'Training sites fetched successfully',
        );
      }
      
      return DataResponse(
        success: false,
        message: 'No data received',
      );
    } on DioException catch (e) {
      developer.log('Error fetching paginated training set: ${e.message}', name: 'DataService');
      return DataResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Failed to fetch training sites',
      );
    } catch (e) {
      developer.log('Unexpected error: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Fetch all training sites by iterating through all pages and store in local database
  /// IMPORTANT: Preserves local unsynced records during sync
  Future<DataResponse<List<TrainingSite>>> getAllTrainingSitesPaginated({
    int limit = 10,
    Function(int currentRecords, int totalRecords)? onProgress,
    bool storeInDatabase = true,
  }) async {
    try {
      developer.log('Starting to fetch all training sites with pagination', name: 'DataService');
      
      List<TrainingSite> allTrainingSites = [];
      int currentPage = 1;
      int totalPages = 1;
      int totalRecords = 0;
      
      // STEP 1: If storing in database, backup unsynced local records
      List<TrainingSite> unsyncedBackup = [];
      if (storeInDatabase) {
        final trainingSiteRepo = TrainingSiteRepository();
        unsyncedBackup = await trainingSiteRepo.getUnsynced();
        developer.log('Backed up ${unsyncedBackup.length} unsynced local records before sync', name: 'DataService');
      }
      
      do {
        final response = await getTrainingSetPaginated(page: currentPage, limit: limit);
        
        if (!response.success || response.data == null) {
          return DataResponse(
            success: false,
            message: response.message ?? 'Failed to fetch training sites',
          );
        }
        
        final paginatedData = response.data!;
        allTrainingSites.addAll(paginatedData.data);
        totalPages = paginatedData.totalPages;
        totalRecords = paginatedData.totalRecords;
        
        // Call progress callback with cumulative records downloaded and total records
        onProgress?.call(allTrainingSites.length, totalRecords);
        
        developer.log(
          'Fetched page $currentPage/$totalPages (${paginatedData.data.length} items)',
          name: 'DataService',
        );
        
        currentPage++;
      } while (currentPage <= totalPages);
      
      developer.log(
        'Successfully fetched all ${allTrainingSites.length} training sites from $totalPages pages',
        name: 'DataService',
      );
      
      // Store in local database if requested
      if (storeInDatabase && allTrainingSites.isNotEmpty) {
        try {
          final trainingSiteRepo = TrainingSiteRepository();
          
          // Mark all as synced since they come from server
          final sitesWithSyncStatus = allTrainingSites.map((site) => 
            site.copyWith(sIsSync: 1)
          ).toList();
          
          await trainingSiteRepo.insertBulk(sitesWithSyncStatus);
          developer.log('Stored ${allTrainingSites.length} training sites in local database (marked as synced)', name: 'DataService');
          
          // STEP 2: Verify unsynced records are still there
          final unsyncedCountAfter = await trainingSiteRepo.getUnsyncedCount();
          developer.log('After sync: $unsyncedCountAfter unsynced local records', name: 'DataService');
          
          if (unsyncedCountAfter < unsyncedBackup.length) {
            developer.log('WARNING: Some local records were lost! Restoring...', name: 'DataService');
            // Restore lost records
            await trainingSiteRepo.insertBulk(unsyncedBackup);
            developer.log('Restored ${unsyncedBackup.length} local records', name: 'DataService');
          } else {
            developer.log('✅ All local unsynced records preserved', name: 'DataService');
          }
        } catch (e) {
          developer.log('Error storing training sites in database: $e', name: 'DataService');
          // Don't fail the entire operation if database storage fails
        }
      }
      
      return DataResponse(
        success: true,
        data: allTrainingSites,
        message: 'All training sites fetched successfully',
      );
    } catch (e) {
      developer.log('Error fetching all training sites: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'Failed to fetch all training sites: $e',
      );
    }
  }

  /// Process paginated training sites response and store in local database
  /// This method handles the specific API response format with pagination metadata
  Future<DataResponse<int>> processTrainingSitesResponse(Map<String, dynamic> responseData) async {
    try {
      developer.log('Processing training sites response...', name: 'DataService');
      
      // Extract pagination info
      final currentPage = responseData['currentPage'] ?? 1;
      final totalPages = responseData['totalPages'] ?? 1;
      final totalRecords = responseData['totalRecords'] ?? 0;
      final data = responseData['data'] as List<dynamic>? ?? [];
      
      developer.log(
        'Processing page $currentPage/$totalPages with ${data.length} records (total: $totalRecords)',
        name: 'DataService',
      );
      
      if (data.isEmpty) {
        return DataResponse(
          success: true,
          data: 0,
          message: 'No training sites to process',
        );
      }
      
      // Convert API response to TrainingSite objects
      final trainingSites = data.map((json) {
        try {
          return TrainingSite.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          developer.log('Error parsing training site: $e', name: 'DataService');
          developer.log('Problematic data: $json', name: 'DataService');
          rethrow;
        }
      }).toList();
      
      // Store in local database
      final trainingSiteRepo = TrainingSiteRepository();
      
      // Mark all as synced since they come from server
      final sitesWithSyncStatus = trainingSites.map((site) => 
        site.copyWith(sIsSync: 1)
      ).toList();
      
      await trainingSiteRepo.insertBulk(sitesWithSyncStatus);
      
      developer.log('Successfully stored ${trainingSites.length} training sites in local database', name: 'DataService');
      
      return DataResponse(
        success: true,
        data: trainingSites.length,
        message: 'Successfully processed ${trainingSites.length} training sites',
      );
    } catch (e) {
      developer.log('Error processing training sites response: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'Failed to process training sites: $e',
      );
    }
  }
  Future<DataResponse<int>> syncTrainingSitesFromServer({
    int limit = 10,
    Function(int current, int total)? onProgress,
    bool clearExisting = false,
  }) async {
    try {
      developer.log('Starting training sites sync from server...', name: 'DataService');
      
      final trainingSiteRepo = TrainingSiteRepository();
      
      // Clear existing data if requested
      if (clearExisting) {
        await trainingSiteRepo.clearAll();
        developer.log('Cleared existing training sites from local database', name: 'DataService');
      }
      
      // Fetch all training sites from server
      final response = await getAllTrainingSitesPaginated(
        limit: limit,
        onProgress: onProgress,
        storeInDatabase: false, // We'll handle storage manually
      );
      
      if (!response.success || response.data == null) {
        return DataResponse(
          success: false,
          message: response.message ?? 'Failed to fetch training sites from server',
        );
      }
      
      final trainingSites = response.data!;
      
      if (trainingSites.isNotEmpty) {
        // Store in local database with proper sync status
        final sitesWithSyncStatus = trainingSites.map((site) => 
          site.copyWith(sIsSync: 1) // Mark as synced since they come from server
        ).toList();
        
        await trainingSiteRepo.insertBulk(sitesWithSyncStatus);
        developer.log('Successfully synced ${trainingSites.length} training sites to local database', name: 'DataService');
      }
      
      return DataResponse(
        success: true,
        data: trainingSites.length,
        message: 'Successfully synced ${trainingSites.length} training sites',
      );
    } catch (e) {
      developer.log('Error syncing training sites from server: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'Failed to sync training sites: $e',
      );
    }
  }

  /// Convenience method to sync training sites
  Future<DataResponse<SyncResponse>> syncTrainingSites(List<Map<String, dynamic>> trainingSites) async {
    return getSyncData(payload: {'trainings': trainingSites});
  }

  /// Convenience method to sync beneficiaries
  Future<DataResponse<SyncResponse>> syncBeneficiaries(List<Map<String, dynamic>> beneficiaries) async {
    return getSyncData(payload: {'beneficiaries': beneficiaries});
  }

  /// Convenience method to sync trainings
  Future<DataResponse<SyncResponse>> syncTrainings(List<Map<String, dynamic>> trainings) async {
    return getSyncData(payload: {'trainings': trainings});
  }

  /// Convenience method to sync multiple data types
  Future<DataResponse<SyncResponse>> syncMultipleData({
    List<Map<String, dynamic>>? trainingSites,
    List<Map<String, dynamic>>? beneficiaries,
    List<Map<String, dynamic>>? trainings,
  }) async {
    final payload = <String, dynamic>{};
    
    if (trainingSites != null && trainingSites.isNotEmpty) {
      payload['training_sites'] = trainingSites;
    }
    if (beneficiaries != null && beneficiaries.isNotEmpty) {
      payload['beneficiaries'] = beneficiaries;
    }
    if (trainings != null && trainings.isNotEmpty) {
      payload['trainings'] = trainings;
    }
    
    return getSyncData(payload: payload);
  }

  /// GET /district_slug
  /// Fetches all districts
  Future<DataResponse<List<District>>> getDistricts() async {
    try {
      developer.log('Fetching districts...', name: 'DataService');
      
      // Check network connectivity first
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        developer.log('No network connectivity', name: 'DataService');
        return DataResponse(
          success: false,
          message: 'No internet connection. Please check your network settings.',
        );
      }
      
      developer.log('Making API call to: ${ApiConstants.baseUrl}${ApiConstants.districtSlug}', name: 'DataService');
      
      final response = await _dioClient.get(ApiConstants.districtSlug);
      
      if (response.data != null) {
        List<District> districts = [];
        
        // Handle different response structures
        if (response.data is Map && response.data['data'] != null) {
          final data = response.data['data'];
          if (data is List) {
            districts = data
                .map((json) => District.fromJson(json))
                .toList();
          }
        } else if (response.data is List) {
          districts = (response.data as List)
              .map((json) => District.fromJson(json))
              .toList();
        }
        
        developer.log('Fetched ${districts.length} districts', name: 'DataService');
        
        return DataResponse(
          success: true,
          data: districts,
          message: 'Districts fetched successfully',
        );
      }
      
      return DataResponse(
        success: false,
        message: 'No data received',
      );
    } on DioException catch (e) {
      developer.log('DioException fetching districts: ${e.type} - ${e.message}', name: 'DataService');
      developer.log('Response: ${e.response?.data}', name: 'DataService');
      developer.log('Status Code: ${e.response?.statusCode}', name: 'DataService');
      
      String errorMessage = 'Failed to fetch districts';
      
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage = 'Connection timeout. Please check your internet connection.';
          break;
        case DioExceptionType.sendTimeout:
          errorMessage = 'Request timeout. Please try again.';
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Server response timeout. Please try again.';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Connection failed. Please check your internet connection and try again.';
          break;
        case DioExceptionType.badResponse:
          errorMessage = e.response?.data?['message'] ?? 'Server error occurred.';
          break;
        default:
          errorMessage = e.message ?? 'An unexpected error occurred.';
      }
      
      return DataResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      developer.log('Unexpected error: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  /// GET /authority_slug
  /// Fetches all traditional authorities
  Future<DataResponse<List<Authority>>> getAuthorities() async {
    try {
      developer.log('Fetching authorities...', name: 'DataService');
      
      // Check network connectivity first
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        developer.log('No network connectivity', name: 'DataService');
        return DataResponse(
          success: false,
          message: 'No internet connection. Please check your network settings.',
        );
      }
      
      developer.log('Making API call to: ${ApiConstants.baseUrl}${ApiConstants.authoritySlug}', name: 'DataService');
      
      final response = await _dioClient.get(ApiConstants.authoritySlug);
      
      if (response.data != null) {
        List<Authority> authorities = [];
        
        // Handle different response structures
        if (response.data is Map && response.data['data'] != null) {
          final data = response.data['data'];
          if (data is List) {
            authorities = data
                .map((json) => Authority.fromJson(json))
                .toList();
          }
        } else if (response.data is List) {
          authorities = (response.data as List)
              .map((json) => Authority.fromJson(json))
              .toList();
        }
        
        developer.log('Fetched ${authorities.length} authorities', name: 'DataService');
        
        return DataResponse(
          success: true,
          data: authorities,
          message: 'Authorities fetched successfully',
        );
      }
      
      return DataResponse(
        success: false,
        message: 'No data received',
      );
    } on DioException catch (e) {
      developer.log('DioException fetching authorities: ${e.type} - ${e.message}', name: 'DataService');
      developer.log('Response: ${e.response?.data}', name: 'DataService');
      developer.log('Status Code: ${e.response?.statusCode}', name: 'DataService');
      
      String errorMessage = 'Failed to fetch authorities';
      
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage = 'Connection timeout. Please check your internet connection.';
          break;
        case DioExceptionType.sendTimeout:
          errorMessage = 'Request timeout. Please try again.';
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Server response timeout. Please try again.';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Connection failed. Please check your internet connection and try again.';
          break;
        case DioExceptionType.badResponse:
          errorMessage = e.response?.data?['message'] ?? 'Server error occurred.';
          break;
        default:
          errorMessage = e.message ?? 'An unexpected error occurred.';
      }
      
      return DataResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      developer.log('Unexpected error: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get authorities by district ID
  Future<DataResponse<List<Authority>>> getAuthoritiesByDistrict(int districtId) async {
    try {
      developer.log('Fetching authorities for district $districtId...', name: 'DataService');
      
      final response = await _dioClient.get(
        ApiConstants.authoritySlug,
        queryParameters: {'district_id': districtId},
      );
      
      if (response.data != null) {
        List<Authority> authorities = [];
        
        if (response.data is Map && response.data['data'] != null) {
          final data = response.data['data'];
          if (data is List) {
            authorities = data
                .map((json) => Authority.fromJson(json))
                .toList();
          }
        } else if (response.data is List) {
          authorities = (response.data as List)
              .map((json) => Authority.fromJson(json))
              .toList();
        }
        
        return DataResponse(
          success: true,
          data: authorities,
          message: 'Authorities fetched successfully',
        );
      }
      
      return DataResponse(
        success: false,
        message: 'No data received',
      );
    } on DioException catch (e) {
      developer.log('Error fetching authorities by district: ${e.message}', name: 'DataService');
      return DataResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Failed to fetch authorities',
      );
    } catch (e) {
      developer.log('Unexpected error: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }
  
  /// Debug method to test API connectivity
  Future<DataResponse<Map<String, dynamic>>> testConnectivity() async {
    final results = <String, dynamic>{};
    
    try {
      developer.log('Testing API connectivity...', name: 'DataService');
      
      // Test network connectivity
      final hasConnection = await _checkConnectivity();
      results['network_connectivity'] = hasConnection;
      
      if (!hasConnection) {
        return DataResponse(
          success: false,
          data: results,
          message: 'No network connectivity',
        );
      }
      
      // Test districts API
      try {
        final districtsResponse = await getDistricts();
        results['districts_api'] = {
          'success': districtsResponse.success,
          'message': districtsResponse.message,
          'count': districtsResponse.data?.length ?? 0,
        };
      } catch (e) {
        results['districts_api'] = {
          'success': false,
          'message': 'Error: $e',
          'count': 0,
        };
      }
      
      // Test authorities API
      try {
        final authoritiesResponse = await getAuthorities();
        results['authorities_api'] = {
          'success': authoritiesResponse.success,
          'message': authoritiesResponse.message,
          'count': authoritiesResponse.data?.length ?? 0,
        };
      } catch (e) {
        results['authorities_api'] = {
          'success': false,
          'message': 'Error: $e',
          'count': 0,
        };
      }
      
      final allSuccess = results['network_connectivity'] == true &&
          results['districts_api']['success'] == true &&
          results['authorities_api']['success'] == true;
      
      return DataResponse(
        success: allSuccess,
        data: results,
        message: allSuccess ? 'All connectivity tests passed' : 'Some connectivity tests failed',
      );
      
    } catch (e) {
      developer.log('Error testing connectivity: $e', name: 'DataService');
      results['error'] = e.toString();
      return DataResponse(
        success: false,
        data: results,
        message: 'Connectivity test failed: $e',
      );
    }
  }

  /// Clear all training sites from local database
  Future<DataResponse<void>> clearLocalTrainingSites() async {
    try {
      developer.log('Clearing all training sites from local database...', name: 'DataService');
      
      final trainingSiteRepo = TrainingSiteRepository();
      await trainingSiteRepo.clearAll();
      
      developer.log('Successfully cleared all training sites', name: 'DataService');
      
      return DataResponse(
        success: true,
        message: 'All training sites cleared successfully',
      );
    } catch (e) {
      developer.log('Error clearing training sites: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'Failed to clear training sites: $e',
      );
    }
  }

  /// Reset the entire database (delete and recreate)
  Future<DataResponse<void>> resetDatabase() async {
    try {
      developer.log('Resetting entire database...', name: 'DataService');
      
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.resetDatabase();
      
      developer.log('Successfully reset database', name: 'DataService');
      
      return DataResponse(
        success: true,
        message: 'Database reset successfully',
      );
    } catch (e) {
      developer.log('Error resetting database: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'Failed to reset database: $e',
      );
    }
  }

  /// Force database schema update by resetting and recreating
  Future<DataResponse<void>> updateDatabaseSchema() async {
    try {
      developer.log('Updating database schema...', name: 'DataService');
      
      // Reset the database to ensure latest schema
      final resetResult = await resetDatabase();
      if (!resetResult.success) {
        return resetResult;
      }
      
      // The database will be recreated with the latest schema on next access
      developer.log('Database schema updated successfully', name: 'DataService');
      
      return DataResponse(
        success: true,
        message: 'Database schema updated successfully',
      );
    } catch (e) {
      developer.log('Error updating database schema: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'Failed to update database schema: $e',
      );
    }
  }

  /// Complete sync process for all training sites with progress tracking
  /// This method fetches all pages and stores them in the local database
  /// IMPORTANT: Preserves local unsynced records during sync
  Future<DataResponse<Map<String, dynamic>>> syncAllTrainingSites({
    int limit = 10,
    Function(String status, int current, int total)? onProgress,
    bool clearExisting = false,
  }) async {
    try {
      developer.log('Starting complete training sites sync...', name: 'DataService');
      
      final trainingSiteRepo = TrainingSiteRepository();
      int totalProcessed = 0;
      int totalInserted = 0;
      int cumulativeRecordsDownloaded = 0;
      
      // STEP 1: Get count of unsynced local records BEFORE sync
      final unsyncedCountBefore = await trainingSiteRepo.getUnsyncedCount();
      final unsyncedRecordsBefore = await trainingSiteRepo.getUnsynced();
      developer.log('========================================', name: 'DataService');
      developer.log('BEFORE SYNC: $unsyncedCountBefore unsynced local records', name: 'DataService');
      for (var record in unsyncedRecordsBefore) {
        developer.log('  Local record: ${record.trainingSite} (offline_id: ${record.offlineId}, s_is_sync: ${record.sIsSync})', name: 'DataService');
      }
      developer.log('========================================', name: 'DataService');
      
      // Clear existing data if requested (but this will also clear local unsynced records!)
      if (clearExisting) {
        developer.log('WARNING: clearExisting=true will delete local unsynced records!', name: 'DataService');
        // Save unsynced records before clearing
        final unsyncedBackup = await trainingSiteRepo.getUnsynced();
        await trainingSiteRepo.clearAll();
        developer.log('Cleared existing training sites from local database', name: 'DataService');
        
        // Restore unsynced records
        if (unsyncedBackup.isNotEmpty) {
          await trainingSiteRepo.insertBulk(unsyncedBackup);
          developer.log('Restored ${unsyncedBackup.length} unsynced local records after clear', name: 'DataService');
        }
        
        onProgress?.call('Cleared existing data', 0, 0);
      }
      
      // Get first page to determine total pages and records
      onProgress?.call('Fetching page information...', 0, 0);
      final firstPageResponse = await getTrainingSetPaginated(page: 1, limit: limit);
      
      if (!firstPageResponse.success || firstPageResponse.data == null) {
        return DataResponse(
          success: false,
          message: firstPageResponse.message ?? 'Failed to fetch training sites',
        );
      }
      
      final firstPage = firstPageResponse.data!;
      final totalPages = firstPage.totalPages;
      final totalRecords = firstPage.totalRecords;
      
      developer.log('Found $totalRecords training sites across $totalPages pages', name: 'DataService');
      onProgress?.call('Found $totalRecords records in $totalPages pages', 0, totalRecords);
      
      // Process first page
      if (firstPage.data.isNotEmpty) {
        final sitesWithSyncStatus = firstPage.data.map((site) => 
          site.copyWith(sIsSync: 1)
        ).toList();
        
        // Get count before insert to track what was actually added
        final countBefore = await trainingSiteRepo.getCount();
        await trainingSiteRepo.insertBulk(sitesWithSyncStatus);
        final countAfter = await trainingSiteRepo.getCount();
        
        totalProcessed += firstPage.data.length;
        totalInserted += (countAfter - countBefore);
        cumulativeRecordsDownloaded += firstPage.data.length;
        
        developer.log('Page 1: Processed ${firstPage.data.length}, DB grew by ${countAfter - countBefore}', name: 'DataService');
        
        // Report progress with actual record counts
        onProgress?.call('Downloading records...', cumulativeRecordsDownloaded, totalRecords);
      }
      
      // Process remaining pages
      for (int page = 2; page <= totalPages; page++) {
        final pageResponse = await getTrainingSetPaginated(page: page, limit: limit);
        
        if (pageResponse.success && pageResponse.data != null) {
          final pageData = pageResponse.data!;
          if (pageData.data.isNotEmpty) {
            final sitesWithSyncStatus = pageData.data.map((site) => 
              site.copyWith(sIsSync: 1)
            ).toList();
            
            // Get count before insert to track what was actually added
            final countBefore = await trainingSiteRepo.getCount();
            await trainingSiteRepo.insertBulk(sitesWithSyncStatus);
            final countAfter = await trainingSiteRepo.getCount();
            
            totalProcessed += pageData.data.length;
            totalInserted += (countAfter - countBefore);
            cumulativeRecordsDownloaded += pageData.data.length;
            
            developer.log('Page $page: Processed ${pageData.data.length}, DB grew by ${countAfter - countBefore}', name: 'DataService');
            
            // Report progress with actual record counts
            onProgress?.call('Downloading records...', cumulativeRecordsDownloaded, totalRecords);
          }
        }
        
        developer.log('Processed page $page/$totalPages', name: 'DataService');
      }
      
      // STEP 2: Verify unsynced local records AFTER sync
      final unsyncedCountAfter = await trainingSiteRepo.getUnsyncedCount();
      final unsyncedRecordsAfter = await trainingSiteRepo.getUnsynced();
      developer.log('========================================', name: 'DataService');
      developer.log('AFTER SYNC: $unsyncedCountAfter unsynced local records', name: 'DataService');
      for (var record in unsyncedRecordsAfter) {
        developer.log('  Local record: ${record.trainingSite} (offline_id: ${record.offlineId}, s_is_sync: ${record.sIsSync})', name: 'DataService');
      }
      developer.log('========================================', name: 'DataService');
      
      // STEP 3: Check if any local records were lost
      if (unsyncedCountAfter < unsyncedCountBefore) {
        developer.log('========================================', name: 'DataService');
        developer.log('WARNING: Local records were lost during sync!', name: 'DataService');
        developer.log('Before: $unsyncedCountBefore, After: $unsyncedCountAfter', name: 'DataService');
        developer.log('Lost ${unsyncedCountBefore - unsyncedCountAfter} local records', name: 'DataService');
        developer.log('========================================', name: 'DataService');
        
        // Find which records were lost
        final lostRecords = unsyncedRecordsBefore.where((before) {
          return !unsyncedRecordsAfter.any((after) => 
            after.offlineId == before.offlineId || 
            (after.trainingSite == before.trainingSite && after.district == before.district)
          );
        }).toList();
        
        developer.log('Lost records:', name: 'DataService');
        for (var lost in lostRecords) {
          developer.log('  - ${lost.trainingSite} (offline_id: ${lost.offlineId})', name: 'DataService');
        }
        
        // Restore lost records
        if (lostRecords.isNotEmpty) {
          developer.log('Attempting to restore ${lostRecords.length} lost records...', name: 'DataService');
          await trainingSiteRepo.insertBulk(lostRecords);
          developer.log('Restored ${lostRecords.length} lost local records', name: 'DataService');
        }
      } else {
        developer.log('✅ All local unsynced records preserved during sync', name: 'DataService');
      }
      
      // Get final count to report accurate numbers
      final finalCount = await trainingSiteRepo.getCount();
      final finalSyncedCount = await trainingSiteRepo.getSyncedCount();
      
      developer.log('========================================', name: 'DataService');
      developer.log('SYNC SUMMARY:', name: 'DataService');
      developer.log('  Records from server: $totalRecords', name: 'DataService');
      developer.log('  Pages processed: $totalPages', name: 'DataService');
      developer.log('  Records processed: $totalProcessed', name: 'DataService');
      developer.log('  Records inserted/updated: $totalInserted', name: 'DataService');
      developer.log('  Final DB count: $finalCount', name: 'DataService');
      developer.log('  Final synced count: $finalSyncedCount', name: 'DataService');
      developer.log('  Local unsynced: $unsyncedCountAfter', name: 'DataService');
      developer.log('========================================', name: 'DataService');
      
      // Final progress update
      onProgress?.call('Sync completed', totalRecords, totalRecords);
      
      final result = {
        'totalProcessed': totalProcessed,
        'totalInserted': totalInserted,
        'totalPages': totalPages,
        'totalRecords': totalRecords,
        'finalCount': finalCount,
        'finalSyncedCount': finalSyncedCount,
        'localRecordsBefore': unsyncedCountBefore,
        'localRecordsAfter': unsyncedCountAfter,
        'localRecordsPreserved': unsyncedCountAfter >= unsyncedCountBefore,
      };
      
      developer.log('Successfully synced $totalProcessed training sites from $totalPages pages', name: 'DataService');
      
      return DataResponse(
        success: true,
        data: result,
        message: 'Successfully synced $totalProcessed training sites (stored: $finalSyncedCount)',
      );
    } catch (e) {
      developer.log('Error in complete training sites sync: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'Failed to sync training sites: $e',
      );
    }
  }

  /// Sync districts from server to local database
  Future<DataResponse<int>> syncDistrictsToLocal() async {
    try {
      developer.log('Syncing districts to local database...', name: 'DataService');
      
      final districtRepo = DistrictRepository();
      
      // Fetch districts from server
      final response = await getDistricts();
      
      if (!response.success || response.data == null) {
        return DataResponse(
          success: false,
          message: response.message ?? 'Failed to fetch districts from server',
        );
      }
      
      final districts = response.data!;
      
      if (districts.isNotEmpty) {
        // Clear existing districts and insert new ones
        await districtRepo.clearAll();
        await districtRepo.insertBulk(districts);
        developer.log('Successfully synced ${districts.length} districts to local database', name: 'DataService');
      }
      
      return DataResponse(
        success: true,
        data: districts.length,
        message: 'Successfully synced ${districts.length} districts',
      );
    } catch (e) {
      developer.log('Error syncing districts to local: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'Failed to sync districts: $e',
      );
    }
  }

  /// Sync authorities from server to local database
  Future<DataResponse<int>> syncAuthoritiesToLocal() async {
    try {
      developer.log('Syncing authorities to local database...', name: 'DataService');
      
      final authorityRepo = AuthorityRepository();
      
      // Fetch authorities from server
      final response = await getAuthorities();
      
      if (!response.success || response.data == null) {
        return DataResponse(
          success: false,
          message: response.message ?? 'Failed to fetch authorities from server',
        );
      }
      
      final authorities = response.data!;
      
      if (authorities.isNotEmpty) {
        // Clear existing authorities and insert new ones
        await authorityRepo.clearAll();
        await authorityRepo.insertBulk(authorities);
        developer.log('Successfully synced ${authorities.length} authorities to local database', name: 'DataService');
      }
      
      return DataResponse(
        success: true,
        data: authorities.length,
        message: 'Successfully synced ${authorities.length} authorities',
      );
    } catch (e) {
      developer.log('Error syncing authorities to local: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'Failed to sync authorities: $e',
      );
    }
  }

  /// Get districts from local database (offline support)
  Future<DataResponse<List<District>>> getDistrictsFromLocal() async {
    try {
      developer.log('Fetching districts from local database...', name: 'DataService');
      
      final districtRepo = DistrictRepository();
      final districts = await districtRepo.getAll();
      
      developer.log('Fetched ${districts.length} districts from local database', name: 'DataService');
      
      return DataResponse(
        success: true,
        data: districts,
        message: 'Districts fetched from local database',
      );
    } catch (e) {
      developer.log('Error fetching districts from local: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'Failed to fetch districts from local database: $e',
      );
    }
  }

  /// Get authorities from local database (offline support)
  Future<DataResponse<List<Authority>>> getAuthoritiesFromLocal() async {
    try {
      developer.log('Fetching authorities from local database...', name: 'DataService');
      
      final authorityRepo = AuthorityRepository();
      final authorities = await authorityRepo.getAll();
      
      developer.log('Fetched ${authorities.length} authorities from local database', name: 'DataService');
      
      return DataResponse(
        success: true,
        data: authorities,
        message: 'Authorities fetched from local database',
      );
    } catch (e) {
      developer.log('Error fetching authorities from local: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'Failed to fetch authorities from local database: $e',
      );
    }
  }

  /// Get districts with offline fallback
  /// Tries to fetch from server first, falls back to local database if offline
  Future<DataResponse<List<District>>> getDistrictsWithFallback() async {
    try {
      // Check network connectivity
      final hasConnection = await _checkConnectivity();
      
      if (hasConnection) {
        // Try to fetch from server
        final serverResponse = await getDistricts();
        
        if (serverResponse.success && serverResponse.data != null) {
          // Store in local database for offline use
          final districtRepo = DistrictRepository();
          await districtRepo.clearAll();
          await districtRepo.insertBulk(serverResponse.data!);
          
          return serverResponse;
        }
      }
      
      // Fallback to local database
      developer.log('Falling back to local database for districts', name: 'DataService');
      return await getDistrictsFromLocal();
    } catch (e) {
      developer.log('Error in getDistrictsWithFallback: $e', name: 'DataService');
      // Try local database as last resort
      return await getDistrictsFromLocal();
    }
  }

  /// Get authorities with offline fallback
  /// Tries to fetch from server first, falls back to local database if offline
  Future<DataResponse<List<Authority>>> getAuthoritiesWithFallback() async {
    try {
      // Check network connectivity
      final hasConnection = await _checkConnectivity();
      
      if (hasConnection) {
        // Try to fetch from server
        final serverResponse = await getAuthorities();
        
        if (serverResponse.success && serverResponse.data != null) {
          // Store in local database for offline use
          final authorityRepo = AuthorityRepository();
          await authorityRepo.clearAll();
          await authorityRepo.insertBulk(serverResponse.data!);
          
          return serverResponse;
        }
      }
      
      // Fallback to local database
      developer.log('Falling back to local database for authorities', name: 'DataService');
      return await getAuthoritiesFromLocal();
    } catch (e) {
      developer.log('Error in getAuthoritiesWithFallback: $e', name: 'DataService');
      // Try local database as last resort
      return await getAuthoritiesFromLocal();
    }
  }

  /// Get device timezone offset in format like "+05:30" or "-08:00"
  String _getDeviceTimezone() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    
    final hours = offset.inHours;
    final minutes = offset.inMinutes.remainder(60).abs();
    
    final sign = hours >= 0 ? '+' : '-';
    final hoursStr = hours.abs().toString().padLeft(2, '0');
    final minutesStr = minutes.toString().padLeft(2, '0');
    
    return '$sign$hoursStr:$minutesStr';
  }

  /// POST /training-site/update_data
  /// Fetches updated/synced training sites from server after a specific date
  /// Used for incremental sync after initial full sync
  Future<DataResponse<List<TrainingSite>>> getUpdatedTrainingSites(String lastSyncDate) async {
    try {
      final timezone = _getDeviceTimezone();
      
      developer.log('Fetching updated training sites since: $lastSyncDate', name: 'DataService');
      developer.log('Device timezone: $timezone', name: 'DataService');
      
      final response = await _dioClient.post(
        ApiConstants.updateData,
        data: {
          'date': lastSyncDate,
          'timezone': timezone,
        },
      );
      
      if (response.data != null) {
        List<TrainingSite> trainingSites = [];
        
        // Handle different response structures
        if (response.data is Map && response.data['data'] != null) {
          final data = response.data['data'];
          if (data is List) {
            trainingSites = data
                .map((json) => TrainingSite.fromJson(json))
                .toList();
          }
        } else if (response.data is List) {
          trainingSites = (response.data as List)
              .map((json) => TrainingSite.fromJson(json))
              .toList();
        }
        
        developer.log('Fetched ${trainingSites.length} updated training sites', name: 'DataService');
        
        return DataResponse(
          success: true,
          data: trainingSites,
          message: 'Updated training sites fetched successfully',
        );
      }
      
      return DataResponse(
        success: false,
        message: 'No data received',
      );
    } on DioException catch (e) {
      developer.log('Error fetching updated training sites: ${e.message}', name: 'DataService');
      return DataResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Failed to fetch updated training sites',
      );
    } catch (e) {
      developer.log('Unexpected error: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Sync updated training sites from server and store in local database
  /// This method is used for incremental sync after initial full sync
  Future<DataResponse<int>> syncUpdatedTrainingSites(String lastSyncDate) async {
    try {
      developer.log('Starting incremental sync for training sites...', name: 'DataService');
      
      final response = await getUpdatedTrainingSites(lastSyncDate);
      
      if (!response.success || response.data == null) {
        return DataResponse(
          success: false,
          message: response.message ?? 'Failed to fetch updated training sites',
        );
      }
      
      final trainingSites = response.data!;
      
      if (trainingSites.isNotEmpty) {
        final trainingSiteRepo = TrainingSiteRepository();
        
        // Mark all as synced since they come from server
        final sitesWithSyncStatus = trainingSites.map((site) => 
          site.copyWith(sIsSync: 1)
        ).toList();
        
        await trainingSiteRepo.insertBulk(sitesWithSyncStatus);
        developer.log('Successfully synced ${trainingSites.length} updated training sites', name: 'DataService');
      } else {
        developer.log('No updated training sites found', name: 'DataService');
      }
      
      return DataResponse(
        success: true,
        data: trainingSites.length,
        message: trainingSites.isEmpty 
            ? 'No new updates available' 
            : 'Successfully synced ${trainingSites.length} updated training sites',
      );
    } catch (e) {
      developer.log('Error syncing updated training sites: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'Failed to sync updated training sites: $e',
      );
    }
  }

  /// Verify that data has been fetched and persisted in local database
  /// Returns true if there are synced training sites in the database
  Future<DataResponse<bool>> verifyDataPersistence() async {
    try {
      developer.log('Verifying data persistence...', name: 'DataService');
      
      final trainingSiteRepo = TrainingSiteRepository();
      final syncedCount = await trainingSiteRepo.getSyncedCount();
      
      developer.log('Found $syncedCount synced training sites in local database', name: 'DataService');
      
      if (syncedCount > 0) {
        return DataResponse(
          success: true,
          data: true,
          message: 'Data verification successful. Found $syncedCount synced records.',
        );
      } else {
        return DataResponse(
          success: false,
          data: false,
          message: 'No synced data found in local database. Please sync data from the dashboard first.',
        );
      }
    } catch (e) {
      developer.log('Error verifying data persistence: $e', name: 'DataService');
      return DataResponse(
        success: false,
        data: false,
        message: 'Failed to verify data persistence: $e',
      );
    }
  }

  /// GET /training-site/lang_slug
  /// Fetches all languages
  Future<DataResponse<List<String>>> getLanguages() async {
    try {
      developer.log('Fetching languages...', name: 'DataService');
      
      final response = await _dioClient.get(ApiConstants.langSlug);
      
      if (response.data != null) {
        List<String> languages = [];
        
        if (response.data is Map && response.data['data'] != null) {
          final data = response.data['data'];
          if (data is List) {
            languages = data.map((item) => item['lang_name'] as String).toList();
          }
        } else if (response.data is List) {
          languages = (response.data as List).map((item) => item['lang_name'] as String).toList();
        }
        
        developer.log('Fetched ${languages.length} languages', name: 'DataService');
        
        return DataResponse(
          success: true,
          data: languages,
          message: 'Languages fetched successfully',
        );
      }
      
      return DataResponse(
        success: false,
        message: 'No data received',
      );
    } on DioException catch (e) {
      developer.log('Error fetching languages: ${e.message}', name: 'DataService');
      return DataResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Failed to fetch languages',
      );
    } catch (e) {
      developer.log('Unexpected error: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  /// GET /training-site/cookstove_slug
  /// Fetches all cookstoves
  Future<DataResponse<List<String>>> getCookstoves() async {
    try {
      developer.log('Fetching cookstoves...', name: 'DataService');
      
      final response = await _dioClient.get(ApiConstants.cookstoveSlug);
      
      if (response.data != null) {
        List<String> cookstoves = [];
        
        if (response.data is Map && response.data['data'] != null) {
          final data = response.data['data'];
          if (data is List) {
            cookstoves = data.map((item) => item['cookstove_name'] as String).toList();
          }
        } else if (response.data is List) {
          cookstoves = (response.data as List).map((item) => item['cookstove_name'] as String).toList();
        }
        
        developer.log('Fetched ${cookstoves.length} cookstoves', name: 'DataService');
        
        return DataResponse(
          success: true,
          data: cookstoves,
          message: 'Cookstoves fetched successfully',
        );
      }
      
      return DataResponse(
        success: false,
        message: 'No data received',
      );
    } on DioException catch (e) {
      developer.log('Error fetching cookstoves: ${e.message}', name: 'DataService');
      return DataResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Failed to fetch cookstoves',
      );
    } catch (e) {
      developer.log('Unexpected error: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  /// GET /training-site/getAllSites
  /// Fetches all training site names
  Future<DataResponse<List<String>>> getAllTrainingSiteNames() async {
    try {
      developer.log('Fetching all training site names...', name: 'DataService');
      
      final response = await _dioClient.get(ApiConstants.getAllSites);
      
      if (response.data != null) {
        List<String> trainingSites = [];
        
        // Handle response structure: {"message": "...", "data": [...]}
        if (response.data is Map && response.data['data'] != null) {
          final data = response.data['data'];
          if (data is List) {
            trainingSites = data.map((item) {
              if (item is Map && item['training_site'] != null) {
                return item['training_site'] as String;
              }
              return '';
            }).where((site) => site.isNotEmpty).toList();
          }
        } else if (response.data is List) {
          trainingSites = (response.data as List).map((item) {
            if (item is Map && item['training_site'] != null) {
              return item['training_site'] as String;
            }
            return '';
          }).where((site) => site.isNotEmpty).toList();
        }
        
        developer.log('Fetched ${trainingSites.length} training site names', name: 'DataService');
        
        return DataResponse(
          success: true,
          data: trainingSites,
          message: 'Training site names fetched successfully',
        );
      }
      
      return DataResponse(
        success: false,
        message: 'No data received',
      );
    } on DioException catch (e) {
      developer.log('Error fetching training site names: ${e.message}', name: 'DataService');
      return DataResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Failed to fetch training site names',
      );
    } catch (e) {
      developer.log('Unexpected error: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Sync languages from server to local database
  Future<DataResponse<int>> syncLanguagesToLocal() async {
    try {
      developer.log('Syncing languages to local database...', name: 'DataService');
      
      final response = await getLanguages();
      
      if (!response.success || response.data == null) {
        return DataResponse(
          success: false,
          message: response.message ?? 'Failed to fetch languages from server',
        );
      }
      
      final languages = response.data!;
      
      if (languages.isNotEmpty) {
        final languageRepo = LanguageRepository();
        await languageRepo.deleteAll();
        
        for (var langName in languages) {
          await languageRepo.insert(Language(langName: langName));
        }
        
        developer.log('Successfully synced ${languages.length} languages to local database', name: 'DataService');
      }
      
      return DataResponse(
        success: true,
        data: languages.length,
        message: 'Successfully synced ${languages.length} languages',
      );
    } catch (e) {
      developer.log('Error syncing languages to local: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'Failed to sync languages: $e',
      );
    }
  }

  /// Sync cookstoves from server to local database
  Future<DataResponse<int>> syncCookstovesToLocal() async {
    try {
      developer.log('Syncing cookstoves to local database...', name: 'DataService');
      
      final response = await getCookstoves();
      
      if (!response.success || response.data == null) {
        return DataResponse(
          success: false,
          message: response.message ?? 'Failed to fetch cookstoves from server',
        );
      }
      
      final cookstoves = response.data!;
      
      if (cookstoves.isNotEmpty) {
        final cookstoveRepo = CookstoveRepository();
        await cookstoveRepo.deleteAll();
        
        for (var cookstoveName in cookstoves) {
          await cookstoveRepo.insert(Cookstove(cookstoveName: cookstoveName));
        }
        
        developer.log('Successfully synced ${cookstoves.length} cookstoves to local database', name: 'DataService');
      }
      
      return DataResponse(
        success: true,
        data: cookstoves.length,
        message: 'Successfully synced ${cookstoves.length} cookstoves',
      );
    } catch (e) {
      developer.log('Error syncing cookstoves to local: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'Failed to sync cookstoves: $e',
      );
    }
  }

  /// Sync training site names from server to local database
  Future<DataResponse<int>> syncTrainingSiteNamesToLocal() async {
    try {
      developer.log('Syncing training site names to local database...', name: 'DataService');
      
      final response = await getAllTrainingSiteNames();
      
      if (!response.success || response.data == null) {
        return DataResponse(
          success: false,
          message: response.message ?? 'Failed to fetch training site names from server',
        );
      }
      
      final trainingSites = response.data!;
      
      if (trainingSites.isNotEmpty) {
        final trainingSiteListRepo = TrainingSiteListRepository();
        await trainingSiteListRepo.deleteAll();
        
        for (var siteName in trainingSites) {
          await trainingSiteListRepo.insert(TrainingSiteList(trainingSite: siteName));
        }
        
        developer.log('Successfully synced ${trainingSites.length} training site names to local database', name: 'DataService');
      }
      
      return DataResponse(
        success: true,
        data: trainingSites.length,
        message: 'Successfully synced ${trainingSites.length} training site names',
      );
    } catch (e) {
      developer.log('Error syncing training site names to local: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'Failed to sync training site names: $e',
      );
    }
  }

  /// POST /beneficiary/sync
  /// Syncs beneficiaries to server and updates with server-assigned beneficiary_id
  Future<DataResponse<Map<String, dynamic>>> syncBeneficiariesToServer() async {
    try {
      developer.log('Syncing beneficiaries to server...', name: 'DataService');
      
      // CRITICAL: Check if ALL training sites are synced before allowing beneficiary sync
      final trainingSiteRepo = TrainingSiteRepository();
      final allSynced = await trainingSiteRepo.areAllTrainingSitesSynced();
      
      if (!allSynced) {
        developer.log('Cannot sync beneficiaries: Not all training sites are synced', name: 'DataService');
        return DataResponse(
          success: false,
          message: 'Cannot sync beneficiaries. Please sync all training sites first from the Conduct Training screen.',
        );
      }
      
      developer.log('✅ All training sites are synced, proceeding with beneficiary sync', name: 'DataService');
      
      final beneficiaryRepo = BeneficiaryRepository();
      final unsyncedBeneficiaries = await beneficiaryRepo.getUnsynced();
      
      if (unsyncedBeneficiaries.isEmpty) {
        developer.log('No unsynced beneficiaries to sync', name: 'DataService');
        return DataResponse(
          success: true,
          data: {'synced': 0},
          message: 'No beneficiaries to sync',
        );
      }
      
      developer.log('Found ${unsyncedBeneficiaries.length} unsynced beneficiaries', name: 'DataService');
      
      // Convert to JSON for sync (excludes national_id)
      final beneficiariesJson = unsyncedBeneficiaries.map((b) => b.toJsonForSync()).toList();
      
      developer.log('Sending beneficiaries to server...', name: 'DataService');
      
      final response = await _dioClient.post(
        ApiConstants.beneficiarySync,
        data: {'beneficiaries': beneficiariesJson},
      );
      
      if (response.data != null) {
        developer.log('Server response received', name: 'DataService');
        
        // Parse response to get beneficiary_id mappings
        // Expected response format: { "data": [{ "offline_id": 1, "beneficiary_id": 123 }, ...] }
        final responseData = response.data;
        int syncedCount = 0;
        
        if (responseData is Map && responseData['data'] != null) {
          final mappings = responseData['data'] as List;
          
          for (var mapping in mappings) {
            final offlineId = mapping['offline_id'] as int?;
            final beneficiaryId = mapping['beneficiary_id'] as int?;
            
            if (offlineId != null && beneficiaryId != null) {
              // Update local record with server-assigned beneficiary_id
              await beneficiaryRepo.updateWithServerId(offlineId, beneficiaryId);
              syncedCount++;
              developer.log('Updated beneficiary offline_id=$offlineId with beneficiary_id=$beneficiaryId', name: 'DataService');
            }
          }
        }
        
        developer.log('Successfully synced $syncedCount beneficiaries', name: 'DataService');
        
        return DataResponse(
          success: true,
          data: {'synced': syncedCount},
          message: 'Successfully synced $syncedCount beneficiaries',
        );
      }
      
      return DataResponse(
        success: false,
        message: 'No response from server',
      );
    } on DioException catch (e) {
      developer.log('Error syncing beneficiaries: ${e.message}', name: 'DataService');
      return DataResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Failed to sync beneficiaries',
      );
    } catch (e) {
      developer.log('Unexpected error syncing beneficiaries: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'An unexpected error occurred: $e',
      );
    }
  }

  /// GET /beneficiary/list with pagination
  /// Fetches beneficiaries from server with pagination support
  Future<DataResponse<PaginatedResponse<Map<String, dynamic>>>> getBeneficiaryListPaginated({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      developer.log('Fetching paginated beneficiary list - page: $page, limit: $limit', name: 'DataService');
      
      final response = await _dioClient.post(
        ApiConstants.beneficiaryList,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      
      if (response.data != null) {
        final paginatedResponse = PaginatedResponse<Map<String, dynamic>>.fromJson(
          response.data,
          (json) => json,
        );
        
        developer.log(
          'Fetched ${paginatedResponse.data.length} beneficiaries (page $page/${paginatedResponse.totalPages})',
          name: 'DataService',
        );
        
        return DataResponse(
          success: true,
          data: paginatedResponse,
          message: 'Beneficiaries fetched successfully',
        );
      }
      
      return DataResponse(
        success: false,
        message: 'No data received',
      );
    } on DioException catch (e) {
      developer.log('Error fetching paginated beneficiary list: ${e.message}', name: 'DataService');
      return DataResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Failed to fetch beneficiaries',
      );
    } catch (e) {
      developer.log('Unexpected error: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Fetch all beneficiaries by iterating through all pages and store in local database
  Future<DataResponse<List<Map<String, dynamic>>>> getAllBeneficiariesPaginated({
    int limit = 50,
    Function(int currentRecords, int totalRecords)? onProgress,
    bool storeInDatabase = true,
  }) async {
    try {
      developer.log('Starting to fetch all beneficiaries with pagination', name: 'DataService');
      
      List<Map<String, dynamic>> allBeneficiaries = [];
      int currentPage = 1;
      int totalPages = 1;
      int totalRecords = 0;
      
      // STEP 1: If storing in database, backup unsynced local records
      List<Beneficiary> unsyncedBackup = [];
      if (storeInDatabase) {
        final beneficiaryRepo = BeneficiaryRepository();
        unsyncedBackup = await beneficiaryRepo.getUnsynced();
        developer.log('Backed up ${unsyncedBackup.length} unsynced local records before sync', name: 'DataService');
      }
      
      do {
        final response = await getBeneficiaryListPaginated(page: currentPage, limit: limit);
        
        if (!response.success || response.data == null) {
          return DataResponse(
            success: false,
            message: response.message ?? 'Failed to fetch beneficiaries',
          );
        }
        
        final paginatedData = response.data!;
        allBeneficiaries.addAll(paginatedData.data);
        totalPages = paginatedData.totalPages;
        totalRecords = paginatedData.totalRecords;
        
        // Call progress callback with cumulative records downloaded and total records
        onProgress?.call(allBeneficiaries.length, totalRecords);
        
        developer.log(
          'Fetched page $currentPage/$totalPages (${paginatedData.data.length} items)',
          name: 'DataService',
        );
        
        currentPage++;
      } while (currentPage <= totalPages);
      
      developer.log(
        'Successfully fetched all ${allBeneficiaries.length} beneficiaries from $totalPages pages',
        name: 'DataService',
      );
      
      // Store in local database if requested
      if (storeInDatabase && allBeneficiaries.isNotEmpty) {
        try {
          final beneficiaryRepo = BeneficiaryRepository();
          
          // Convert to Beneficiary objects and mark all as synced since they come from server
          List<Beneficiary> beneficiariesToInsert = [];
          int skippedCount = 0;
          
          for (var i = 0; i < allBeneficiaries.length; i++) {
            final beneficiaryData = allBeneficiaries[i];
            try {
              final beneficiary = Beneficiary.fromJson(beneficiaryData);
              final beneficiaryWithSyncStatus = beneficiary.copyWith(sIsSync: 1);
              beneficiariesToInsert.add(beneficiaryWithSyncStatus);
            } catch (e, stackTrace) {
              developer.log('Error parsing beneficiary $i: $e', name: 'DataService');
              developer.log('Stack trace: $stackTrace', name: 'DataService');
              developer.log('Problematic data: $beneficiaryData', name: 'DataService');
              skippedCount++;
              // Continue with next beneficiary - don't let one bad record stop the entire sync
            }
          }
          
          developer.log('========================================', name: 'DataService');
          developer.log('Beneficiary Parsing Summary:', name: 'DataService');
          developer.log('Total fetched: ${allBeneficiaries.length}', name: 'DataService');
          developer.log('Successfully parsed: ${beneficiariesToInsert.length}', name: 'DataService');
          developer.log('Skipped/Failed: $skippedCount', name: 'DataService');
          developer.log('========================================', name: 'DataService');
          
          // Use bulk insert for better performance and reliability
          if (beneficiariesToInsert.isNotEmpty) {
            await beneficiaryRepo.insertBulk(beneficiariesToInsert);
            developer.log('Stored ${beneficiariesToInsert.length} beneficiaries in local database (marked as synced)', name: 'DataService');
          } else {
            developer.log('WARNING: No beneficiaries to insert after parsing!', name: 'DataService');
          }
          
          // STEP 2: Verify unsynced records are still there
          final unsyncedCountAfter = await beneficiaryRepo.getUnsyncedCount();
          developer.log('After sync: $unsyncedCountAfter unsynced local records', name: 'DataService');
          
          if (unsyncedCountAfter < unsyncedBackup.length) {
            developer.log('WARNING: Some local records were lost! Restoring...', name: 'DataService');
            // Restore lost records
            await beneficiaryRepo.insertBulk(unsyncedBackup);
            developer.log('Restored ${unsyncedBackup.length} local records', name: 'DataService');
          } else {
            developer.log('✅ All local unsynced records preserved', name: 'DataService');
          }
        } catch (e, stackTrace) {
          developer.log('Error storing beneficiaries in database: $e', name: 'DataService');
          developer.log('Stack trace: $stackTrace', name: 'DataService');
          // Don't fail the entire operation if database storage fails
        }
      }
      
      return DataResponse(
        success: true,
        data: allBeneficiaries,
        message: 'All beneficiaries fetched successfully',
      );
    } catch (e) {
      developer.log('Error fetching all beneficiaries: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'Failed to fetch all beneficiaries: $e',
      );
    }
  }

  /// POST /beneficiary/list (legacy method for incremental sync)
  /// Fetches beneficiaries from server with optional last sync date for incremental sync
  Future<DataResponse<List<Map<String, dynamic>>>> getBeneficiaryList({String? lastSyncDate}) async {
    try {
      developer.log('Fetching beneficiary list from server...', name: 'DataService');
      
      final payload = <String, dynamic>{};
      if (lastSyncDate != null) {
        payload['last_sync_date'] = lastSyncDate;
        developer.log('Incremental sync from: $lastSyncDate', name: 'DataService');
      } else {
        developer.log('Full sync - fetching all beneficiaries', name: 'DataService');
      }
      
      final response = await _dioClient.post(
        ApiConstants.beneficiaryList,
        data: payload,
      );
      
      if (response.data != null) {
        List<Map<String, dynamic>> beneficiaries = [];
        
        // Handle different response structures
        if (response.data is Map && response.data['data'] != null) {
          final data = response.data['data'];
          if (data is List) {
            beneficiaries = data.cast<Map<String, dynamic>>();
          }
        } else if (response.data is List) {
          beneficiaries = (response.data as List).cast<Map<String, dynamic>>();
        }
        
        developer.log('Fetched ${beneficiaries.length} beneficiaries from server', name: 'DataService');
        
        return DataResponse(
          success: true,
          data: beneficiaries,
          message: 'Beneficiaries fetched successfully',
        );
      }
      
      return DataResponse(
        success: false,
        message: 'No data received',
      );
    } on DioException catch (e) {
      developer.log('Error fetching beneficiary list: ${e.message}', name: 'DataService');
      return DataResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Failed to fetch beneficiaries',
      );
    } catch (e) {
      developer.log('Unexpected error fetching beneficiary list: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'An unexpected error occurred: $e',
      );
    }
  }

  /// Sync beneficiaries from server to local database
  Future<DataResponse<int>> syncBeneficiariesFromServer({
    Function(int current, int total)? onProgress,
  }) async {
    try {
      developer.log('Starting beneficiary sync from server...', name: 'DataService');
      
      final beneficiaryRepo = BeneficiaryRepository();
      
      // Get last sync time from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final lastSyncTimestamp = prefs.getString('last_beneficiary_sync');
      
      // Fetch beneficiaries from server (incremental if we have last sync time)
      final response = await getBeneficiaryList(
        lastSyncDate: lastSyncTimestamp,
      );
      
      if (!response.success || response.data == null) {
        return DataResponse(
          success: false,
          message: response.message ?? 'Failed to fetch beneficiaries from server',
        );
      }
      
      final beneficiariesData = response.data!;
      
      if (beneficiariesData.isEmpty) {
        developer.log('No new beneficiaries to sync', name: 'DataService');
        return DataResponse(
          success: true,
          data: 0,
          message: 'No new beneficiaries to sync',
        );
      }
      
      // Report progress
      onProgress?.call(0, beneficiariesData.length);
      
      // Convert to Beneficiary objects and store in local database
      int syncedCount = 0;
      for (var i = 0; i < beneficiariesData.length; i++) {
        try {
          final beneficiaryData = beneficiariesData[i];
          
          // Create Beneficiary object from server data
          // Note: Server data should already have beneficiary_id
          final beneficiary = Beneficiary.fromJson(beneficiaryData);
          
          // Mark as synced since it comes from server
          final beneficiaryWithSyncStatus = beneficiary.copyWith(sIsSync: 1);
          
          // Insert or update in local database
          await beneficiaryRepo.insert(beneficiaryWithSyncStatus);
          syncedCount++;
          
          // Report progress
          onProgress?.call(syncedCount, beneficiariesData.length);
        } catch (e) {
          developer.log('Error processing beneficiary: $e', name: 'DataService');
          // Continue with next beneficiary
        }
      }
      
      developer.log('Successfully synced $syncedCount beneficiaries to local database', name: 'DataService');
      
      return DataResponse(
        success: true,
        data: syncedCount,
        message: 'Successfully synced $syncedCount beneficiaries',
      );
    } catch (e) {
      developer.log('Error syncing beneficiaries from server: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'Failed to sync beneficiaries: $e',
      );
    }
  }

  /// POST /beneficiary/bene_sync
  /// Syncs beneficiary data to server (alternative sync endpoint)
  /// Uses FormData to support file uploads (images)
  Future<DataResponse<Map<String, dynamic>>> beneficiaryBeneSync({
    required List<Map<String, dynamic>> beneficiaries,
  }) async {
    try {
      developer.log('Syncing beneficiaries via bene_sync endpoint...', name: 'DataService');
      developer.log('Sending ${beneficiaries.length} beneficiaries', name: 'DataService');
      
      // Create FormData
      final formData = FormData();
      
      // Determine if we're sending single or multiple beneficiaries
      final isSingleBeneficiary = beneficiaries.length == 1;
      
      // Process each beneficiary
      for (int i = 0; i < beneficiaries.length; i++) {
        final beneficiary = beneficiaries[i];
        
        // Add all non-file fields
        beneficiary.forEach((key, value) {
          if (value != null) {
            // Check if this is a file path field
            if (key == 'national_id_attachment' || 
                key == 'house_pic' || 
                key == 'cookstove_pic' || 
                key == 'signature') {
              // Handle file upload
              final filePath = value.toString();
              if (filePath.isNotEmpty && File(filePath).existsSync()) {
                developer.log('Adding file for $key: $filePath', name: 'DataService');
                
                // Use flat format for single beneficiary, array format for multiple
                final fieldName = isSingleBeneficiary 
                    ? key 
                    : 'beneficiaries[$i][$key]';
                
                formData.files.add(MapEntry(
                  fieldName,
                  MultipartFile.fromFileSync(
                    filePath,
                    filename: filePath.split('/').last,
                  ),
                ));
              }
            } else {
              // Add regular field
              // Use flat format for single beneficiary, array format for multiple
              final fieldName = isSingleBeneficiary 
                  ? key 
                  : 'beneficiaries[$i][$key]';
              
              formData.fields.add(MapEntry(
                fieldName,
                value.toString(),
              ));
            }
          }
        });
      }
      
      developer.log('========================================', name: 'DataService');
      developer.log('FormData prepared with ${formData.fields.length} fields and ${formData.files.length} files', name: 'DataService');
      
      // Log ALL fields for debugging
      if (formData.fields.isNotEmpty) {
        developer.log('--- FormData Fields (${formData.fields.length}) ---', name: 'DataService');
        for (var field in formData.fields) {
          developer.log('  ${field.key} = ${field.value}', name: 'DataService');
        }
      }
      
      // Log ALL files for debugging
      if (formData.files.isNotEmpty) {
        developer.log('--- FormData Files (${formData.files.length}) ---', name: 'DataService');
        for (var file in formData.files) {
          developer.log('  ${file.key} = ${file.value.filename}', name: 'DataService');
        }
      }
      developer.log('========================================', name: 'DataService');
      
      final response = await _dioClient.post(
        ApiConstants.beneficiaryBeneSync,
        data: formData,
      );
      
      if (response.data != null) {
        developer.log('Beneficiary bene_sync response received', name: 'DataService');
        
        // Parse response
        final responseData = response.data;
        
        // Expected response format: { "success": true, "message": "...", "data": {...} }
        return DataResponse(
          success: true,
          data: responseData is Map<String, dynamic> ? responseData : {},
          message: responseData['message'] ?? 'Beneficiaries synced successfully',
        );
      }
      
      return DataResponse(
        success: false,
        message: 'No response from server',
      );
    } on DioException catch (e) {
      developer.log('Error in beneficiary bene_sync: ${e.message}', name: 'DataService');
      developer.log('Response data: ${e.response?.data}', name: 'DataService');
      return DataResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Failed to sync beneficiaries',
      );
    } catch (e) {
      developer.log('Unexpected error in beneficiary bene_sync: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'An unexpected error occurred: $e',
      );
    }
  }

  /// POST /beneficiary/Beneficiary_data
  /// Fetches updated/synced beneficiaries from server after a specific date
  /// Used for incremental sync after initial full sync (similar to training site update_data)
  Future<DataResponse<List<Beneficiary>>> getUpdatedBeneficiaries(String lastSyncDate) async {
    try {
      final timezone = _getDeviceTimezone();
      
      developer.log('Fetching updated beneficiaries since: $lastSyncDate', name: 'DataService');
      developer.log('Device timezone: $timezone', name: 'DataService');
      
      final response = await _dioClient.post(
        ApiConstants.beneficiaryData,
        data: {
          'date': lastSyncDate,
          'timezone': timezone,
        },
      );
      
      if (response.data != null) {
        List<Beneficiary> beneficiaries = [];
        
        // Handle different response structures
        if (response.data is Map && response.data['data'] != null) {
          final data = response.data['data'];
          if (data is List) {
            beneficiaries = data
                .map((json) => Beneficiary.fromJson(json))
                .toList();
          }
        } else if (response.data is List) {
          beneficiaries = (response.data as List)
              .map((json) => Beneficiary.fromJson(json))
              .toList();
        }
        
        developer.log('Fetched ${beneficiaries.length} updated beneficiaries', name: 'DataService');
        
        return DataResponse(
          success: true,
          data: beneficiaries,
          message: 'Updated beneficiaries fetched successfully',
        );
      }
      
      return DataResponse(
        success: false,
        message: 'No data received',
      );
    } on DioException catch (e) {
      developer.log('Error fetching updated beneficiaries: ${e.message}', name: 'DataService');
      return DataResponse(
        success: false,
        message: e.response?.data['message'] ?? e.message ?? 'Failed to fetch updated beneficiaries',
      );
    } catch (e) {
      developer.log('Unexpected error: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Sync updated beneficiaries from server and store in local database
  /// This method is used for incremental sync after initial full sync
  Future<DataResponse<int>> syncUpdatedBeneficiaries(String lastSyncDate) async {
    try {
      developer.log('Starting incremental sync for beneficiaries...', name: 'DataService');
      
      final response = await getUpdatedBeneficiaries(lastSyncDate);
      
      if (!response.success || response.data == null) {
        return DataResponse(
          success: false,
          message: response.message ?? 'Failed to fetch updated beneficiaries',
        );
      }
      
      final beneficiaries = response.data!;
      
      if (beneficiaries.isNotEmpty) {
        final beneficiaryRepo = BeneficiaryRepository();
        
        // Mark all as synced since they come from server
        final beneficiariesWithSyncStatus = beneficiaries.map((beneficiary) => 
          beneficiary.copyWith(sIsSync: 1)
        ).toList();
        
        for (var beneficiary in beneficiariesWithSyncStatus) {
          await beneficiaryRepo.insert(beneficiary);
        }
        
        developer.log('Successfully synced ${beneficiaries.length} updated beneficiaries', name: 'DataService');
      } else {
        developer.log('No updated beneficiaries found', name: 'DataService');
      }
      
      return DataResponse(
        success: true,
        data: beneficiaries.length,
        message: beneficiaries.isEmpty 
            ? 'No new updates available' 
            : 'Successfully synced ${beneficiaries.length} updated beneficiaries',
      );
    } catch (e) {
      developer.log('Error syncing updated beneficiaries: $e', name: 'DataService');
      return DataResponse(
        success: false,
        message: 'Failed to sync updated beneficiaries: $e',
      );
    }
  }
}

/// Generic response wrapper for API calls
class DataResponse<T> {
  final bool success;
  final T? data;
  final String? message;

  DataResponse({
    required this.success,
    this.data,
    this.message,
  });
}
