// Test file to verify AuthRequest JSON format
import 'package:irise/data/models/auth_request.dart';
import 'dart:convert';

void testAuthRequest() {
  final authRequest = AuthRequest(
    username: 'userexample',
    password: '123456',
  );

  final json = authRequest.toJson();
  print('Login request body:');
  print(jsonEncode(json));
  
  // Expected output:
  // {"validemail":"userexample","validPass":"123456"}
}