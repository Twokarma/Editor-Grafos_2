import 'dart:async';

import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/models/app_mode.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';

enum SortPause {
  compare(120),
  swap(350),
  write(300);

  const SortPause(this.milliseconds);

  final int milliseconds;
}

enum SortRole {
  current(AppColors.sortCurrent),
  compared(AppColors.sortCompared),
  target(AppColors.sortTarget),
  sorted(AppColors.sortSorted);

  const SortRole(this.color);

  final Color color;
}

@immutable
class SortMarks {
  final int current;
  final int compared;
  final int target;
  final int rangeStart;
  final int rangeEnd;
  final int sortedCount;

  const SortMarks({
    this.current = -1,
    this.compared = -1,
    this.target = -1,
    this.rangeStart = -1,
    this.rangeEnd = -1,
    this.sortedCount = 0,
  });

  SortMarks copyWith({int? current, int? compared, int? target, int? rangeStart, int? rangeEnd, int? sortedCount}) {
    return SortMarks(
      current: current ?? this.current,
      compared: compared ?? this.compared,
      target: target ?? this.target,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
      sortedCount: sortedCount ?? this.sortedCount,
    );
  }

  SortRole? roleOf(int index) {
    if (index == current) return SortRole.current;
    if (index == compared) return SortRole.compared;
    if (index >= rangeStart && index <= rangeEnd && rangeStart >= 0) return SortRole.compared;
    if (index == target) return SortRole.target;
    if (index < sortedCount) return SortRole.sorted;
    return null;
  }

  bool isRaised(int index) => index == current || index == compared;
}

class SortSession {
  final List<int> values;
  final void Function(SortMarks marks) onChange;
  final Duration Function(SortPause pause) pauseFor;
  final bool Function() isCancelled;
  SortMarks _marks = const SortMarks();

  SortSession({
    required this.values,
    required this.onChange,
    required this.pauseFor,
    required this.isCancelled,
  });

  SortMarks get marks => _marks;

  void mark(SortMarks marks) {
    _marks = marks;
    onChange(marks);
  }

  void swap(int a, int b) {
    final int temp = values[a];
    values[a] = values[b];
    values[b] = temp;
    onChange(_marks);
  }

  void write(int index, int value) {
    values[index] = value;
    onChange(_marks);
  }

  Future<bool> wait(SortPause pause) async {
    if (isCancelled()) return false;
    await Future<void>.delayed(pauseFor(pause));
    return !isCancelled();
  }
}

class SortLegendEntry {
  final SortRole role;
  final String label;

  const SortLegendEntry(this.role, this.label);
}

enum SortKind {
  selection(
    AppMode.selection,
    'Selection Sort',
    'assets/docs/guia_selection_sort.pdf',
    [
      SortLegendEntry(SortRole.current, 'menor'),
      SortLegendEntry(SortRole.compared, 'comparado'),
      SortLegendEntry(SortRole.target, 'posición'),
      SortLegendEntry(SortRole.sorted, 'en su lugar'),
    ],
  ),
  insertion(
    AppMode.insertion,
    'Insertion Sort',
    'assets/docs/guia_insertion_sort.pdf',
    [
      SortLegendEntry(SortRole.current, 'insertando'),
      SortLegendEntry(SortRole.compared, 'comparado'),
      SortLegendEntry(SortRole.sorted, 'parte ordenada'),
    ],
  ),
  shell(
    AppMode.shell,
    'Shell Sort',
    'assets/docs/guia_shell_sort.pdf',
    [
      SortLegendEntry(SortRole.current, 'actual'),
      SortLegendEntry(SortRole.compared, 'comparado'),
      SortLegendEntry(SortRole.sorted, 'en su lugar'),
    ],
  ),
  merge(
    AppMode.merge,
    'Merge Sort',
    'assets/docs/guia_merge_sort.pdf',
    [
      SortLegendEntry(SortRole.current, 'escribiendo'),
      SortLegendEntry(SortRole.compared, 'tramo que se mezcla'),
      SortLegendEntry(SortRole.sorted, 'en su lugar'),
    ],
  );

