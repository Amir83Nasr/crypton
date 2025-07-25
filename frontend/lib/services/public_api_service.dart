import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypton_frontend/services/storage_service.dart';

class PublicApiService {
  late final Dio _dio;
  final baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.1.3:8000/api/';

  PublicApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {'Content-Type': 'application/json'},
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

  /// ثبت‌نام کاربر جدید
  Future<Map<String, Object?>> register({
    required String name,
    required String family,
    required String username,
    required String password,
    required age,
    required String gender,
  }) async {
    try {
      final response = await _dio.post(
        'register/',
        data: {
          'name': name,
          'family': family,
          'username': username,
          'password': password,
          'age': age,
          'gender': gender,
        },
      );

      final data = response.data;
      final access = data['user']['access'] as String?;
      final refresh = data['user']['refresh'] as String?;
      final role = 'user';

      if (access != null && refresh != null) {
        await StorageService.saveTokens(access: access, refresh: refresh);
        await StorageService.saveUserRole(role);
      }

      return {'success': true, 'data': data};
    } on DioException catch (e) {
      final response = e.response;
      if (response?.statusCode == 400 && response?.data != null) {
        final errorData = response!.data;

        String? errorMessage;

        if (errorData is Map) {
          // حالت 1: وجود کلید detail
          if (errorData.containsKey('detail')) {
            errorMessage = errorData['detail'].toString();
          }
          // حالت 2: ساختار errors به صورت Map
          else if (errorData.containsKey('errors') &&
              errorData['errors'] is Map) {
            final errors = errorData['errors'] as Map;
            if (errors.isNotEmpty) {
              final firstValue = errors.values.first;
              errorMessage =
                  firstValue is List
                      ? firstValue.first.toString()
                      : firstValue.toString();
            }
          }
          // حالت 3: non_field_errors به صورت لیست
          else if (errorData.containsKey('non_field_errors')) {
            final nonFieldErrors = errorData['non_field_errors'];
            if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
              errorMessage = nonFieldErrors.first.toString();
            }
          }
          // حالت 4: ارور مستقیم به صورت Map با کلید‌های دیگر
          else if (errorData.isNotEmpty) {
            // اگر errorData شامل کلیدهای فیلدها هست
            final firstKey = errorData.keys.first;
            final firstValue = errorData[firstKey];
            if (firstValue is List && firstValue.isNotEmpty) {
              errorMessage = firstValue.first.toString();
            } else {
              errorMessage = firstValue.toString();
            }
          }
        } else if (errorData is String) {
          errorMessage = errorData;
        }

        return {
          'success': false,
          'error': errorMessage ?? 'خطایی در ثبت‌نام رخ داده است.',
        };
      }

      return {
        'success': false,
        'error': 'ارتباط با سرور برقرار نشد. لطفاً اینترنت را بررسی کنید.',
      };
    } catch (e) {
      return {'success': false, 'error': 'خطای غیرمنتظره: $e'};
    }
  }

  /// ورود کاربر و ذخیره توکن‌ها و نقش
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        'login/',
        data: {'username': username, 'password': password},
      );

      final access = response.data['access'];
      final refresh = response.data['refresh'];
      final role = response.data['role'];

      await StorageService.saveTokens(access: access, refresh: refresh);
      await StorageService.saveUserRole(role);

      return {
        'success': true,
        'data': {'access': access, 'refresh': refresh, 'role': role},
      };
    } on DioException catch (e) {
      return {'success': false, 'error': e.response?.data ?? 'خطای ناشناخته'};
    }
  }

  /// خروج از حساب و حذف داده‌ها
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// بررسی اینکه کاربر لاگین هست یا نه (بر اساس refresh token)
  Future<bool> isLoggedIn() async {
    final refresh = await StorageService.getRefreshToken();
    return refresh != null && refresh.isNotEmpty;
  }

  /// دریافت access token جدید با refresh token
  Future<bool> refreshAccessToken() async {
    final refresh = await StorageService.getRefreshToken();

    if (refresh == null || refresh.isEmpty) return false;

    try {
      final response = await _dio.post(
        'token/refresh/',
        data: {'refresh': refresh},
      );

      final newAccess = response.data['access'];
      if (newAccess != null) {
        await StorageService.saveAccessToken(newAccess);
        return true;
      }

      return false;
    } on DioException catch (_) {
      return false;
    }
  }
}
