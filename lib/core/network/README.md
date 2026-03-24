# API Integration Documentation

## Overview
This project uses Dio for HTTP requests with automatic token management through interceptors.

## Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── api_constants.dart          # API endpoints and configuration
│   ├── network/
│   │   ├── dio_client.dart             # Dio singleton with interceptors
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart   # Automatic token injection
│   │       └── logging_interceptor.dart # Request/response logging
│   └── storage/
│       └── token_storage.dart          # Token persistence
├── data/
│   ├── models/
│   │   ├── auth_request.dart           # Login request model
│   │   └── auth_response.dart          # Login response model
│   └── services/
│       └── auth_service.dart           # Authentication API calls
└── providers/
    └── auth_provider.dart              # State management for auth
```

## Features

### 1. Automatic Token Injection
The `AuthInterceptor` automatically adds the Bearer token to all API requests:
- Retrieves token from SharedPreferences
- Adds `Authorization: Bearer <token>` header
- Handles 401 errors by clearing invalid tokens

### 2. Request/Response Logging
The `LoggingInterceptor` logs all network activity for debugging:
- Request method, URL, headers, and body
- Response status and data
- Error details

### 3. Centralized API Client
The `DioClient` singleton provides:
- Consistent base URL configuration
- Timeout settings
- Standard headers
- Convenient methods: get(), post(), put(), delete()

## Usage

### Making API Calls

```dart
// In a service class
final response = await DioClient.instance.post(
  '/endpoint',
  data: {'key': 'value'},
);
```

### Adding New Endpoints

1. Add endpoint to `api_constants.dart`:
```dart
static const String newEndpoint = '/new-endpoint';
```

2. Create a service method:
```dart
Future<Response> fetchData() async {
  return await DioClient.instance.get(ApiConstants.newEndpoint);
}
```

### Token Management

Tokens are automatically:
- Saved after successful login
- Added to all requests
- Cleared on logout or 401 errors

## Configuration

Base URL: `http://192.168.0.106:3000`
Timeout: 30 seconds

To change the base URL, edit `lib/core/constants/api_constants.dart`.
