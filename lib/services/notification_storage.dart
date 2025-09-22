import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationStorage {
  static const String key = "notifications";

  static Future<void> saveNotification(String title, String body) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(key) ?? [];
    final newNotification = jsonEncode({
      "title": title,
      "body": body,
      "time": DateTime.now().toIso8601String(),
    });
    existing.insert(0, newNotification);
    await prefs.setStringList(key, existing);
  }

  static Future<List<Map<String, dynamic>>> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(key) ?? [];
    return data.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<void> saveAll(List<Map<String, dynamic>> notifs) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = notifs.map((n) => json.encode(n)).toList();
    await prefs.setStringList(key, encoded);
  }
}
