import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/fuzzy_provider.dart';
import 'fuzzy_utils.dart';
import 'membership_chart.dart';

/// Pestaña "Simulación": sliders de entrada, resultado y gráficas.
class SimulationTab extends StatelessWidget {
  const SimulationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final fz = context.watch<FuzzyProvider>();
    final sys = fz.system;

    if (sys.inputs.isEmpty || sys.rules.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Define al menos una variable de entrada y una regla para simular.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final isMamdani = fz.method == FuzzyMethod.mamdani;
    final result = fz.result;
    final mr = fz.mamdaniResult;
    final sr = fz.sugenoResult;
    final firing = fz.firing;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // ---- Entradas
        for (final v in sys.inputs)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${v.name} = ${fmt(fz.inputValues[v.name] ?? v.min)}',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    min: v.min,
                    max: v.max,
                    value: (fz.inputValues[v.name] ?? v.min)
                        .clamp(v.min, v.max)
                        .toDouble(),
                    onChanged: (val) => fz.setInputValue(v.name, val),
                  ),
                  MembershipChart(
                    variable: v,
                    marker: fz.inputValues[v.name],
                    height: 130,
                  ),
                ],
              ),
            ),
          ),

        // ---- Resultado
        Card(
          color: theme.colorScheme.primaryContainer,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  isMamdani
                      ? 'Resultado · Mamdani (centroide)'
                      : 'Resultado · Sugeno (promedio ponderado)',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  result == null
                      ? '—'
                      : '${sys.output.name} = ${fmt(result, decimals: 3)}',
                  style: theme.textTheme.headlineMedium,
                ),
                if (!fz.active)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Ninguna regla se activa con estos valores.',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ---- Activación de reglas
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activación de reglas',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < firing.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(width: 32, child: Text('R${i + 1}')),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: firing[i].clamp(0.0, 1.0).toDouble(),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 120,
                          child: Text(
                            isMamdani || sr == null
                                ? 'w = ${fmt(firing[i], decimals: 3)}'
                                : 'w=${fmt(firing[i])}  z=${fmt(sr.outputs[i])}',
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ---- Salida agregada (solo Mamdani)
        if (isMamdani && mr != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Salida difusa agregada',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  MembershipChart(
                    variable: sys.output,
                    marker: mr.active ? mr.value : null,
                    aggX: mr.xs,
                    aggMu: mr.mu,
                    height: 200,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}