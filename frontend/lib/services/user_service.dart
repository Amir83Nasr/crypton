import 'package:crypton_frontend/services/storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserService {
  late final Dio _dio;
  final baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.1.3:8000/api/';

  UserService() {
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

  List<dynamic>? _cachedUsers;
  DateTime? _usersLastFetched;
  final Duration _userCacheDuration = Duration(minutes: 1);

  final Map<int, Map<String, dynamic>> _cachedUserDetails = {};

  // گرفتن لیست کاربران با کش
  Future<List<dynamic>> getUsers({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedUsers != null &&
        _usersLastFetched != null &&
        DateTime.now().difference(_usersLastFetched!) < _userCacheDuration) {
      return _cachedUsers!;
    }

    final response = await _dio.get('/users/');
    _cachedUsers = response.data;
    _usersLastFetched = DateTime.now();
    return _cachedUsers!;
  }

  void invalidateUserCache() {
    _cachedUsers = null;
    _usersLastFetched = null;
  }


  // گرفتن جزئیات یک کاربر بدون درخواست جداگانه، فقط از کش اصلی
  Future<Map<String, dynamic>> getUserDetails(int userId) async {
    // ابتدا از کش لیست کاربران سعی می‌کنیم بگیریم
    if (_cachedUsers != null) {
      final user = _cachedUsers!.firstWhere(
        (u) => u['id'] == userId,
        orElse: () => null,
      );
      if (user != null) return user;
    }

    // اگر در کش نبود، درخواست جداگانه ارسال شود (برای اطمینان)
    final response = await _dio.get('/users/$userId/');
    return response.data;
  }

  void invalidateUserDetailsCache(int userId) {
    _cachedUserDetails.remove(userId);
  }


  // تغییر وضعیت کاربر و پاکسازی کش
  Future<bool> toggleUserStatus(int userId, bool isActive) async {
    try {
      final response = await _dio.patch(
        '/users/$userId/',
        data: {'is_active': !isActive},
      );
      if (response.statusCode == 200) {
        invalidateUserCache();
        invalidateUserDetailsCache(userId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
