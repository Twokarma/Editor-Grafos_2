import 'dart:math' as math;

/// Especificación de un tipo de función de pertenencia.
/// Agregar un tipo nuevo = una entrada en [MF.registry] + su clase.
class MFSpec {
  final String label;
  final List<String> paramLabels;
  final MF Function(List<double> p) build;
  final String? Function(List<double> p) validate;
  final List<double> Function(double min, double max) defaults;

  const MFSpec({
    required this.label,
    required this.paramLabels,
    required this.build,
    required this.validate,
    required this.defaults,
  });
}

/// Funciones de pertenencia con los mismos nombres que usa MATLAB:
/// `trimf`, `trapmf`, `gaussmf`, `gbellmf`, `sigmf`, `zmf` y `smf`
/// (facilita importar archivos .fis más adelante).
abstract class MF {
  const MF();

  /// 'trimf' | 'trapmf' | 'gaussmf' | 'gbellmf' | 'sigmf' | 'zmf' | 'smf'
  String get type;

  List<double> get params;

  /// Grado de pertenencia de [x] (entre 0 y 1).
  double eval(double x);

  Map<String, dynamic> toJson() => {'type': type, 'params': params};

  factory MF.fromJson(Map<String, dynamic> json) {
    final p =
        (json['params'] as List).map((e) => (e as num).toDouble()).toList();
    return MF.create(json['type'] as String, p);
  }

  // ---------------------------------------------------------------------------
  // Registro de tipos
  // ---------------------------------------------------------------------------
  static final Map<String, MFSpec> registry = {
    'trimf': MFSpec(
      label: 'Triangular (trimf)',
      paramLabels: ['a (inicio)', 'b (pico)', 'c (fin)'],
      build: (p) => Triangular(p[0], p[1], p[2]),
      validate: (p) => (p[0] <= p[1] && p[1] <= p[2] && p[0] < p[2])
          ? null
          : 'Debe cumplirse a ≤ b ≤ c (con a < c).',
      defaults: (mn, mx) {
        final r = mx - mn;
        return [mn + .25 * r, mn + .5 * r, mn + .75 * r];
      },
    ),
    'trapmf': MFSpec(
      label: 'Trapezoidal (trapmf)',
      paramLabels: [
        'a (inicio)',
        'b (inicio meseta)',
        'c (fin meseta)',
        'd (fin)'
      ],
      build: (p) => Trapezoidal(p[0], p[1], p[2], p[3]),
      validate: (p) =>
          (p[0] <= p[1] && p[1] <= p[2] && p[2] <= p[3] && p[0] < p[3])
              ? null
              : 'Debe cumplirse a ≤ b ≤ c ≤ d (con a < d).',
      defaults: (mn, mx) {
        final r = mx - mn;
        return [mn + .1 * r, mn + .3 * r, mn + .7 * r, mn + .9 * r];
      },
    ),
    'gaussmf': MFSpec(
      label: 'Gaussiana (gaussmf)',
      paramLabels: ['σ (sigma)', 'c (centro)'],
      build: (p) => Gaussian(p[0], p[1]),
      validate: (p) => p[0] > 0 ? null : 'σ debe ser mayor que 0.',
      defaults: (mn, mx) => [.15 * (mx - mn), mn + .5 * (mx - mn)],
    ),
    'gbellmf': MFSpec(
      label: 'Campana generalizada (gbellmf)',
      paramLabels: ['a (ancho)', 'b (pendiente)', 'c (centro)'],
      build: (p) => GBell(p[0], p[1], p[2]),
      validate: (p) => (p[0] != 0 && p[1] > 0) ? null : 'a ≠ 0 y b > 0.',
      defaults: (mn, mx) => [.2 * (mx - mn), 2, mn + .5 * (mx - mn)],
    ),
    'sigmf': MFSpec(
      label: 'Sigmoidal (sigmf)',
      paramLabels: ['a (pendiente)', 'c (punto medio)'],
      build: (p) => Sigmoidal(p[0], p[1]),
      validate: (p) => p[0] != 0 ? null : 'a debe ser distinto de 0.',
      defaults: (mn, mx) => [10 / (mx - mn), mn + .5 * (mx - mn)],
    ),
    'zmf': MFSpec(
      label: 'Forma Z (zmf)',
      paramLabels: ['a (inicio caída)', 'b (fin caída)'],
      build: (p) => ZShape(p[0], p[1]),
      validate: (p) => p[0] < p[1] ? null : 'Debe cumplirse a < b.',
      defaults: (mn, mx) => [mn + .3 * (mx - mn), mn + .7 * (mx - mn)],
    ),
    'smf': MFSpec(
      label: 'Forma S (smf)',
      paramLabels: ['a (inicio subida)', 'b (fin subida)'],
      build: (p) => SShape(p[0], p[1]),
      validate: (p) => p[0] < p[1] ? null : 'Debe cumplirse a < b.',
      defaults: (mn, mx) => [mn + .3 * (mx - mn), mn + .7 * (mx - mn)],
    ),
  };

