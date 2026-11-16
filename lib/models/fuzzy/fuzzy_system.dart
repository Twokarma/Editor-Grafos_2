import 'fuzzy_rule.dart';
import 'fuzzy_variable.dart';
import 'membership_function.dart';

class FuzzySystem {
  String name;
  final List<FuzzyVariable> inputs;
  FuzzyVariable output;
  final List<FuzzyRule> rules;

  FuzzySystem({
    this.name = 'Sistema difuso',
    List<FuzzyVariable>? inputs,
    required this.output,
    List<FuzzyRule>? rules,
  })  : inputs = inputs ?? <FuzzyVariable>[],
        rules = rules ?? <FuzzyRule>[];

  FuzzyVariable? inputByName(String n) {
    for (final v in inputs) {
      if (v.name == n) return v;
    }
    return null;
  }

  bool _esSalida(FuzzyVariable v) => identical(v, output);

  // ---------------------------------------------------------------------------
  // Edición consistente (mantiene las reglas sincronizadas)
  // ---------------------------------------------------------------------------

  /// Renombra un término y actualiza las reglas que lo usan.
  void renameTerm(FuzzyVariable v, String old, String nuevo) {
    if (old == nuevo) return;
    v.renameTerm(old, nuevo);
    for (var i = 0; i < rules.length; i++) {
      final r = rules[i];
      if (_esSalida(v)) {
        if (r.consequent == old) rules[i] = r.copyWith(consequent: nuevo);
      } else if (r.antecedents[v.name] == old) {
        rules[i] = r.copyWith(antecedents: {...r.antecedents, v.name: nuevo});
      }
    }
  }

  /// Borra un término y limpia las reglas que dependían de él.
  /// - Salida: la regla pierde su consecuente (queda pendiente de asignar).
  /// - Entrada: se quita esa condición; si la regla se queda sin
  ///   antecedentes, se elimina.
  void removeTerm(FuzzyVariable v, String term) {
    v.terms.remove(term);
    final nuevas = <FuzzyRule>[];
    for (final r in rules) {
      if (_esSalida(v)) {
        nuevas.add(r.consequent == term ? r.copyWith(clearConsequent: true) : r);
      } else if (r.antecedents[v.name] == term) {
        final ant = Map<String, String>.from(r.antecedents)..remove(v.name);
        if (ant.isNotEmpty) nuevas.add(r.copyWith(antecedents: ant));
      } else {
        nuevas.add(r);
      }
    }
    rules
      ..clear()
      ..addAll(nuevas);
  }

  /// Renombra una variable y actualiza antecedentes y coeficientes Sugeno.
  /// Valida antes que [nuevo] no esté vacío ni repetido.
  void renameVariable(FuzzyVariable v, String nuevo) {
    final old = v.name;
    if (old == nuevo) return;
    v.name = nuevo;
    if (_esSalida(v)) return; // las reglas solo guardan nombres de entradas
    for (var i = 0; i < rules.length; i++) {
      final r = rules[i];
      final ant = r.antecedents.map((k, t) => MapEntry(k == old ? nuevo : k, t));
      final coefs =
          r.sugenoCoefs?.map((k, c) => MapEntry(k == old ? nuevo : k, c));
      rules[i] = r.copyWith(antecedents: ant, sugenoCoefs: coefs);
    }
  }

  // ---------------------------------------------------------------------------

  factory FuzzySystem.empty() => FuzzySystem(
        name: 'Nuevo sistema',
        output: FuzzyVariable(name: 'salida', min: 0, max: 10),
      );

  /// Ejemplo clásico de la propina (sirve para probar Mamdani y Sugeno).
  factory FuzzySystem.example() {
    final servicio = FuzzyVariable(name: 'servicio', min: 0, max: 10, terms: {
      'malo': const Triangular(0, 0, 5),
      'bueno': const Triangular(0, 5, 10),
      'excelente': const Triangular(5, 10, 10),
    });
    final comida = FuzzyVariable(name: 'comida', min: 0, max: 10, terms: {
      'mala': const Trapezoidal(0, 0, 1, 3),
      'deliciosa': const Trapezoidal(7, 9, 10, 10),
    });
    final propina = FuzzyVariable(name: 'propina', min: 0, max: 25, terms: {
      'baja': const Triangular(0, 0, 13),
      'media': const Triangular(0, 13, 25),
      'alta': const Triangular(13, 25, 25),
    });
    return FuzzySystem(
      name: 'Propina',
      inputs: [servicio, comida],
      output: propina,
      rules: [
        FuzzyRule(
          antecedents: {'servicio': 'malo', 'comida': 'mala'},
          connector: Connector.or,
          consequent: 'baja',
          sugenoCoefs: {},
          sugenoConst: 5,
        ),
        FuzzyRule(
          antecedents: {'servicio': 'bueno'},
          consequent: 'media',
          sugenoCoefs: {},
          sugenoConst: 13,
        ),
        FuzzyRule(
          antecedents: {'servicio': 'excelente', 'comida': 'deliciosa'},
          connector: Connector.or,
          consequent: 'alta',
          sugenoCoefs: {},
          sugenoConst: 21,
        ),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'inputs': inputs.map((v) => v.toJson()).toList(),
        'output': output.toJson(),
        'rules': rules.map((r) => r.toJson()).toList(),
      };

  factory FuzzySystem.fromJson(Map<String, dynamic> j) => FuzzySystem(
        name: j['name'] as String? ?? 'Sistema difuso',
        inputs: (j['inputs'] as List)
            .map((e) => FuzzyVariable.fromJson(e as Map<String, dynamic>))
            .toList(),
        output: FuzzyVariable.fromJson(j['output'] as Map<String, dynamic>),
        rules: (j['rules'] as List)
            .map((e) => FuzzyRule.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}