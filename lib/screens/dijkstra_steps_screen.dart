import 'package:flutter/material.dart';

import '../algorithms/dijkstra.dart';

/// Paso a paso de Dijkstra: en cada vuelta se fija el nodo más cercano aún no
/// visitado y se intenta mejorar la distancia de sus vecinos.
class DijkstraStepsScreen extends StatelessWidget {
  final DijkstraResult result;

  /// Nombre de cada nodo por id.
  final Map<String, String> names;

  const DijkstraStepsScreen({super.key, required this.result, required this.names});

  String _fmt(double v) {
    if (v == double.infinity) return '∞';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  Widget _summary(BuildContext context) {
    final r = result;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r.reachable
                  ? 'Shortest distance: ${_fmt(r.totalDistance)}'
                  : 'No path found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text('From ${names[r.sourceId]} to ${names[r.targetId]}.'),
            if (r.reachable)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(r.pathNodeIds.map((id) => names[id]).join(' → ')),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${names[r.targetId]} cannot be reached from ${names[r.sourceId]}.',
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
    final isTarget = step.nodeId == result.targetId;

    return Card(
      color: isTarget ? scheme.primaryContainer : null,
      child: ExpansionTile(
        leading: CircleAvatar(child: Text('${k + 1}')),
        title: Text('Fix ${names[step.nodeId]}  (distance ${_fmt(step.distance)})'),
        subtitle: Text(
          step.relaxations.isEmpty
              ? 'No unvisited neighbours'
              : '${step.relaxations.length} neighbour(s) checked',
        ),
        children: [
          for (final rel in step.relaxations)
            ListTile(
              dense: true,
              leading: Icon(
                rel.improved ? Icons.check_circle_outline : Icons.remove_circle_outline,
                color: rel.improved ? scheme.primary : null,
              ),
              title: Text(
                // → para aristas dirigidas, - para no dirigidas.
                '${names[rel.from]} ${rel.edge.directed ? '→' : '-'} ${names[rel.to]}'
                '   (weight ${_fmt(rel.edge.weight)})',
              ),
              subtitle: Text(
                '${_fmt(step.distance)} + ${_fmt(rel.edge.weight)} = ${_fmt(rel.candidate)}  vs  '
                '${_fmt(rel.previous)}  →  '
                '${rel.improved ? 'improved' : 'kept the old distance'}',
              ),
            ),
        ],
      ),
    );
  }

  Widget _finalDistances(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (final entry in result.distances.entries)
            ListTile(
              dense: true,
              title: Text(names[entry.key] ?? entry.key),
              trailing: Text(_fmt(entry.value)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dijkstra steps')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summary(context),
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 8),
            child: Text('Nodes, from the closest to the farthest',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          const Text(
            'Every round fixes the unvisited node with the smallest known distance '
            'and checks whether going through it shortens the distance to its '
            'neighbours. Non-directed edges (-) can be used in both directions; '
            'directed edges (→) only from their origin to their destination.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          for (var k = 0; k < result.steps.length; k++) _stepTile(context, k),
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 8),
            child: Text('Final distances from ${names[result.sourceId]}',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          _finalDistances(context),
        ],
      ),
    );
  }
}