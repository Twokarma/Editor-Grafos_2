import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/layout/options_config.dart';
import 'package:graph_maker_app_2/widgets/ui/panel_card.dart';
import 'package:graph_maker_app_2/widgets/ui/pill_button.dart';

class OptionsPanel extends StatelessWidget{
  final OptionsConfig optionsConfig;
  final Map<OptionKind, GlobalKey> keys;

  const OptionsPanel({super.key, required this.optionsConfig, this.keys = const <OptionKind, GlobalKey>{}});

  Widget _buildOptions(List<OptionItem> options){
    final List<Widget> buttons = [];
    final List<Widget> history = [];
    for(OptionItem option in options){
      if(option.kind.group == OptionGroup.history){
        if(history.isNotEmpty) history.add(const SizedBox(width: 10,));
        history.add(Expanded(child: PillButton(
          key: keys[option.kind],
          label: option.kind.label,
          style: option.kind.style,
          onTap: option.action,
          icon: option.kind.icon,
        ),),);
      }else{
        if(buttons.isNotEmpty) buttons.add(const SizedBox(height: 10,));
        buttons.add(PillButton(
          key: keys[option.kind],
          label: option.kind.label,
          style: option.kind.style,
          onTap: option.action,
          icon: option.kind.icon,
          fullWidth: true,
        ));
      }
    }
    if(history.isNotEmpty){
      buttons.insert(0, const SizedBox(height: 10,));
      buttons.insert(0, Row(children: history,));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: buttons,
    );
  }

  @override
  Widget build(BuildContext context){
    final List<OptionItem> options = optionsConfig.visibleOptions();
    return options.isNotEmpty? PanelCard(
        title: "Opciones",
        child: _buildOptions(options),
    ) : const SizedBox.shrink();
  }
}