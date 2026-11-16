import 'dart:math' as math;

import '../../models/fuzzy/fuzzy_system.dart';
import 'fuzzy_common.dart';

class MamdaniResult {
  /// Valor nítido (defuzzificado por centroide).
  final double value;

  /// Puntos de la curva de salida agregada (para graficar).
  final List<double> xs;
  final List<double> mu;

  /// Fuerza de disparo de cada regla (mismo orden que system.rules).
  final List<double> firing;

  /// false si ninguna regla se activó.
  final bool active;

  const MamdaniResult({
    required this.value,
    required this.xs,
    required this.mu,
    required this.firing,
    required this.active,
  });
}

/// Inferencia Mamdani: implicación = mínimo (recorte), agregación = máximo,
/// defuzzificación = centroide.
class Mamdani {
  static MamdaniResult evaluate(
    FuzzySystem s,
    Map<String, double> x, {
    int samples = 500,
  }) {
    final out = s.output;
    final firing = s.rules.map((r) => ruleFiring(s, r, x)).toList();

    final xs = <double>[];
    final mus = <double>[];
    final step = (out.max - out.min) / samples;
    double numer = 0, denom = 0;

    for (int i = 0; i <= samples; i++) {
      final z = out.min + i * step;
      double mu = 0;
      for (int k = 0; k < s.rules.length; k++) {
        if (firing[k] <= 0) continue;
        final term = s.rules[k].consequent;
        final mf = term == null ? null : out.terms[term];
        if (mf == null) continue;
        mu = math.max(mu, math.min(firing[k], mf.eval(z)));
      }
      xs.add(z);
      mus.add(mu);
      numer += z * mu;
      denom += mu;
    }

    return MamdaniResult(
      value: denom > 0 ? numer / denom : (out.min + out.max) / 2,
      xs: xs,
      mu: mus,
      firing: firing,
      active: denom > 0,
    );
  }
}