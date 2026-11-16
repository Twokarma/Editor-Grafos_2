import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/fuzzy/fuzzy_system.dart';

/// Resumen de un sistema guardado, para mostrarlo en la lista de "Cargar".
class SavedSystemInfo {
  final String name;
  final DateTime savedAt;
  final int inputs;
  final int rules;

  const SavedSystemInfo({
    required this.name,
    required this.savedAt,
    required this.inputs,
    required this.rules,
  });
}

/// Guarda varios sistemas difusos con nombre (independiente del autoguardado
/// de [FuzzyStorageService], que solo recuerda el sistema actual).
///
/// Requiere `shared_preferences` en pubspec.yaml:
///   flutter pub add shared_preferences
class FuzzyLibraryService {
  static const _key = 'fuzzy_library_v1';

  Future<Map<String, dynamic>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeAll(Map<String, dynamic> all) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(all));
  }

  /// Lista los sistemas guardados, del más reciente al más antiguo.
  Future<List<SavedSystemInfo>> list() async {
    final all = await _readAll();
    final out = <SavedSystemInfo>[];
    all.forEach((name, value) {
      try {
        final m = Map<String, dynamic>.from(value as Map);
        final sys = Map<String, dynamic>.from(m['system'] as Map);
        out.add(SavedSystemInfo(
          name: name,
          savedAt: DateTime.tryParse(m['savedAt'] as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
          inputs: (sys['inputs'] as List).length,
          rules: (sys['rules'] as List).length,
        ));
      } catch (_) {
        // entrada dañada: se ignora
      }
    });
    out.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return out;
  }

  Future<bool> exists(String name) async => (await _readAll()).containsKey(name);

  Future<void> save(String name, FuzzySystem system) async {
    final all = await _readAll();
    all[name] = {
      'savedAt': DateTime.now().toIso8601String(),
      'system': system.toJson(),
    };
    await _writeAll(all);
  }

  Future<FuzzySystem?> load(String name) async {
    final all = await _readAll();
    final value = all[name];
    if (value == null) return null;
    try {
      final m = Map<String, dynamic>.from(value as Map);
      return FuzzySystem.fromJson(Map<String, dynamic>.from(m['system'] as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String name) async {
    final all = await _readAll();
    if (all.remove(name) != null) await _writeAll(all);
  }
}