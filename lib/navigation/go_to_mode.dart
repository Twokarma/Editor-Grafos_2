import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/models/app_mode.dart';
import 'package:graph_maker_app_2/providers/graph_provider.dart';
import 'package:provider/provider.dart';

void goToMode(BuildContext context, AppMode destinationMode, AppMode currentMode){
  if(destinationMode == currentMode) return;
  //lee el mainProvider pasando por alto el provider del modo en el que está
  final GraphProvider mainProvider = Navigator.of(context).context.read<GraphProvider>();
  if(destinationMode.usesCopy){
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<GraphProvider>(
          create: (_) => GraphProvider(initialGraph: mainProvider.snapshot(), graphRules: destinationMode.rules),
          child: destinationMode.buildScreen(mainProvider),
        ),
      ),
    );
  }else{
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => destinationMode.buildScreen(mainProvider)));
  }

}