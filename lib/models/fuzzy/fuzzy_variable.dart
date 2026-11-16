import 'membership_function.dart';

class FuzzyVariable {
  String name;
  double min;
  double max;
  final Map<String, MF> terms;

  FuzzyVariable({
    required this.name,
    required this.min,
    required this.max,
    Map<String, MF>? terms,
  }) : terms = terms ?? <String, MF>{};

  /// Renombra un término conservando el orden de inserción.
  /// No toca las reglas: usa `FuzzySystem.renameTerm` para eso.
  void renameTerm(String old, String nuevo) {
    if (old == nuevo || !terms.containsKey(old)) return;
    final copia = Map<String, MF>.from(terms);
    terms.clear();
    copia.forEach((k, v) => terms[k == old ? nuevo : k] = v);
  }

  /// Reemplaza (o agrega) la función de un término.
  void replaceTerm(String name, MF mf) => terms[name] = mf;

  Map<String, dynamic> toJson() => {
        'name': name,
        'min': min,
        'max': max,
        'terms': terms.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory FuzzyVariable.fromJson(Map<String, dynamic> j) => FuzzyVariable(
        name: j['name'] as String,
        min: (j['min'] as num).toDouble(),
        max: (j['max'] as num).toDouble(),
        terms: (j['terms'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, MF.fromJson(v as Map<String, dynamic>)),
        ),
      );
}