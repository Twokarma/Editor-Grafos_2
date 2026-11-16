import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:graph_maker_app_2/algorithms/sorts.dart';

Future<List<SortMarks>> _run(SortKind kind, List<int> values, {bool Function(int step)? cancelAt}) async {
  final List<SortMarks> seen = [];
  int steps = 0;
  final session = SortSession(
    values: values,
    onChange: seen.add,
    pauseFor: (_) => Duration.zero,
    isCancelled: () => cancelAt != null && cancelAt(steps++),
  );
  await kind.run(session);
  return seen;
}

void main() {
  for (final SortKind kind in SortKind.values) {
    group(kind.title, () {
      test('sorts a shuffled list', () async {
        final List<int> values = List<int>.generate(20, (i) => i + 1)..shuffle(Random(3));
        await _run(kind, values);
        expect(values, List<int>.generate(20, (i) => i + 1));
      });

      test('sorts values with repeats', () async {
        final List<int> values = [5, 3, 5, 1, 99, 3, 1];
        await _run(kind, values);
        expect(values, [1, 1, 3, 3, 5, 5, 99]);
      });

      test('handles one value and an already sorted list', () async {
        final List<int> one = [7];
        await _run(kind, one);
        expect(one, [7]);
        final List<int> sorted = [1, 2, 3, 4];
        await _run(kind, sorted);
        expect(sorted, [1, 2, 3, 4]);
      });

      test('stops as soon as it is cancelled and keeps the values intact', () async {
        final List<int> values = [9, 8, 7, 6, 5, 4, 3, 2, 1];
        await _run(kind, values, cancelAt: (step) => step >= 3);
        expect(values.toList()..sort(), [1, 2, 3, 4, 5, 6, 7, 8, 9]);
        expect(values, isNot([1, 2, 3, 4, 5, 6, 7, 8, 9]));
      });

      test('only marks positions inside the list', () async {
        final List<int> values = [4, 2, 3, 1];
        final marks = await _run(kind, values);
        expect(marks, isNotEmpty);
        for (final SortMarks m in marks) {
          for (final int index in [m.current, m.compared, m.target, m.rangeStart, m.rangeEnd]) {
            expect(index, inInclusiveRange(-1, values.length - 1));
          }
        }
      });
    });
  }

  test('roles: current wins over compared, range and sorted prefix', () {
    const marks = SortMarks(current: 2, compared: 3, target: 0, rangeStart: 2, rangeEnd: 5, sortedCount: 1);
    expect(marks.roleOf(2), SortRole.current);
    expect(marks.roleOf(3), SortRole.compared);
    expect(marks.roleOf(4), SortRole.compared);
    expect(marks.roleOf(0), SortRole.target);
    expect(marks.roleOf(6), isNull);
    expect(const SortMarks(sortedCount: 2).roleOf(1), SortRole.sorted);
  });
}
