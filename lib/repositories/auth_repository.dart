// lib/repositories/auth_repository.dart

import '../models/user_model.dart';
import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../services/dio_client.dart';
import '../services/secure_storage_service.dart';
import '../services/socket_client.dart'; // <-- 1. IMPORT SOCKET CLIENT
import '../shared/exceptions.dart';
import '../services/locator.dart'; // <-- 2. IMPORT THE SERVICE LOCATOR
import 'user_repository.dart';

class AuthRepository {
  // 3. GET DEPENDENCIES FROM THE SERVICE LOCATOR INSTEAD OF DIRECTLY
  final Dio _dio = sl<DioClient>().dio;
  final SecureStorageService _storageService = sl<SecureStorageService>();
  final SocketClient _socketClient = sl<SocketClient>();
  final UserRepository _userRepository = sl<UserRepository>();

  Future<User> login(String username, String password) async {
    try {
      // ... (the try block remains the same)
      final response = await _dio.post(ApiEndPoints.authLogIn, data: {
        'user_name': username, 'password': password,
      });

      if (response.statusCode == 200 && response.data['token'] != null) {
        await _storageService.saveToken(response.data['token']);
        await _socketClient.connectAndListen();

        final user = await _userRepository.getMe();
        _socketClient.registerPresence(user);

        return user;
      } else {
        throw AuthException('Login failed: Invalid response from server.');
      }

    } on DioException catch (e) {
      // Let's create a helper to handle Dio errors cleanly
      throw _handleDioError(e);
    } catch (e) {
      // Catch any other unexpected errors
      throw ServerException('An unexpected error occurred: $e');
    }
  }

  AppException _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      // Return the exception instead of throwing it
      return NetworkException('Please check your internet connection.');
    }

    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final errorMessage = e.response!.data['error'] ?? 'An error occurred.';
      if (statusCode == 401 || statusCode == 404) {
        // Return the exception
        return AuthException(errorMessage);
      }
    }

    // Return a default server exception
    return ServerException('An unexpected server error occurred.');
  }

  Future<void> logout() async {
    // 5. DISCONNECT THE SOCKET ON LOGOUT
    _socketClient.disconnect();
    await _storageService.deleteToken();
  }

  Future<String?> getToken() async {
    return await _storageService.getToken();
  }
}