import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/fuzzy_provider.dart';
import '../../services/fuzzy_library_service.dart';

String _two(int n) => n.toString().padLeft(2, '0');

String _fecha(DateTime d) =>
    '${_two(d.day)}/${_two(d.month)}/${d.year} ${_two(d.hour)}:${_two(d.minute)}';

// ---------------------------------------------------------------------------
// Guardar con nombre
// ---------------------------------------------------------------------------

/// Pide un nombre y guarda el sistema actual. Si el nombre ya existe,
/// pide confirmación antes de sobrescribir.
Future<void> showSaveSystemDialog(BuildContext context) async {
  final fz = context.read<FuzzyProvider>();
  final messenger = ScaffoldMessenger.of(context);

  final name = await showDialog<String>(
    context: context,
    builder: (_) => _SaveDialog(provider: fz),
  );
  if (name == null) return;

  final err = await fz.saveAs(name);
  messenger.showSnackBar(
    SnackBar(content: Text(err ?? 'Sistema "${name.trim()}" guardado')),
  );
}

class _SaveDialog extends StatefulWidget {
  final FuzzyProvider provider;
  const _SaveDialog({required this.provider});

  @override
  State<_SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends State<_SaveDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.provider.system.name);
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final n = _name.text.trim();
    if (n.isEmpty) {
      setState(() => _error = 'Escribe un nombre.');
      return;
    }
    setState(() => _busy = true);
    final exists = await widget.provider.namedExists(n);
    if (!mounted) return;

    if (exists) {
      final overwrite = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Ya existe'),
          content: Text('Ya hay un sistema guardado como "$n". ¿Sobrescribirlo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sobrescribir'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (overwrite != true) {
        setState(() => _busy = false);
        return;
      }
    }
    Navigator.pop(context, n);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Guardar sistema'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nombre del sistema',
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Cargar
// ---------------------------------------------------------------------------

/// Muestra los sistemas guardados y carga el elegido (reemplaza el actual).
Future<void> showLoadSystemDialog(BuildContext context) async {
  final fz = context.read<FuzzyProvider>();
  final messenger = ScaffoldMessenger.of(context);

  final name = await showDialog<String>(
    context: context,
    builder: (_) => _LoadDialog(provider: fz),
  );
  if (name == null) return;

  final err = await fz.loadNamed(name);
  messenger.showSnackBar(
    SnackBar(content: Text(err ?? 'Sistema "$name" cargado')),
  );
}

class _LoadDialog extends StatefulWidget {
  final FuzzyProvider provider;
  const _LoadDialog({required this.provider});

  @override
  State<_LoadDialog> createState() => _LoadDialogState();
}

class _LoadDialogState extends State<_LoadDialog> {
  late Future<List<SavedSystemInfo>> _items = widget.provider.listNamed();

  void _refresh() =>
      setState(() => _items = widget.provider.listNamed());

  Future<void> _confirmDelete(SavedSystemInfo info) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar'),
        content: Text('¿Eliminar "${info.name}"? No se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.provider.deleteNamed(info.name);
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Cargar sistema'),
      content: SizedBox(
        width: 420,
        child: FutureBuilder<List<SavedSystemInfo>>(
          future: _items,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final items = snap.data ?? const <SavedSystemInfo>[];
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Aún no hay sistemas guardados.\n'
                  'Usa el botón Guardar para crear el primero.',
                ),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final it = items[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.psychology_outlined),
                        title: Text(it.name),
                        subtitle: Text(
                          '${it.inputs} entradas · ${it.rules} reglas · '
                          '${_fecha(it.savedAt)}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Eliminar',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(it),
                        ),
                        onTap: () => Navigator.pop(context, it.name),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Al cargar se reemplaza el sistema actual. '
                  'Guárdalo antes si quieres conservarlo.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}