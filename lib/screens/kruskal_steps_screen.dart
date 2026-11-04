import 'package:flutter/material.dart';

import '../algorithms/kruskal.dart';

/// Paso a paso de Kruskal: las aristas en el orden en que se consideraron y
/// qué se decidió con cada una.
class KruskalStepsScreen extends StatelessWidget {
  final KruskalResult result;

  /// Nombre de cada nodo por id.
  final Map<String, String> names;

  const KruskalStepsScreen({super.key, required this.result, required this.names});

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  String _edgeName(KruskalEdge e) => '${names[e.source]} - ${names[e.target]}';

  Widget _summary(BuildContext context) {
    final r = result;
    final kind = r.goal == KruskalGoal.minimum ? 'minimum' : 'maximum';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total weight ($kind): ${_fmt(r.totalWeight)}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${r.treeEdges.length} edges chosen among ${r.steps.length}, '
                'connecting ${r.nodeCount} nodes.'),
            if (!r.isConnected)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'The graph is not connected (${r.components} parts), so this is a '
                  'spanning forest: one tree per part.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stepTile(BuildContext context, int k) {
    final step = result.steps[k];
    final scheme = Theme.of(context).colorScheme;

    final String label;
    final Color? background;
    final IconData icon;
    switch (step.decision) {
      case KruskalDecision.accepted:
        label = 'Accepted: joins two separate groups';
        background = scheme.primaryContainer;
        icon = Icons.check_circle_outline;
        break;
      case KruskalDecision.rejectedCycle:
        label = 'Rejected: it would close a cycle';
        background = scheme.errorContainer;
        icon = Icons.block;
        break;
      case KruskalDecision.skipped:
        label = 'Not needed: the tree was already complete';
        background = null;
        icon = Icons.remove_circle_outline;
        break;
    }

    return Card(
      color: background,
      child: ListTile(
        leading: CircleAvatar(child: Text('${k + 1}')),
        title: Text('${_edgeName(step.edge)}   (weight ${_fmt(step.edge.weight)})'),
        subtitle: Text('$label\n'
            'Groups left: ${step.componentsAfter} · total so far: ${_fmt(step.totalAfter)}'),
        isThreeLine: true,
        trailing: Icon(icon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalWord = result.goal == KruskalGoal.minimum ? 'smallest' : 'largest';
    return Scaffold(
      appBar: AppBar(title: const Text('Kruskal steps')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summary(context),
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 8),
            child: Text('Edges, from the $goalWord weight onwards',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          const Text(
            'Each edge is accepted only if its two ends are in different groups '
            '(otherwise it would close a cycle). Every node starts in its own group '
            'and groups merge as edges are accepted.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (result.steps.isEmpty)
            const Text('There are no edges.')
          else
            for (var k = 0; k < result.steps.length; k++) _stepTile(context, k),
        ],
      ),
    );
  }
}
