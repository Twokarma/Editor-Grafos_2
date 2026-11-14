import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/models/app_mode.dart';
import 'package:graph_maker_app_2/providers/graph_provider.dart';
import 'package:graph_maker_app_2/widgets/dialogs/confirm_exit_dialog.dart';
import 'package:provider/provider.dart';

Route<void> modeRoute(AppMode mode){
  if(mode.ownsGraph){
    return MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider<GraphProvider>(
        create: (_) => GraphProvider(graphRules: mode.rules),
        child: mode.buildScreen(),
      ),
    );
  }
  return MaterialPageRoute(builder: (_) => mode.buildScreen());
}

Future<void> goToMode(BuildContext context, AppMode destinationMode, AppMode currentMode) async {
  if(destinationMode == currentMode) return;
  final NavigatorState navigator = Navigator.of(context);
  if(currentMode.ownsGraph){
    final GraphProvider provider = context.read<GraphProvider>();
    if(!await confirmLeaveGraph(context, provider)) return;
    navigator.pushReplacement(modeRoute(destinationMode));
    return;
  }
  navigator.push(modeRoute(destinationMode));
}
