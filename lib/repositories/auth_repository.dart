// lib/repositories/auth_repository.dart

import '../models/user_model.dart';
import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../services/dio_client.dart';
import '../services/secure_storage_service.dart';
import '../services/socket_client.dart';
import '../shared/exceptions.dart';
import '../services/locator.dart';
import '../services/password_service.dart';
import 'user_repository.dart';
import 'package:provider/provider.dart';
import '../view_models/call/call_viewmodel.dart';
import '../view_models/user_provider.dart';
import 'package:flutter/material.dart';

class AuthRepository {
  final Dio _dio = sl<DioClient>().dio;
  final SecureStorageService _storageService = sl<SecureStorageService>();
  final SocketClient _socketClient = sl<SocketClient>();
  final UserRepository _userRepository = sl<UserRepository>();

  Future<User> login(String username, String password) async {
    try {
      // Hash the password before sending to server
      final hashedPassword = PasswordService.hashForServer(password);
      
      final response = await _dio.post(ApiEndPoints.authLogIn, data: {
        'user_name': username, 
        'password': hashedPassword,
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

  Future<User> signUp(String userName, String password, String displayName, String publicKey) async {
    try {
      // Hash the password before sending to server
      final hashedPassword = PasswordService.hashForServer(password);
      
      final response = await _dio.post(ApiEndPoints.authSignUp, data: {
        'user_name': userName,
        'password': hashedPassword,
        'display_name': displayName,
        'public_key': publicKey,
      });

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['token'] != null) {
        await _storageService.saveToken(response.data['token']);
        await _socketClient.connectAndListen();

        final user = await _userRepository.getMe();
        _socketClient.registerPresence(user);

        return user;
      } else {
        throw AuthException('Sign up failed: Invalid response from server.');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
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
      if (statusCode == 400 || statusCode == 401 || statusCode == 404 || statusCode == 409) {
        return AuthException(errorMessage);
      }
    }

    // Return a default server exception
    return ServerException('An unexpected server error occurred.');
  }

  Future<void> logout() async {
    try {
      // Disconnect the socket
      sl<SocketClient>().disconnect();

      // Delete the token
      await _storageService.deleteToken();
    } catch (e) {
      // Re-throw the error so the UI layer is aware of the failure.
      throw ServerException("Failed to clear session data.");
    }
  }

  Future<String?> getToken() async {
    return await _storageService.getToken();
  }

  Future<String?> getPrivateKey() async {
    return await _storageService.getPrivateKey();
  }
}