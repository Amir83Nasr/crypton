import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CryptoCache {
  static const _cacheKey = 'cached_crypto_list';
  static const _cacheTimeKey = 'cached_crypto_time';

  static Future<void> save(List<dynamic> cryptos) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    await prefs.setString(_cacheKey, jsonEncode(cryptos));
    await prefs.setInt(_cacheTimeKey, now);
  }

  static Future<List<dynamic>?> loadIfValid({int maxAgeMinutes = 5}) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedTime = prefs.getInt(_cacheTimeKey);
    final cachedData = prefs.getString(_cacheKey);

    if (cachedTime != null && cachedData != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final age = now - cachedTime;
      final maxAge = maxAgeMinutes * 60 * 1000;

      if (age <= maxAge) {
        return jsonDecode(cachedData);
      }
    }
    return null; // کش منقضی شده
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimeKey);
  }
}
