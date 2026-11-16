import 'package:flutter/material.dart';

import '../../models/fuzzy/fuzzy_variable.dart';
import '../../models/fuzzy/membership_function.dart';
import 'fuzzy_utils.dart';

/// Resultado del diálogo: nombre del término y su función de pertenencia.
class TermResult {
  final String name;
  final MF mf;
  const TermResult(this.name, this.mf);
}

/// Abre el diálogo para crear un término nuevo o, si [editing] no es null,
/// para editar el término existente con ese nombre.
Future<TermResult?> showTermDialog(
  BuildContext context, {
  required FuzzyVariable variable,
  String? editing,
}) =>
    showDialog<TermResult>(
      context: context,
      builder: (_) => _TermDialog(variable: variable, editing: editing),
    );

class _TermDialog extends StatefulWidget {
  final FuzzyVariable variable;
  final String? editing;
  const _TermDialog({required this.variable, this.editing});

  @override
  State<_TermDialog> createState() => _TermDialogState();
}

class _TermDialogState extends State<_TermDialog> {
  late final TextEditingController _name;
  late String _type;
  List<TextEditingController> _ctrls = [];

  FuzzyVariable get _v => widget.variable;

  @override
  void initState() {
    super.initState();
    final old = widget.editing == null ? null : _v.terms[widget.editing!];
    _name = TextEditingController(text: widget.editing ?? '');
    _type = old?.type ?? MF.types.first;
    _rebuild(old?.params ?? MF.defaults(_type, _v.min, _v.max));
  }

  @override
  void dispose() {
    _name.dispose();
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _rebuild(List<double> values) {
    for (final c in _ctrls) {
      c.dispose();
    }
    _ctrls = values.map((x) => TextEditingController(text: fmt(x))).toList();
  }

  List<double>? _parse() {
    final out = <double>[];
    for (final c in _ctrls) {
      final x = parseNum(c.text);
      if (x == null) return null;
      out.add(x);
    }
    return out;
  }

  /// Devuelve el error actual o null si todo es válido.
  String? _error() {
    final nombre = _name.text.trim();
    if (nombre.isEmpty) return 'Escribe un nombre.';
    if (!RegExp(r'^[A-Za-z0-9_áéíóúñÁÉÍÓÚÑ]+$').hasMatch(nombre)) {
      return 'Usa solo letras, números o _ (sin espacios).';
    }
    if (nombre != widget.editing && _v.terms.containsKey(nombre)) {
      return 'Ya existe un término con ese nombre.';
    }
    final p = _parse();
    if (p == null) return 'Todos los parámetros deben ser números.';
    return MF.validate(_type, p);
  }

  @override
  Widget build(BuildContext context) {
    final error = _error();
    final p = _parse();
    final mf = (p != null && MF.validate(_type, p) == null)
        ? MF.create(_type, p)
        : null;
    final labels = MF.paramLabels(_type);

    return AlertDialog(
      title: Text(widget.editing == null
          ? 'Nuevo término en ${_v.name}'
          : 'Editar "${widget.editing}"'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration:
                    const InputDecoration(labelText: 'Nombre (p. ej. bajo)'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Tipo de función'),
                child: DropdownButton<String>(
                  value: _type,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: [
                    for (final t in MF.types)
                      DropdownMenuItem(value: t, child: Text(MF.typeLabel(t))),
                  ],
                  onChanged: (t) {
                    if (t == null) return;
                    setState(() {
                      _type = t;
                      _rebuild(MF.defaults(t, _v.min, _v.max));
                    });
                  },
                ),
              ),
              for (var i = 0; i < _ctrls.length; i++)
                TextField(
                  controller: _ctrls[i],
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  decoration: InputDecoration(labelText: labels[i]),
                  onChanged: (_) => setState(() {}),
                ),
              const SizedBox(height: 12),
              SizedBox(
                height: 90,
                width: double.infinity,
                child: CustomPaint(
                    painter: _PreviewPainter(mf, _v.min, _v.max)),
              ),
              const SizedBox(height: 4),
              Text(
                'Rango de la variable: ${fmt(_v.min)} a ${fmt(_v.max)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    error,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
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
        FilledButton(
          onPressed: error == null
              ? () => Navigator.pop(
                    context,
                    TermResult(_name.text.trim(), MF.create(_type, _parse()!)),
                  )
              : null,
          child: Text(widget.editing == null ? 'Agregar' : 'Guardar'),
        ),
      ],
    );
  }
}

class _PreviewPainter extends CustomPainter {
  final MF? mf;
  final double min, max;
  _PreviewPainter(this.mf, this.min, this.max);

  @override
  void paint(Canvas canvas, Size size) {
    final eje = Paint()
      ..color = Colors.grey.withOpacity(.5)
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(0, size.height), Offset(size.width, size.height), eje);

    final f = mf;
    if (f == null) return;

    final path = Path();
    const n = 101;
    for (var i = 0; i < n; i++) {
      final x = min + (max - min) * i / (n - 1);
      final dx = size.width * i / (n - 1);
      final dy = size.height * (1 - f.eval(x).clamp(0.0, 1.0));
      i == 0 ? path.moveTo(dx, dy) : path.lineTo(dx, dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.lightBlueAccent,
    );
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter old) =>
      old.mf != mf || old.min != min || old.max != max;
}