import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/algorithms/binary_tree.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/ui/circle_icon_button.dart';
import 'package:graph_maker_app_2/widgets/ui/pill_button.dart';

class TreeTourKeys {
  final GlobalKey traversals = GlobalKey();
  final GlobalKey pair = GlobalKey();
  final GlobalKey postField = GlobalKey();
  final GlobalKey otherField = GlobalKey();
  final GlobalKey build = GlobalKey();
  final GlobalKey count = GlobalKey();
  final GlobalKey generate = GlobalKey();
}

const TextStyle _sectionStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: AppColors.darkBlue,
);

class TreeTraversalsBlock extends StatelessWidget {
  final Map<Traversal, List<String>>? traversals;
  final String? treeError;
  final Traversal? selectedTraversal;
  final ValueChanged<Traversal> onTraversalTap;
  final VoidCallback? onUseInBuild;
  final GlobalKey? boxKey;

  const TreeTraversalsBlock({
    super.key,
    required this.traversals,
    required this.treeError,
    required this.selectedTraversal,
    required this.onTraversalTap,
    required this.onUseInBuild,
    this.boxKey,
  });

  @override
  Widget build(BuildContext context) {
    final bool isError = treeError != null;
    final Map<Traversal, List<String>>? lists = traversals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Recorridos', style: _sectionStyle)),
            if (lists != null)
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: AppColors.blue),
                onPressed: onUseInBuild,
                icon: const Icon(Icons.south, size: 18),
                label: const Text('Usar abajo'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          key: boxKey,
          padding: const EdgeInsets.all(10),
          decoration: ShapeDecoration(
            color: AppColors.gray.withAlpha(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: isError ? const BorderSide(color: AppColors.orange, width: 1.5) : BorderSide.none,
            ),
          ),
          child: isError || lists == null
              ? Text(
                  treeError ?? 'Dibuja un árbol, constrúyelo o genera uno',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isError ? Theme.of(context).colorScheme.error : AppColors.gray,
                    fontSize: 15,
                    fontWeight: isError ? FontWeight.w600 : FontWeight.normal,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final Traversal t in Traversal.values) _row(t, lists[t]!),
                  ],
                ),
        ),
        if (lists != null)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Toca un recorrido para numerar los nodos en el lienzo',
              style: TextStyle(color: AppColors.gray, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _row(Traversal t, List<String> labels) {
    final bool selected = selectedTraversal == t;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => onTraversalTap(t),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.white : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 86,
                child: Text(
                  t.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.treeOrderBadge : AppColors.darkBlue,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  labels.join('  '),
                  style: const TextStyle(
                    color: AppColors.darkBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TreeFunctions extends StatelessWidget {
  final Widget? traversalsBlock;

  final TreePair pair;
  final ValueChanged<TreePair> onPairChanged;
  final TextEditingController postController;
  final TextEditingController otherController;
  final String? buildError;
  final VoidCallback? onBuild;

  final int nodeCount;
  final int maxNodes;
  final ValueChanged<int> onNodeCountChanged;
  final VoidCallback onGenerate;

  final TreeTourKeys? keys;

  const TreeFunctions({
    super.key,
    this.traversalsBlock,
    required this.pair,
    required this.onPairChanged,
    required this.postController,
    required this.otherController,
    required this.buildError,
    required this.onBuild,
    required this.nodeCount,
    required this.maxNodes,
    required this.onNodeCountChanged,
    required this.onGenerate,
    this.keys,
  });

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: _sectionStyle),
      );

  Widget _field(BuildContext context, String label, TextEditingController controller, GlobalKey? key, TextInputAction action) {
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: const BorderSide(color: AppColors.darkBlue, width: 1.5),
    );
    return TextField(
      key: key,
      controller: controller,
      textInputAction: action,
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(color: AppColors.darkBlue, fontSize: 16, letterSpacing: 0.5),
      cursorColor: AppColors.blue,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      onSubmitted: action == TextInputAction.done ? (_) => onBuild?.call() : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.darkBlue),
        floatingLabelStyle: const TextStyle(color: AppColors.blue),
        hintText: controller == postController
            ? 'Ej.: 2, 5, 4, 9, 8, 7'
            : (pair == TreePair.postIn ? 'Ej.: 2, 4, 5, 7, 8, 9' : 'Ej.: 7, 4, 2, 5, 8, 9'),
        hintStyle: const TextStyle(color: AppColors.gray),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        enabledBorder: border,
        border: border,
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.blue, width: 2)),
      ),
    );
  }

  Widget _pairSelector() {
    return SegmentedButton<TreePair>(
      key: keys?.pair,
      showSelectedIcon: false,
      segments: [
        for (final TreePair p in TreePair.values)
          ButtonSegment<TreePair>(value: p, label: Text('Post + ${p.other.short}'), tooltip: p.label),
      ],
      selected: {pair},
      onSelectionChanged: (s) => onPairChanged(s.first),
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.blue,
        selectedForegroundColor: AppColors.white,
        foregroundColor: AppColors.darkBlue,
        side: const BorderSide(color: AppColors.darkBlue, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (traversalsBlock != null) ...[
          traversalsBlock!,
          const Divider(height: 32),
        ],

        _section('Construir desde recorridos'),
        _pairSelector(),
        const SizedBox(height: 12),
        _field(context, 'Postorden', postController, keys?.postField, TextInputAction.next),
        const SizedBox(height: 12),
        _field(context, pair.other.label, otherController, keys?.otherField, TextInputAction.done),
        const SizedBox(height: 12),
        PillButton(
          key: keys?.build,
          label: 'Construir',
          icon: Icons.account_tree_outlined,
          style: AppButtonStyle.accent,
          onTap: onBuild,
          fullWidth: true,
        ),
        if (buildError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              buildError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600),
            ),
          ),

        const Divider(height: 32),

        _section('Árbol aleatorio'),
        Row(
          key: keys?.count,
          children: [
            const Expanded(child: Text('Nodos', style: TextStyle(color: AppColors.darkBlue, fontSize: 15))),
            CircleIconButton(
              icon: Icons.remove,
              text: 'Menos nodos',
              action: nodeCount > 1 ? () => onNodeCountChanged(nodeCount - 1) : null,
            ),
            SizedBox(
              width: 44,
              child: Text(
                '$nodeCount',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkBlue),
              ),
            ),
            CircleIconButton(
              icon: Icons.add,
              text: 'Más nodos',
              action: nodeCount < maxNodes ? () => onNodeCountChanged(nodeCount + 1) : null,
            ),
          ],
        ),
        const SizedBox(height: 12),
        PillButton(
          key: keys?.generate,
          label: 'Generar aleatorio',
          icon: Icons.casino_outlined,
          style: AppButtonStyle.outline,
          onTap: onGenerate,
          fullWidth: true,
        ),
      ],
    );
  }
}
