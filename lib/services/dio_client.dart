import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Required for kDebugMode
import 'secure_storage_service.dart';
import '../core/config.dart';

class DioClient {
  DioClient._privateConstructor();
  static final DioClient instance = DioClient._privateConstructor();

  final Dio dio = _createDio();

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      // Use the baseUrl from AppConfig, which is set in main.dart
      baseUrl: AppConfig.instance.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorageService.instance.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          print('--> ${options.method.toUpperCase()} ${options.path}');
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (kDebugMode) {
          print('❌ DIO ERROR: [${e.response?.statusCode}] ${e.requestOptions.path}');
          print('Error Data: ${e.response?.data}');
        }
        return handler.next(e);
      },
    ));

    return dio;
  }
}