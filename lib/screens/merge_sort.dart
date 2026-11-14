import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/algorithms/sorts.dart';
import 'package:graph_maker_app_2/screens/sort_screen.dart';

class MergeSort extends StatelessWidget {
  const MergeSort({super.key});

  @override
  Widget build(BuildContext context) => const SortScreen(kind: SortKind.merge);
}
