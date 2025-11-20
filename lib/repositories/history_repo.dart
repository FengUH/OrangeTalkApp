import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryRepo {
  static const _key = 'identify_history_v1';

  Future<List<Map<String, String>>> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList(_key) ?? [];
    return raw.map((e) => Map<String, String>.from(json.decode(e))).toList();
  }

  Future<void> save(List<Map<String, String>> history) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_key, history.map((e) => json.encode(e)).toList());
  }

  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
  }

  /// ✅ 新增：追加保存一个病例记录
  Future<void> addCase({
    required String imagePath,
    required String title,
    required String advice,
    required double confidence,
    required DateTime time,
  }) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList(_key) ?? [];

    final newItem = {
      'imagePath': imagePath,
      'title': title,
      'advice': advice,
      'confidence': confidence.toStringAsFixed(2),
      'time': time.toIso8601String(),
    };

    raw.add(json.encode(newItem));
    await sp.setStringList(_key, raw);
  }
}
