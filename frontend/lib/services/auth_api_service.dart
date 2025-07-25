import 'package:dio/dio.dart';
import 'package:crypton_frontend/services/storage_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthApiService {
  late final Dio _dio;
  final baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.1.3:8000/api/';

  AuthApiService() {
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

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/change-password/',
        data: {'old_password': oldPassword, 'new_password': newPassword},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? 'خطایی رخ داده است');
      }
    } catch (e) {
      throw Exception('خطا در تغییر رمز عبور: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/user/');
    return {'data': response.data};
  }

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) async {
    final response = await _dio.patch('/user/', data: data);
    return {'data': response.data};
  }

  Future<List<Map<String, dynamic>>> getMyAssets() async {
    try {
      final response = await _dio.get('/asset/');
      if (response.statusCode == 200) {
        final List<dynamic> assets = response.data;
        // همه دارایی‌ها برگردانده می‌شود
        return assets.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        throw Exception('خطا در دریافت دارایی‌ها');
      }
    } catch (e) {
      throw Exception('خطا در دریافت اطلاعات: $e');
    }
  }

  Future<Map<String, dynamic>> sendContactMessage({
    required String message,
    required int stars,
  }) async {
    try {
      final response = await _dio.post(
        '/contact-messages/',
        data: {'message': message, 'stars': stars},
      );

      return response.data;
    } on DioError catch (e) {
      if (e.response != null) {
        throw Exception('خطا: ${e.response?.data}');
      } else {
        throw Exception('خطای شبکه: ${e.message}');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getContactMessages() async {
    try {
      final response = await _dio.get('contact-messages/');
      final data = response.data as List;

      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } on DioError catch (e) {
      throw Exception(e.response?.data.toString() ?? e.message);
    }
  }

  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final response = await _dio.get('announcements/');
      final data = response.data as List;
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } on DioError catch (e) {
      throw Exception(e.response?.data.toString() ?? e.message);
    }
  }

  Future<void> createAnnouncement({
    required String title,
    required String message,
  }) async {
    try {
      await _dio.post(
        'announcements/',
        data: {'title': title, 'message': message},
      );
    } on DioError catch (e) {
      throw Exception(e.response?.data.toString() ?? e.message);
    }
  }

  Future<void> updateAnnouncement({
    required int id,
    required String title,
    required String message,
  }) async {
    try {
      await _dio.put(
        'announcements/$id/',
        data: {'title': title, 'message': message},
      );
    } on DioError catch (e) {
      throw Exception(e.response?.data.toString() ?? e.message);
    }
  }

  Future<void> deleteAnnouncement(int id) async {
    try {
      await _dio.delete('announcements/$id/');
    } on DioError catch (e) {
      throw Exception(e.response?.data.toString() ?? e.message);
    }
  }

  Future<double> getWalletBalance() async {
    try {
      final response = await _dio.get('/wallet/');
      final data = response.data;
      return double.tryParse(data['balance'].toString()) ?? 0.0;
    } catch (e) {
      throw Exception('خطا در دریافت موجودی: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getUserTransactions() async {
    try {
      final response = await _dio.get('/transaction/');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is List) {
          return data
              .map<Map<String, dynamic>>(
                (item) => Map<String, dynamic>.from(item),
              )
              .toList();
        } else {
          throw Exception('داده دریافت‌شده فرمت لیست ندارد: $data');
        }
      } else {
        throw Exception('خطا در دریافت تراکنش‌ها: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطای دریافت تراکنش‌ها: $e');
    }
  }
}
