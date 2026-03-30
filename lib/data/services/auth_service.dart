import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:irise/core/constants/api_constants.dart';
import 'package:irise/core/network/dio_client.dart';
import 'package:irise/core/storage/token_storage.dart';
import 'package:irise/data/models/auth_request.dart';
import 'package:irise/data/models/auth_response.dart';
import 'package:irise/data/services/data_service.dart';
import 'dart:developer' as developer;

class AuthService {
  final DioClient _dioClient = DioClient.instance;
  final TokenStorage _tokenStorage = TokenStorage();
  final DataService _dataService = DataService();

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    try {
      final authRequest = AuthRequest(
        username: username,
        password: password,
      );

      final response = await _dioClient.post(
        ApiConstants.verifyUser,
        data: authRequest.toJson(),
      );

      // Check if response is successful (200 or 201)
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        // Ensure response.data is a Map
        Map<String, dynamic> responseData;
        if (response.data is String) {
          responseData = json.decode(response.data);
        } else if (response.data is Map<String, dynamic>) {
          responseData = response.data;
        } else {
          print('AuthService: Unexpected response data type: ${response.data.runtimeType}');
          return false;
        }
        
        print('AuthService: Response data keys: ${responseData.keys.toList()}');
        print('AuthService: AccessTokenss value: ${responseData['AccessTokenss']}');
        
        final authResponse = AuthResponse.fromJson(responseData);
        
        print('AuthService: Parsed accessToken: ${authResponse.accessToken}');
        print('AuthService: accessToken != null: ${authResponse.accessToken != null}');
        print('AuthService: accessToken.isNotEmpty: ${authResponse.accessToken?.isNotEmpty}');

        // Save token and user data if login successful
        if (authResponse.accessToken != null && authResponse.accessToken!.isNotEmpty) {
          await _tokenStorage.saveToken(authResponse.accessToken!);
          
          if (authResponse.refreshToken != null) {
            await _tokenStorage.saveRefreshToken(authResponse.refreshToken!);
          }
          
          if (authResponse.user != null) {
            final user = authResponse.user!;
            if (user.id != null) {
              await _tokenStorage.saveUserId(user.id!);
            }
            if (user.email != null) {
              await _tokenStorage.saveUserEmail(user.email!);
            }
            if (user.name != null) {
              await _tokenStorage.saveUserName(user.name!);
            }
          }
          
          // Sync lookup data (languages, cookstoves, training sites) after successful login
          await _syncLookupData();
          
          print('AuthService: Login successful, returning true');
          return true;
        } else {
          print('AuthService: Access token is null or empty');
        }
      } else {
        print('AuthService: Invalid response status or data');
      }
      return false;
    } on DioException catch (e) {
      print('AuthService: DioException: ${e.message}');
      // Handle specific error responses
      if (e.response?.statusCode == 401) {
        // Invalid credentials
        return false;
      }
      return false;
    } catch (e) {
      print('AuthService: General exception: $e');
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    await _tokenStorage.clearToken();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _tokenStorage.isLoggedIn();
  }

  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final userId = await _tokenStorage.getUserId();
    final email = await _tokenStorage.getUserEmail();
    final name = await _tokenStorage.getUserName();
    
    if (userId != null) {
      return {
        'id': userId,
        'email': email,
        'name': name,
      };
    }
    return null;
  }

  /// Sync lookup data (languages, cookstoves, training sites) after login
  /// This ensures dropdown data is available for beneficiary registration
  Future<void> _syncLookupData() async {
    try {
      developer.log('========================================', name: 'AuthService');
      developer.log('Syncing lookup data after login...', name: 'AuthService');
      developer.log('========================================', name: 'AuthService');
      
      // Sync all lookup data in parallel
      final results = await Future.wait([
        _dataService.syncLanguagesToLocal(),
        _dataService.syncCookstovesToLocal(),
        _dataService.syncTrainingSiteNamesToLocal(),
      ]);
      
      final languagesResult = results[0];
      final cookstovesResult = results[1];
      final trainingSitesResult = results[2];
      
      if (languagesResult.success) {
        developer.log('✅ Synced ${languagesResult.data ?? 0} languages', name: 'AuthService');
      } else {
        developer.log('⚠️ Failed to sync languages: ${languagesResult.message}', name: 'AuthService');
      }
      
      if (cookstovesResult.success) {
        developer.log('✅ Synced ${cookstovesResult.data ?? 0} cookstoves', name: 'AuthService');
      } else {
        developer.log('⚠️ Failed to sync cookstoves: ${cookstovesResult.message}', name: 'AuthService');
      }
      
      if (trainingSitesResult.success) {
        developer.log('✅ Synced ${trainingSitesResult.data ?? 0} training site names', name: 'AuthService');
      } else {
        developer.log('⚠️ Failed to sync training site names: ${trainingSitesResult.message}', name: 'AuthService');
      }
      
      developer.log('========================================', name: 'AuthService');
    } catch (e) {
      developer.log('Error syncing lookup data: $e', name: 'AuthService');
      // Don't fail login if lookup data sync fails
    }
  }
}