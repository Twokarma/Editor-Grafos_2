import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/algorithms/sorts.dart';
import 'package:graph_maker_app_2/layout/breakpoints.dart';
import 'package:graph_maker_app_2/layout/editor_shell.dart';
import 'package:graph_maker_app_2/layout/options_config.dart';
import 'package:graph_maker_app_2/models/velocidad.dart';
import 'package:graph_maker_app_2/screens/pdf_viewer_screen.dart';
import 'package:graph_maker_app_2/services/sort_storage_service.dart';
import 'package:graph_maker_app_2/tours/tree_sort_tours.dart';
import 'package:graph_maker_app_2/widgets/dialogs/sort_guardado_dialogs.dart';
import 'package:graph_maker_app_2/widgets/panels/sort_functions.dart';
import 'package:graph_maker_app_2/widgets/sort/sort_canvas.dart';

class SortScreen extends StatefulWidget {
  final SortKind kind;

  const SortScreen({super.key, required this.kind});

  @override
  State<SortScreen> createState() => _SortScreenState();
}

class _SortScreenState extends State<SortScreen> {
  static const int maxBolos = 20;
  static const int valorMax = 99;
  static const int _initialCount = 8;
  static const String _storageGroup = SortStorageService.grupoCompartido;

  final Random _random = Random();
  final SortStorageService _storage = SortStorageService();
  final SortTourKeys _tourKeys = SortTourKeys();
  final ValueNotifier<int> _shuffles = ValueNotifier<int>(0);

  late List<int> _values;
  Velocidad _speed = Velocidad.normal;
  SortMarks _marks = const SortMarks();
  bool _running = false;
  int _runId = 0;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _values = _shuffled(_initialCount);
  }

  @override
  void dispose() {
    _runId++;
    _ticker?.cancel();
    _shuffles.dispose();
    super.dispose();
  }

  List<int> _shuffled(int n) => List<int>.generate(n, (i) => i + 1)..shuffle(_random);

  Duration _pauseFor(SortPause pause) => Duration(milliseconds: (pause.milliseconds * _speed.factor).round());

  Duration get _liftDuration => Duration(milliseconds: (100 * _speed.factor).round().clamp(30, 250));

  String get _time {
    final int ms = _stopwatch.elapsedMilliseconds;
    final String minutes = (ms ~/ 60000).toString().padLeft(2, '0');
    final String seconds = ((ms ~/ 1000) % 60).toString().padLeft(2, '0');
    final String tenths = ((ms % 1000) ~/ 100).toString();
    return '$minutes:$seconds.$tenths';
  }

  void _setValues(List<int> values) {
    setState(() {
      _values = values;
      _marks = const SortMarks();
      _stopwatch.reset();
    });
  }

  void _stopClock() {
    _stopwatch.stop();
    _ticker?.cancel();
    _ticker = null;
  }

  void _stop() {
    _runId++;
    _stopClock();
    setState(() {
      _running = false;
      _marks = const SortMarks();
    });
  }

  Future<void> _solve() async {
    if (_running) return;
    final int id = ++_runId;
    setState(() {
      _running = true;
      _marks = const SortMarks();
    });
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });

    final SortSession session = SortSession(
      values: _values,
      onChange: (marks) {
        if (mounted && id == _runId) setState(() => _marks = marks);
      },
      pauseFor: _pauseFor,
      isCancelled: () => !mounted || id != _runId,
    );
    await widget.kind.run(session);

    if (!mounted || id != _runId) return;
    _stopClock();
    setState(() {
      _running = false;
      _marks = SortMarks(sortedCount: _values.length);
    });
  }

  void _shuffle() {
    _setValues(List<int>.of(_values)..shuffle(_random));
    _shuffles.value++;
  }

  void _randomValues() => _setValues(List<int>.generate(_values.length, (_) => _random.nextInt(valorMax) + 1));

  void _changeCount(int count) {
    if (count == _values.length) return;
    _setValues(_shuffled(count));
  }

  Future<void> _enterValues() async {
    final TextEditingController controller = TextEditingController(text: _values.join(', '));
    String? error;

    final List<int>? result = await showDialog<List<int>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialog) => AlertDialog(
          title: const Text('Ingresar valores'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Ej: 5, 3, 8, 1',
              helperText: 'Separados por coma o espacio (1 a $valorMax, máx. $maxBolos)',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final List<int?> numbers = controller.text
                    .split(RegExp(r'[,\s]+'))
                    .where((e) => e.isNotEmpty)
                    .map(int.tryParse)
                    .toList();
                String? problem;
                if (numbers.isEmpty) {
                  problem = 'Ingresa al menos un valor';
                } else if (numbers.contains(null)) {
                  problem = 'Solo se permiten números';
                } else if (numbers.any((n) => n! < 1 || n > valorMax)) {
                  problem = 'Cada valor debe estar entre 1 y $valorMax';
                } else if (numbers.length > maxBolos) {
                  problem = 'Máximo $maxBolos valores';
                }
                if (problem != null) {
                  setDialog(() => error = problem);
                } else {
                  Navigator.pop(dialogContext, numbers.cast<int>());
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (result != null && mounted) _setValues(result);
  }

  Future<void> _save() => guardarValoresDialog(
        context: context,
        storage: _storage,
        algoritmo: _storageGroup,
        valores: _values,
      );

  Future<void> _open() async {
    if (_running) _stop();
    final List<int>? values = await cargarValoresDialog(
      context: context,
      storage: _storage,
      algoritmo: _storageGroup,
    );
    if (values == null || !mounted) return;
    _setValues(values);
  }

  void _openManual() => openManual(context, title: widget.kind.title, assetPath: widget.kind.manualAsset);

  @override
  Widget build(BuildContext context) {
    final bool mobile = MediaQuery.sizeOf(context).width < Breakpoints.mobileUntil;

    return EditorShell(
      mode: widget.kind.mode,
      hint: 'Mezcla los bolos y pulsa Resolver',
      canvas: SortCanvas(values: _values, marks: _marks, liftDuration: _liftDuration),
      functions: SortFunctions(
        kind: widget.kind,
        showTimer: !mobile,
        time: _time,
        running: _running,
        count: _values.length,
        maxCount: maxBolos,
        onCountChanged: _changeCount,
        speed: _speed,
        onSpeedChanged: (speed) => setState(() => _speed = speed),
        onShuffle: _shuffle,
        onSolve: _solve,
        onStop: _stop,
        onRandom: _randomValues,
        onEnter: _enterValues,
        keys: _tourKeys,
      ),
      summary: SortTimer(time: _time, fontSize: 22),
      options: OptionsConfig(
        onSave: _save,
        onOpen: _open,
        onManual: _openManual,
      ),
      tour: sortTour(
        kind: widget.kind,
        keys: _tourKeys,
        shuffles: _shuffles,
        onStart: () {
          if (_running) _stop();
        },
      ),
    );
  }
}
