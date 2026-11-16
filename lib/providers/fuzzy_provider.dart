import 'package:flutter/foundation.dart';

import '../algorithms/fuzzy/mamdani.dart';
import '../algorithms/fuzzy/sugeno.dart';
import '../models/fuzzy/fuzzy_rule.dart';
import '../models/fuzzy/fuzzy_system.dart';
import '../models/fuzzy/fuzzy_variable.dart';
import '../models/fuzzy/membership_function.dart';
import '../services/fuzzy_library_service.dart';
import '../services/fuzzy_storage_service.dart';

enum FuzzyMethod { mamdani, sugeno }

class FuzzyProvider extends ChangeNotifier {
  FuzzyProvider({
    FuzzyStorageService? storage,
    FuzzyLibraryService? library,
  })  : _storage = storage ?? FuzzyStorageService(),
        _library = library ?? FuzzyLibraryService() {
    _syncInputs();
    _calculate();
    _loadSaved();
  }

  final FuzzyStorageService _storage;
  final FuzzyLibraryService _library;
  bool _disposed = false;

  FuzzySystem system = FuzzySystem.example();
  FuzzyMethod method = FuzzyMethod.mamdani;

  /// Valor actual de cada entrada (para la pestaña de simulación).
  final Map<String, double> inputValues = {};

  MamdaniResult? mamdaniResult;
  SugenoResult? sugenoResult;

  // ---------------------------------------------------------------- Resultado

  double? get result => method == FuzzyMethod.mamdani
      ? mamdaniResult?.value
      : sugenoResult?.value;

  bool get active => method == FuzzyMethod.mamdani
      ? (mamdaniResult?.active ?? false)
      : (sugenoResult?.active ?? false);

  List<double> get firing => method == FuzzyMethod.mamdani
      ? (mamdaniResult?.firing ?? const <double>[])
      : (sugenoResult?.weights ?? const <double>[]);

  // ------------------------------------------------------------------ Método

  void setMethod(FuzzyMethod m) {
    method = m;
    notifyListeners();
  }

  void setInputValue(String name, double value) {
    inputValues[name] = value;
    _calculate();
    notifyListeners();
  }

  // --------------------------------------------------------------- Variables

  /// Devuelve un mensaje de error, o null si todo salió bien.
  String? addInput(String name, double min, double max) {
    final n = name.trim();
    final err = _checkIdentifier(n);
    if (err != null) return err;
    if (min >= max) return 'El mínimo debe ser menor que el máximo.';
    if (n == system.output.name || system.inputByName(n) != null) {
      return 'Ya existe una variable con ese nombre.';
    }
    system.inputs.add(FuzzyVariable(name: n, min: min, max: max));
    _changed();
    return null;
  }

  void removeInput(String name) {
    system.inputs.removeWhere((v) => v.name == name);
    final updated = <FuzzyRule>[];
    for (final r in system.rules) {
      if (!r.antecedents.containsKey(name)) {
        updated.add(r);
        continue;
      }
      final ant = Map<String, String>.of(r.antecedents)..remove(name);
      if (ant.isEmpty) continue;
      final coefs = r.sugenoCoefs == null
          ? null
          : (Map<String, double>.of(r.sugenoCoefs!)..remove(name));
      updated.add(r.copyWith(antecedents: ant, sugenoCoefs: coefs));
    }
    system.rules
      ..clear()
      ..addAll(updated);
    _changed();
  }

  /// Cambia nombre y rango de una variable (entrada o salida).
  /// Al renombrar una entrada, se actualizan las reglas (antecedentes y
  /// coeficientes Sugeno) y se conserva su valor de simulación.
  /// Devuelve un mensaje de error, o null si todo salió bien.
  String? updateVariable(
    String currentName, {
    required String newName,
    required double min,
    required double max,
  }) {
    final v = _variable(currentName);
    if (v == null) return 'Variable no encontrada.';
    if (min >= max) return 'El mínimo debe ser menor que el máximo.';

    final n = newName.trim();
    final isOutput = identical(v, system.output);

    if (n != currentName) {
      final err = _checkIdentifier(n);
      if (err != null) return err;
      if (n == system.output.name || system.inputByName(n) != null) {
        return 'Ya existe una variable con ese nombre.';
      }
      if (isOutput) {
        v.name = n;
      } else {
        final valorActual = inputValues.remove(currentName);
        system.renameVariable(v, n);
        if (valorActual != null) inputValues[n] = valorActual;
      }
    }

    v.min = min;
    v.max = max;
    _changed();
    return null;
  }

  // ----------------------------------------------------------------- Términos

