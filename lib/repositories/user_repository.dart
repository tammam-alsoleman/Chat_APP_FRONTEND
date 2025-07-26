import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../services/dio_client.dart';
import '../models/user_model.dart';
import '../shared/exceptions.dart';

class UserRepository {
  final Dio _dio = DioClient.instance.dio;

  Future<User> getMe() async {
    try {
      final response = await _dio.get(ApiEndPoints.usersMe);
      return User.fromJson(response.data);
    } on DioException {
      throw ServerException('Failed to fetch user data.');
    }
  }
}