import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/fuzzy/fuzzy_rule.dart';
import '../../providers/fuzzy_provider.dart';

/// Pestaña "Reglas": lista de reglas y diálogo para crear nuevas.
class RuleEditor extends StatelessWidget {
  const RuleEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final fz = context.watch<FuzzyProvider>();
    final sys = fz.system;

    return Column(
      children: [
        Expanded(
          child: sys.rules.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Aún no hay reglas.\nAgrega una con el botón de abajo.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: sys.rules.length,
                  itemBuilder: (context, i) {
                    final rule = sys.rules[i];
                    final sugeno = rule.sugenoText(sys.output.name);
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 14,
                          child: Text('${i + 1}'),
                        ),
                        title: Text(rule.describe(sys.output.name)),
                        subtitle: sugeno == null ? null : Text(sugeno),
                        trailing: IconButton(
                          tooltip: 'Eliminar regla',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => fz.removeRule(i),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: Text(sys.inputs.isEmpty
                  ? 'Primero agrega variables de entrada'
                  : 'Agregar regla'),
              onPressed: sys.inputs.isEmpty
                  ? null
                  : () => showDialog<void>(
                        context: context,
                        builder: (_) => _RuleDialog(provider: fz),
                      ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RuleDialog extends StatefulWidget {
  final FuzzyProvider provider;
  const _RuleDialog({required this.provider});

  @override
  State<_RuleDialog> createState() => _RuleDialogState();
}

class _RuleDialogState extends State<_RuleDialog> {
  final Map<String, String?> _sel = {};
  Connector _connector = Connector.and;
  String? _consequent;
  String? _error;

  void _submit() {
    final ant = <String, String>{};
    _sel.forEach((k, v) {
      if (v != null) ant[k] = v;
    });
    if (ant.isEmpty) {
      setState(() => _error = 'Selecciona al menos una condición (SI).');
      return;
    }

    if (_consequent == null) {
      setState(() => _error = 'Define la salida Mamdani.');
      return;
    }

    widget.provider.addRule(FuzzyRule(
      antecedents: ant,
      connector: _connector,
      consequent: _consequent,
      sugenoCoefs: null,
      sugenoConst: 0,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final sys = widget.provider.system;
    final theme = Theme.of(context);
    final bold = theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold);

    return AlertDialog(
      title: const Text('Nueva regla'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SI', style: bold),
              const SizedBox(height: 4),
              for (final v in sys.inputs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DropdownButtonFormField<String?>(
                    initialValue: _sel[v.name],
                    isExpanded: true,
                    decoration: InputDecoration(labelText: '${v.name} ES'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('— (ignorar)'),
                      ),
                      for (final t in v.terms.keys)
                        DropdownMenuItem<String?>(value: t, child: Text(t)),
                    ],
                    onChanged: (val) => setState(() => _sel[v.name] = val),
                  ),
                ),
              SegmentedButton<Connector>(
                segments: const [
                  ButtonSegment(value: Connector.and, label: Text('Y (AND)')),
                  ButtonSegment(value: Connector.or, label: Text('O (OR)')),
                ],
                selected: {_connector},
                onSelectionChanged: (s) => setState(() => _connector = s.first),
              ),
              const Divider(height: 28),
              Text('ENTONCES · Mamdani', style: bold),
              const SizedBox(height: 4),
              DropdownButtonFormField<String?>(
                initialValue: _consequent,
                isExpanded: true,
                decoration: InputDecoration(labelText: '${sys.output.name} ES'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('— (seleccionar)'),
                  ),
                  for (final t in sys.output.terms.keys)
                    DropdownMenuItem<String?>(value: t, child: Text(t)),
                ],
                onChanged: (val) => setState(() => _consequent = val),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Agregar')),
      ],
    );
  }
}