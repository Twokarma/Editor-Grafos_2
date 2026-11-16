import '../../models/fuzzy/fuzzy_system.dart';
import 'fuzzy_common.dart';

class SugenoResult {
  final double value;

  /// Peso (fuerza de disparo) wᵢ de cada regla.
  final List<double> weights;

  /// Salida zᵢ de cada regla.
  final List<double> outputs;

  final bool active;

  const SugenoResult({
    required this.value,
    required this.weights,
    required this.outputs,
    required this.active,
  });
}

/// Inferencia Sugeno (Takagi-Sugeno): y = Σ wᵢ·zᵢ / Σ wᵢ
/// con zᵢ = Σ aᵢⱼ·xⱼ + cᵢ (orden 1) o zᵢ = cᵢ (orden 0).
class Sugeno {
  static SugenoResult evaluate(FuzzySystem s, Map<String, double> x) {
    final weights = <double>[];
    final outputs = <double>[];
    double numer = 0, denom = 0;

    for (final r in s.rules) {
      final coefs = r.sugenoCoefs;
      if (coefs == null) {
        weights.add(0);
        outputs.add(0);
        continue;
      }
      final w = ruleFiring(s, r, x);
      double z = r.sugenoConst;
      coefs.forEach((name, a) {
        final v = s.inputByName(name);
        if (v == null) return;
        z += a * (x[name] ?? v.min);
      });
      weights.add(w);
      outputs.add(z);
      numer += w * z;
      denom += w;
    }

    final out = s.output;
    return SugenoResult(
      value: denom > 0 ? numer / denom : (out.min + out.max) / 2,
      weights: weights,
      outputs: outputs,
      active: denom > 0,
    );
  }
}