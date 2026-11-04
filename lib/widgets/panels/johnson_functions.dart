import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/models/node.dart';
import 'package:graph_maker_app_2/services/johnson_service.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/ui/panel_card.dart';
import 'package:graph_maker_app_2/widgets/ui/pill_button.dart';

class JohnsonFunctions extends StatelessWidget{
  final String? path;
  final String? message;
  final List<Node> nodes;
  final String? from;
  final String? to;
  final Objective objective;
  final bool canSolve;
  final bool resultExists;
  final ValueChanged<String?> onFromChanged;
  final ValueChanged<String?> onToChanged;
  final ValueChanged<Objective> onObjectiveChanged;
  final VoidCallback? onOpenMatrix;
  final GlobalKey? fromKey;
  final GlobalKey? toKey;
  final GlobalKey? objectiveKey;
  final GlobalKey? matrixKey;

  const JohnsonFunctions({
    super.key,
    this.path,
    this.message,
    required this.nodes,
    required this.from,
    required this.to,
    required this.objective,
    required this.canSolve,
    required this.resultExists,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onObjectiveChanged,
    required this.onOpenMatrix,
    this.fromKey,
    this.toKey,
    this.objectiveKey,
    this.matrixKey,
  });

  List<DropdownMenuEntry<String>> _dropdownMenuEntries(){
    List<DropdownMenuEntry<String>> entries = [];
    for (final Node node in nodes) {
      entries.add(DropdownMenuEntry<String>(value: node.id, label: node.name));
    }
    return entries;
  }

  Widget _nodeDropDown(String label, String? value, ValueChanged<String?> onSelected, List<DropdownMenuEntry<String>> entries,GlobalKey? key){
    return KeyedSubtree(
        key: key,
        child: DropdownMenu<String>(
        key: ValueKey('${label}_$value'),
        expandedInsets: EdgeInsets.zero,
        initialSelection: value,
        label: Text(label),
        requestFocusOnTap: false,
        enabled: resultExists,
        menuHeight: 300,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          enabledBorder: ShapedInputBorder(
              shape: StadiumBorder(),
              borderSide: BorderSide(
                color: AppColors.darkBlue,
                width: 1.5,
              ),
          ),
          disabledBorder: ShapedInputBorder(
            shape: StadiumBorder(),
            borderSide: BorderSide(
              color: AppColors.darkBlue.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
        ),
        dropdownMenuEntries: entries,
        onSelected: onSelected,
      )
    );
  }

  @override
  Widget build(BuildContext context){
    final List<DropdownMenuEntry<String>> dropdownMenuEntries = _dropdownMenuEntries();
    return PanelCard(
        title: "Funciones",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if(message != null || path != null)...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: ShapeDecoration(
                    color: AppColors.gray.withAlpha(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(8),
                      side: message != null? BorderSide(
                          color: AppColors.orange,
                          width: 1.5
                      ) : BorderSide.none,
                    )
                ),
                child: Center(
                  child: Text(
                    message?? path?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: message != null? Theme.of(context).colorScheme.error : AppColors.cian,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16,),
            ],

            LayoutBuilder(builder: (context, constraints){
                  return constraints.maxWidth >= 300? Row(
                    children: [
                      Expanded(
                        child:  _nodeDropDown("Desde", from, onFromChanged, dropdownMenuEntries, fromKey),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child:  _nodeDropDown("Hacia", to, onToChanged, dropdownMenuEntries, toKey),
                      ),
                    ],
                  ) : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _nodeDropDown("Desde", from, onFromChanged, dropdownMenuEntries, fromKey),
                      const SizedBox(height: 16.0),
                      _nodeDropDown("Hacia", to, onToChanged, dropdownMenuEntries, toKey),
                    ],
                  );
                }
            ),

            const SizedBox(height: 16,),

            Column(
              key: objectiveKey,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PillButton(
                  label: "Minimizar",
                  style: objective == Objective.min? AppButtonStyle.accent : AppButtonStyle.outline,
                  icon: Icons.trending_down,
                  onTap: canSolve? () => onObjectiveChanged(Objective.min) : null,
                  fullWidth: true,
                ),
                const SizedBox(height: 16.0),
                PillButton(
                  label: "Maximizar",
                  style: objective == Objective.max? AppButtonStyle.accent : AppButtonStyle.outline,
                  icon: Icons.trending_up,
                  onTap: canSolve? () => onObjectiveChanged(Objective.max) : null,
                  fullWidth: true,
                ),
              ],
            ),

            const SizedBox(height: 16.0),
            PillButton(
              key: matrixKey,
              label: "Matriz M[x]",
              style: AppButtonStyle.outline,
              icon: Icons.grid_on,
              onTap: resultExists? onOpenMatrix : null,
              fullWidth: true,
            ),
          ],
        )
    );
  }

}