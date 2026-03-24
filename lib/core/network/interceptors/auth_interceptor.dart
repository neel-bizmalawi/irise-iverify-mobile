import 'package:dio/dio.dart';
import 'package:irise/core/storage/token_storage.dart';
import 'package:irise/core/constants/api_constants.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage = TokenStorage();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip adding token for login endpoint
    if (options.path == ApiConstants.verifyUser) {
      handler.next(options);
      return;
    }

    // Get token from storage for other endpoints
    final token = await _tokenStorage.getToken();

    // Add token to headers if available
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized errors
    if (err.response?.statusCode == 401) {
      // Clear token on unauthorized (except for login endpoint)
      if (err.requestOptions.path != ApiConstants.verifyUser) {
        await _tokenStorage.clearToken();
      }
    }

    handler.next(err);
  }
}
