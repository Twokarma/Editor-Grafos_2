enum Connector { and, or }

/// Regla difusa.
///
/// - Mamdani: usa [consequent] (nombre de un término de la variable de salida).
/// - Sugeno:  usa [sugenoCoefs] y [sugenoConst]  →  z = Σ aᵢ·xᵢ + c
///   (orden 0 si los coeficientes están vacíos, orden 1 si hay coeficientes).
///
/// Una misma regla puede tener ambas salidas para poder cambiar de método.
class FuzzyRule {
  /// variable de entrada -> término (p. ej. {'servicio': 'malo'})
  final Map<String, String> antecedents;
  final Connector connector;
  final String? consequent;
  final Map<String, double>? sugenoCoefs;
  final double sugenoConst;
  final double weight;

  const FuzzyRule({
    required this.antecedents,
    this.connector = Connector.and,
    this.consequent,
    this.sugenoCoefs,
    this.sugenoConst = 0,
    this.weight = 1,
  });

  bool get hasSugeno => sugenoCoefs != null;

  FuzzyRule copyWith({
    Map<String, String>? antecedents,
    Connector? connector,
    String? consequent,
    bool clearConsequent = false,
    Map<String, double>? sugenoCoefs,
    double? sugenoConst,
    double? weight,
  }) {
    return FuzzyRule(
      antecedents: antecedents ?? this.antecedents,
      connector: connector ?? this.connector,
      consequent: clearConsequent ? null : (consequent ?? this.consequent),
      sugenoCoefs: sugenoCoefs ?? this.sugenoCoefs,
      sugenoConst: sugenoConst ?? this.sugenoConst,
      weight: weight ?? this.weight,
    );
  }

  String describe(String outputName) {
    final sep = connector == Connector.and ? ' Y ' : ' O ';
    final cond = antecedents.entries.map((e) => '${e.key} ES ${e.value}').join(sep);
    final out = consequent == null ? '—' : '$outputName ES $consequent';
    return 'SI $cond ENTONCES $out';
  }

  String? sugenoText(String outputName) {
    final coefs = sugenoCoefs;
    if (coefs == null) return null;
    final parts = <String>[];
    coefs.forEach((k, v) {
      if (v != 0) parts.add('${_fmt(v)}·$k');
    });
    if (sugenoConst != 0 || parts.isEmpty) parts.add(_fmt(sugenoConst));
    return 'Sugeno: $outputName = ${parts.join(' + ')}';
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  Map<String, dynamic> toJson() => {
        'antecedents': antecedents,
        'connector': connector.name,
        'consequent': consequent,
        'sugenoCoefs': sugenoCoefs,
        'sugenoConst': sugenoConst,
        'weight': weight,
      };

  factory FuzzyRule.fromJson(Map<String, dynamic> j) {
    final coefs = j['sugenoCoefs'];
    return FuzzyRule(
      antecedents: Map<String, String>.from(j['antecedents'] as Map),
      connector: Connector.values.byName(j['connector'] as String),
      consequent: j['consequent'] as String?,
      sugenoCoefs: coefs == null
          ? null
          : (coefs as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
      sugenoConst: (j['sugenoConst'] as num?)?.toDouble() ?? 0,
      weight: (j['weight'] as num?)?.toDouble() ?? 1,
    );
  }
}