  const SortKind(this.mode, this.title, this.manualAsset, this.legend);

  final AppMode mode;
  final String title;
  final String manualAsset;
  final List<SortLegendEntry> legend;

  Future<void> run(SortSession s) => switch (this) {
        SortKind.selection => _selection(s),
        SortKind.insertion => _insertion(s),
        SortKind.shell => _shell(s),
        SortKind.merge => _merge(s),
      };
}

Future<void> _selection(SortSession s) async {
  final List<int> v = s.values;
  final int n = v.length;
  for (int i = 0; i < n - 1; i++) {
    int smallest = i;
    s.mark(SortMarks(target: i, current: smallest, sortedCount: i));
    for (int j = i + 1; j < n; j++) {
      s.mark(s.marks.copyWith(compared: j));
      if (!await s.wait(SortPause.compare)) return;
      if (v[j] < v[smallest]) {
        smallest = j;
        s.mark(s.marks.copyWith(current: smallest));
      }
    }
    if (smallest != i) {
      s.swap(i, smallest);
      s.mark(s.marks.copyWith(current: i, compared: -1));
      if (!await s.wait(SortPause.swap)) return;
    }
    s.mark(SortMarks(sortedCount: i + 1));
  }
}

Future<void> _insertion(SortSession s) async {
  final List<int> v = s.values;
  final int n = v.length;
  s.mark(const SortMarks(sortedCount: 1));
  for (int i = 1; i < n; i++) {
    int k = i;
    s.mark(SortMarks(current: k, sortedCount: i));
    while (k > 0) {
      s.mark(s.marks.copyWith(compared: k - 1));
      if (!await s.wait(SortPause.compare)) return;
      if (v[k - 1] <= v[k]) break;
      s.swap(k - 1, k);
      k--;
      s.mark(s.marks.copyWith(current: k, compared: -1));
      if (!await s.wait(SortPause.swap)) return;
    }
    s.mark(SortMarks(sortedCount: i + 1));
  }
}

Future<void> _shell(SortSession s) async {
  final List<int> v = s.values;
  final int n = v.length;
  for (int gap = n ~/ 2; gap > 0; gap ~/= 2) {
    for (int i = gap; i < n; i++) {
      int k = i;
      s.mark(SortMarks(current: k));
      while (k >= gap) {
        s.mark(s.marks.copyWith(compared: k - gap));
        if (!await s.wait(SortPause.compare)) return;
        if (v[k - gap] <= v[k]) break;
        s.swap(k - gap, k);
        k -= gap;
        s.mark(s.marks.copyWith(current: k, compared: -1));
        if (!await s.wait(SortPause.swap)) return;
      }
    }
  }
}

Future<void> _merge(SortSession s) async {
  final List<int> v = s.values;

  Future<bool> mergeRange(int left, int middle, int right) async {
    final List<int> lower = v.sublist(left, middle + 1);
    final List<int> upper = v.sublist(middle + 1, right + 1);
    s.mark(SortMarks(rangeStart: left, rangeEnd: right));
    int i = 0;
    int j = 0;
    int k = left;
    bool active = true;
    while (i < lower.length || j < upper.length) {
      final bool takeLower = j >= upper.length || (i < lower.length && lower[i] <= upper[j]);
      if (active) {
        s.mark(s.marks.copyWith(current: k));
        if (i < lower.length && j < upper.length) active = await s.wait(SortPause.compare);
      }
      s.write(k, takeLower ? lower[i++] : upper[j++]);
      k++;
      if (active) active = await s.wait(SortPause.write);
    }
    return active;
  }

  Future<bool> sortRange(int left, int right) async {
    if (left >= right) return true;
    final int middle = (left + right) ~/ 2;
    if (!await sortRange(left, middle)) return false;
    if (!await sortRange(middle + 1, right)) return false;
    return mergeRange(left, middle, right);
  }

  await sortRange(0, v.length - 1);
}