  static MF create(String type, List<double> p) {
    final spec = registry[type];
    if (spec == null) {
      throw FormatException('Tipo de función desconocido: $type');
    }
    return spec.build(p);
  }

  static List<String> get types => registry.keys.toList();

  static String typeLabel(String type) => registry[type]?.label ?? type;

  static int paramCount(String type) => registry[type]!.paramLabels.length;

  static List<String> paramLabels(String type) => registry[type]!.paramLabels;

  /// Devuelve un mensaje de error o null si los parámetros son válidos.
  static String? validate(String type, List<double> p) =>
      registry[type]!.validate(p);

  /// Parámetros por defecto proporcionales al rango [min, max] de la variable.
  static List<double> defaults(String type, double min, double max) =>
      registry[type]!.defaults(min, max);
}

// -----------------------------------------------------------------------------
// Implementaciones
// -----------------------------------------------------------------------------

class Triangular extends MF {
  final double a, b, c;
  const Triangular(this.a, this.b, this.c);

  @override
  String get type => 'trimf';

  @override
  List<double> get params => [a, b, c];

  @override
  double eval(double x) {
    if (x < a || x > c) return 0;
    if (x == b) return 1;
    if (x < b) return (x - a) / (b - a);
    return (c - x) / (c - b);
  }
}

class Trapezoidal extends MF {
  final double a, b, c, d;
  const Trapezoidal(this.a, this.b, this.c, this.d);

  @override
  String get type => 'trapmf';

  @override
  List<double> get params => [a, b, c, d];

  @override
  double eval(double x) {
    if (x < a || x > d) return 0;
    if (x >= b && x <= c) return 1;
    if (x < b) return (x - a) / (b - a);
    return (d - x) / (d - c);
  }
}

/// Igual que `gaussmf` de MATLAB: parámetros [sigma, centro].
class Gaussian extends MF {
  final double sigma;
  final double mean;
  const Gaussian(this.sigma, this.mean);

  @override
  String get type => 'gaussmf';

  @override
  List<double> get params => [sigma, mean];

  @override
  double eval(double x) {
    if (sigma <= 0) return x == mean ? 1 : 0;
    final d = x - mean;
    return math.exp(-(d * d) / (2 * sigma * sigma));
  }
}

/// `gbellmf` de MATLAB: 1 / (1 + |(x-c)/a|^(2b)). Parámetros [a, b, c].
class GBell extends MF {
  final double a, b, c;
  const GBell(this.a, this.b, this.c);

  @override
  String get type => 'gbellmf';

  @override
  List<double> get params => [a, b, c];

  @override
  double eval(double x) {
    if (a == 0) return x == c ? 1 : 0;
    return 1 / (1 + math.pow(((x - c) / a).abs(), 2 * b).toDouble());
  }
}

/// `sigmf` de MATLAB: 1 / (1 + e^(-a(x-c))). Parámetros [a, c].
class Sigmoidal extends MF {
  final double a, c;
  const Sigmoidal(this.a, this.c);

  @override
  String get type => 'sigmf';

  @override
  List<double> get params => [a, c];

  @override
  double eval(double x) => 1 / (1 + math.exp(-a * (x - c)));
}

/// `zmf`: vale 1 a la izquierda de [a], cae suavemente hasta 0 en [b].
class ZShape extends MF {
  final double a, b;
  const ZShape(this.a, this.b);

  @override
  String get type => 'zmf';

  @override
  List<double> get params => [a, b];

  @override
  double eval(double x) {
    if (x <= a) return 1;
    if (x >= b) return 0;
    final m = (a + b) / 2;
    final w = b - a;
    if (x <= m) {
      final t = (x - a) / w;
      return 1 - 2 * t * t;
    }
    final t = (x - b) / w;
    return 2 * t * t;
  }
}

/// `smf`: vale 0 a la izquierda de [a], sube suavemente hasta 1 en [b].
class SShape extends MF {
  final double a, b;
  const SShape(this.a, this.b);

  @override
  String get type => 'smf';

  @override
  List<double> get params => [a, b];

  @override
  double eval(double x) {
    if (x <= a) return 0;
    if (x >= b) return 1;
    final m = (a + b) / 2;
    final w = b - a;
    if (x <= m) {
      final t = (x - a) / w;
      return 2 * t * t;
    }
    final t = (x - b) / w;
    return 1 - 2 * t * t;
  }
}