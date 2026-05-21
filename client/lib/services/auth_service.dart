import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import 'storage_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(storageServiceProvider));
});

class AuthService {
  final StorageService _storage;
  final Dio _dio;

  AuthService(this._storage)
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        ));

  Future<Map<String, dynamic>> register(String phone, String code, String password) async {
    final response = await _dio.post('/auth/register', data: {
      'phone': phone,
      'code': code,
      'password': password,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    await _storage.saveTokens(data['accessToken'], data['refreshToken']);
    return data;
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    await _storage.saveTokens(data['accessToken'], data['refreshToken']);
    return data;
  }

  Future<void> sendSmsCode(String phone) async {
    await _dio.post('/auth/send-sms-code', data: {'phone': phone});
  }

  Future<void> logout() async {
    await _storage.clearTokens();
  }
}
