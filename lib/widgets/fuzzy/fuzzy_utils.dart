/// Convierte texto a número aceptando coma o punto decimal.
double? parseNum(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

/// Formatea un número quitando ceros sobrantes (2.50 -> 2.5, 3.00 -> 3).
String fmt(double v, {int decimals = 2}) {
  if (!v.isFinite) return '—';
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v
      .toStringAsFixed(decimals)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}