import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/fuzzy/fuzzy_system.dart';

/// Guarda y carga el sistema difuso como JSON en shared_preferences.
class FuzzyStorageService {
  static const String _key = 'fuzzy_system_v1';

  Future<void> save(FuzzySystem system) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(system.toJson()));
  }

  Future<FuzzySystem?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      return FuzzySystem.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}