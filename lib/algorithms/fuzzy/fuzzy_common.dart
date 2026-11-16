import 'dart:math' as math;

import '../../models/fuzzy/fuzzy_rule.dart';
import '../../models/fuzzy/fuzzy_system.dart';

/// Fuerza de disparo de una regla: AND = mínimo, OR = máximo.
double ruleFiring(FuzzySystem s, FuzzyRule r, Map<String, double> x) {
  final degrees = <double>[];
  for (final e in r.antecedents.entries) {
    final variable = s.inputByName(e.key);
    final mf = variable?.terms[e.value];
    if (variable == null || mf == null) continue;
    final value = (x[e.key] ?? variable.min)
        .clamp(variable.min, variable.max)
        .toDouble();
    degrees.add(mf.eval(value));
  }
  if (degrees.isEmpty) return 0;
  final d = r.connector == Connector.and
      ? degrees.reduce(math.min)
      : degrees.reduce(math.max);
  return d * r.weight;
}