  String? addTerm(String varName, String term, MF mf) {
    final v = _variable(varName);
    if (v == null) return 'Variable no encontrada.';
    final t = term.trim();
    final err = _checkIdentifier(t);
    if (err != null) return err;
    if (v.terms.containsKey(t)) return 'Ya existe un término con ese nombre.';
    final mfErr = MF.validate(mf.type, mf.params);
    if (mfErr != null) return mfErr;
    v.terms[t] = mf;
    _changed();
    return null;
  }

  /// Edita un término existente: puede cambiar su nombre y/o su función.
  /// Si cambia el nombre, las reglas que lo usan se actualizan solas.
  String? updateTerm(String varName, String oldTerm, String newTerm, MF mf) {
    final v = _variable(varName);
    if (v == null) return 'Variable no encontrada.';
    if (!v.terms.containsKey(oldTerm)) return 'Término no encontrado.';

    final t = newTerm.trim();
    final err = _checkIdentifier(t);
    if (err != null) return err;
    if (t != oldTerm && v.terms.containsKey(t)) {
      return 'Ya existe un término con ese nombre.';
    }
    final mfErr = MF.validate(mf.type, mf.params);
    if (mfErr != null) return mfErr;

    if (t != oldTerm) system.renameTerm(v, oldTerm, t);
    v.replaceTerm(t, mf);
    _changed();
    return null;
  }

  /// Borra un término y limpia las reglas que dependían de él.
  void removeTerm(String varName, String term) {
    final v = _variable(varName);
    if (v == null) return;
    system.removeTerm(v, term);
    _changed();
  }

  // ------------------------------------------------------------------- Reglas

  void addRule(FuzzyRule rule) {
    system.rules.add(rule);
    _changed();
  }

  void removeRule(int index) {
    if (index < 0 || index >= system.rules.length) return;
    system.rules.removeAt(index);
    _changed();
  }

  // ------------------------------------------------------------------ Sistema

  void loadExample() {
    system = FuzzySystem.example();
    _changed();
  }

  void clearSystem() {
    system = FuzzySystem.empty();
    _changed();
  }

  /// Guarda el sistema actual (autoguardado interno).
  Future<void> save() => _storage.save(system);

  // ---------------------------------------------- Sistemas guardados con nombre

  Future<List<SavedSystemInfo>> listNamed() => _library.list();

  Future<bool> namedExists(String name) => _library.exists(name.trim());

  /// Guarda el sistema actual con [name] (sobrescribe si ya existe) y se lo
  /// asigna como nombre. Devuelve un mensaje de error o null.
  Future<String?> saveAs(String name) async {
    final n = name.trim();
    if (n.isEmpty) return 'Escribe un nombre.';
    system.name = n;
    await _library.save(n, system);
    _changed();
    return null;
  }

  /// Carga un sistema guardado y reemplaza el actual.
  Future<String?> loadNamed(String name) async {
    final loaded = await _library.load(name);
    if (loaded == null) return 'No se pudo cargar "$name".';
    system = loaded;
    _changed();
    return null;
  }

  Future<void> deleteNamed(String name) => _library.delete(name);

  // ----------------------------------------------------------------- Internos

  Future<void> _loadSaved() async {
    final saved = await _storage.load();
    if (saved == null) return;
    system = saved;
    _syncInputs();
    _calculate();
    notifyListeners();
  }

  void _changed() {
    _syncInputs();
    _calculate();
    notifyListeners();
    _storage.save(system); // autoguardado
  }

  void _syncInputs() {
    final names = system.inputs.map((v) => v.name).toSet();
    inputValues.removeWhere((k, _) => !names.contains(k));
    for (final v in system.inputs) {
      final cur = inputValues[v.name];
      if (cur == null || cur < v.min || cur > v.max) {
        inputValues[v.name] = (v.min + v.max) / 2;
      }
    }
  }

  void _calculate() {
    if (system.rules.isEmpty) {
      mamdaniResult = null;
      sugenoResult = null;
      return;
    }
    mamdaniResult = Mamdani.evaluate(system, inputValues);
    sugenoResult = Sugeno.evaluate(system, inputValues);
  }

  FuzzyVariable? _variable(String name) =>
      name == system.output.name ? system.output : system.inputByName(name);

  String? _checkIdentifier(String s) {
    if (s.isEmpty) return 'El nombre no puede estar vacío.';
    if (!RegExp(r'^[A-Za-z0-9_áéíóúñÁÉÍÓÚÑ]+$').hasMatch(s)) {
      return 'Usa solo letras, números o _ (sin espacios).';
    }
    return null;
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}