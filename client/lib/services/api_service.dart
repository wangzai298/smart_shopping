import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../models/product.dart';
import '../models/filter.dart';
import 'storage_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.read(storageServiceProvider));
});

String _friendlyError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      return '连接超时 — 请确认服务端已启动';
    case DioExceptionType.connectionError:
      return '无法连接服务端 (${ApiConfig.baseUrl})\n'
          '可能原因：\n'
          '1. 服务端未启动（cd server && npm run start:dev）\n'
          '2. 手机和电脑不在同一 WiFi\n'
          '3. 需要在 api_config.dart 中修改 lanIp 为电脑的局域网 IP\n'
          '当前配置：${ApiConfig.debugInfo}';
    case DioExceptionType.receiveTimeout:
      return '服务端响应超时';
    default:
      return '网络错误: ${e.message}';
  }
}

class ApiService {
  final Dio _dio;
  final StorageService _storage;

  ApiService(this._storage) : _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json; charset=utf-8'},
  )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Attempt token refresh once
          try {
            final refreshToken = await _storage.getRefreshToken();
            if (refreshToken != null) {
              final refreshDio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
              final response = await refreshDio.post('/auth/refresh', data: {
                'refreshToken': refreshToken,
              });
              final data = response.data['data'] as Map<String, dynamic>;
              await _storage.saveTokens(data['accessToken'], refreshToken);

              // Retry original request with new token
              error.requestOptions.headers['Authorization'] = 'Bearer ${data['accessToken']}';
              final retryResponse = await _dio.fetch(error.requestOptions);
              return handler.resolve(retryResponse);
            }
          } catch (_) {
            await _storage.clearTokens();
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<List<Product>> uploadImage(List<String> images) async {
    try {
      final response = await _dio.post('/recognition/upload', data: {
        'images': images,
      });
      final json = response.data as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        final data = json['data'] as Map<String, dynamic>;
        final products = (data['products'] as List<dynamic>?)
            ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList() ?? [];
        return products;
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_friendlyError(e));
    }
  }

  Future<Map<String, dynamic>> fetchHistory(String productId) async {
    try {
      final response = await _dio.get('/products/$productId/history');
      final json = response.data as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        return json['data'] as Map<String, dynamic>;
      }
      return {'productId': productId, 'platforms': <String, dynamic>{}};
    } on DioException catch (e) {
      throw Exception(_friendlyError(e));
    }
  }

  Future<Map<String, dynamic>> sendFilter(String query, {Map<String, dynamic>? context, String? conversationId}) async {
    try {
      final body = <String, dynamic>{'query': query};
      if (context != null) {
        body['context'] = context;
      }
      if (conversationId != null) {
        body['conversationId'] = conversationId;
      }
      final response = await _dio.post('/nlp/filter', data: body);
      final json = response.data as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        return json['data'] as Map<String, dynamic>;
      }
      return {'conversationId': null, 'filter': Filter.defaultFilter().toJson()};
    } on DioException catch (e) {
      throw Exception(_friendlyError(e));
    }
  }

  // ── Favorites ──
  Future<List<dynamic>> getFavoriteLists() async =>
      (await _dio.get('/favorites/lists')).data['data'];

  Future<Map<String, dynamic>> createFavoriteList(String name) async =>
      (await _dio.post('/favorites/lists', data: {'name': name})).data['data'];

  Future<void> deleteFavoriteList(int id) async =>
      _dio.delete('/favorites/lists/$id');

  Future<Map<String, dynamic>> addFavoriteItem(int listId, String productId) async =>
      (await _dio.post('/favorites/lists/$listId/items', data: {'productId': productId})).data;

  Future<List<dynamic>> getFavoriteItems(int listId) async =>
      (await _dio.get('/favorites/lists/$listId/items')).data['data'];

  Future<void> deleteFavoriteItem(int itemId) async =>
      _dio.delete('/favorites/items/$itemId');

  // ── Search History ──
  Future<List<dynamic>> getSearchHistory() async =>
      (await _dio.get('/search-history')).data['data'];

  Future<void> clearSearchHistory() async =>
      _dio.delete('/search-history');

  // ── Reviews ──
  Future<Map<String, dynamic>> getReviews(String productId) async {
    final response = await _dio.get('/products/$productId/reviews');
    return response.data['data'] as Map<String, dynamic>;
  }

  // ── Price Alerts ──
  Future<List<dynamic>> getPriceAlerts() async =>
      (await _dio.get('/price-alerts')).data['data'];

  Future<Map<String, dynamic>> createPriceAlert(Map<String, dynamic> data) async =>
      (await _dio.post('/price-alerts', data: data)).data['data'];

  Future<void> deletePriceAlert(int id) async =>
      _dio.delete('/price-alerts/$id');

  Future<void> updatePriceAlert(int id, Map<String, dynamic> data) async =>
      _dio.patch('/price-alerts/$id', data: data);
}
