import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/fuzzy/fuzzy_variable.dart';
import '../../providers/fuzzy_provider.dart';
import 'fuzzy_utils.dart';
import 'membership_chart.dart';
import 'term_dialog.dart';

/// Pestaña "Variables": entradas, salida y sus términos (funciones de pertenencia).
class VariableEditor extends StatelessWidget {
  const VariableEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final fz = context.watch<FuzzyProvider>();
    final sys = fz.system;
    final titleStyle = Theme.of(context).textTheme.titleMedium;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('Entradas', style: titleStyle),
        const SizedBox(height: 8),
        if (sys.inputs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Aún no hay variables de entrada.'),
          ),
        for (final v in sys.inputs) _VariableCard(variable: v, isOutput: false),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Agregar entrada'),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => _VariableDialog(
                title: 'Nueva variable de entrada',
                onSubmit: (name, min, max) => fz.addInput(name, min, max),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Salida', style: titleStyle),
        const SizedBox(height: 8),
        _VariableCard(variable: sys.output, isOutput: true),
      ],
    );
  }
}

class _VariableCard extends StatelessWidget {
  final FuzzyVariable variable;
  final bool isOutput;

  const _VariableCard({required this.variable, required this.isOutput});

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addTerm(BuildContext context, FuzzyProvider fz) async {
    final r = await showTermDialog(context, variable: variable);
    if (r == null || !context.mounted) return;
    final err = fz.addTerm(variable.name, r.name, r.mf);
    if (err != null) _snack(context, err);
  }

  Future<void> _editTerm(
      BuildContext context, FuzzyProvider fz, String term) async {
    final r = await showTermDialog(context, variable: variable, editing: term);
    if (r == null || !context.mounted) return;
    final err = fz.updateTerm(variable.name, term, r.name, r.mf);
    if (err != null) _snack(context, err);
  }

  @override
  Widget build(BuildContext context) {
    final fz = context.read<FuzzyProvider>();
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${variable.name}  [${fmt(variable.min)}, ${fmt(variable.max)}]',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Editar nombre y rango',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _VariableDialog(
                      title: 'Editar ${variable.name}',
                      initialName: variable.name,
                      initialMin: variable.min,
                      initialMax: variable.max,
                      onSubmit: (name, min, max) => fz.updateVariable(
                        variable.name,
                        newName: name,
                        min: min,
                        max: max,
                      ),
                    ),
                  ),
                ),
                if (!isOutput)
                  IconButton(
                    tooltip: 'Eliminar variable',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => fz.removeInput(variable.name),
                  ),
              ],
            ),
            MembershipChart(variable: variable, height: 150),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final t in variable.terms.entries)
                  Tooltip(
                    message: 'Toca para editar',
                    child: InputChip(
                      label: Text('${t.key} (${t.value.type})'),
                      onPressed: () => _editTerm(context, fz, t.key),
                      onDeleted: () => fz.removeTerm(variable.name, t.key),
                    ),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Término'),
                  onPressed: () => _addTerm(context, fz),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Diálogo: variable (nombre + rango)
// ---------------------------------------------------------------------------

class _VariableDialog extends StatefulWidget {
  final String title;
  final String initialName;
  final double initialMin;
  final double initialMax;
  final bool nameEnabled;
  final String? Function(String name, double min, double max) onSubmit;

  const _VariableDialog({
    required this.title,
    required this.onSubmit,
    this.initialName = '',
    this.initialMin = 0,
    this.initialMax = 10,
    this.nameEnabled = true,
  });

  @override
  State<_VariableDialog> createState() => _VariableDialogState();
}

class _VariableDialogState extends State<_VariableDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName);
  late final TextEditingController _min =
      TextEditingController(text: fmt(widget.initialMin));
  late final TextEditingController _max =
      TextEditingController(text: fmt(widget.initialMax));
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _submit() {
    final min = parseNum(_min.text);
    final max = parseNum(_max.text);
    if (min == null || max == null) {
      setState(() => _error = 'Rango inválido.');
      return;
    }
    final err = widget.onSubmit(_name.text, min, max);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const numberKeyboard =
        TextInputType.numberWithOptions(decimal: true, signed: true);
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              enabled: widget.nameEnabled,
              decoration: const InputDecoration(
                labelText: 'Nombre (sin espacios)',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _min,
                    keyboardType: numberKeyboard,
                    decoration: const InputDecoration(labelText: 'Mínimo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _max,
                    keyboardType: numberKeyboard,
                    decoration: const InputDecoration(labelText: 'Máximo'),
                  ),
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Aceptar')),
      ],
    );
  }
}