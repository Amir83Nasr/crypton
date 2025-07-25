import 'package:crypton_frontend/services/storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CoinService {
  late final Dio _dio;
  final baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.1.3:8000/api/';

  CoinService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {'Content-Type': 'application/json'},
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  List<dynamic>? _cachedCoins;
  DateTime? _lastFetchTime;

  final Duration _cacheDuration = const Duration(minutes: 5);

  Future<List<dynamic>> getCoins() async {
    final now = DateTime.now();
    final isCacheValid =
        _cachedCoins != null &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!) < _cacheDuration;

    if (isCacheValid) {
      return _cachedCoins!;
    }

    try {
      final response = await _dio.get('/coins/');
      _cachedCoins = response.data;
      _lastFetchTime = now;
      return _cachedCoins!;
    } catch (e) {
      throw Exception('خطا در دریافت لیست رمز ارزها: $e');
    }
  }

  Future<Map<String, dynamic>> getCoinDetails(String symbol) async {
    try {
      final response = await _dio.get('/coins/$symbol/');
      return response.data;
    } catch (e) {
      throw Exception('خطا در دریافت جزئیات رمز ارز: $e');
    }
  }

  Future<bool> toggleCoinStatus(String symbol, bool isActive) async {
    try {
      final response = await _dio.patch(
        '/coins/$symbol/',
        data: {'is_active': !isActive},
      );

      // بروزرسانی کش پس از تغییر وضعیت
      if (response.statusCode == 200) {
        await getCoins(); // ریفرش لیست رمز ارزها
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  void clearCache() {
    _cachedCoins = null;
    _lastFetchTime = null;
  }

  Future<String?> buyCoin({required int coinId, required double amount}) async {
    try {
      final response = await _dio.post(
        '/buy/',
        data: {'coin_id': coinId, 'amount': amount},
      );

      if (response.statusCode == 200) {
        return response.data['message']; // خرید با موفقیت انجام شد
      } else {
        return 'خطا در انجام خرید';
      }
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final error = e.response!.data;
        if (error is Map && error.containsKey('non_field_errors')) {
          return error['non_field_errors'][0];
        }
        return error.toString();
      }
      return 'خطا در اتصال به سرور';
    }
  }

  Future<Map<String, dynamic>> sellCoin({
    required String coinSymbol,
    required double amount,
  }) async {
    try {
      final response = await _dio.post(
        '/sell/',
        data: {'coin_symbol': coinSymbol, 'amount': amount},
      );

      return {
        'success': true,
        'message': response.data['message'],
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      if (e.response != null) {
        return {'success': false, 'error': e.response!.data};
      } else {
        return {'success': false, 'error': 'خطا در ارتباط با سرور'};
      }
    }
  }

  Future<String?> swapCoin({
    required String fromSymbol,
    required String toSymbol,
    required double amount,
  }) async {
    try {
      final response = await _dio.post(
        '/swap/',
        data: {
          'from_symbol': fromSymbol,
          'to_symbol': toSymbol,
          'amount': amount.toString(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['message'] ?? 'سواپ با موفقیت انجام شد';
      } else {
        return 'خطا در سواپ';
      }
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final error = e.response!.data;
        if (error is Map && error.containsKey('error')) {
          return error['error'];
        }
        return error.toString();
      }
      return 'خطا در اتصال به سرور';
    }
  }
}
