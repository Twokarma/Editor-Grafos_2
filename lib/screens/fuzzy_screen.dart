import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/screens/pdf_viewer_screen.dart';
import 'package:graph_maker_app_2/widgets/dialogs/system_dialogs.dart';
import 'package:provider/provider.dart';

import '../providers/fuzzy_provider.dart';
import '../widgets/fuzzy/rule_editor.dart';
import '../widgets/fuzzy/simulation_tab.dart';
import '../widgets/fuzzy/variable_editor.dart';

/// Pantalla de lógica difusa: Mamdani y Sugeno.
class FuzzyScreen extends StatelessWidget {
  const FuzzyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fz = context.watch<FuzzyProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lógica difusa'),
          actions: [
            IconButton(
              tooltip: 'Guardar con nombre',
              icon: const Icon(Icons.save_outlined),
              onPressed: () => showSaveSystemDialog(context),
            ),
            IconButton(
              tooltip: 'Cargar sistema',
              icon: const Icon(Icons.folder_open_outlined),
              onPressed: () => showLoadSystemDialog(context),
            ),
            IconButton(
              tooltip: 'Manual de usuario',
              icon: const Icon(Icons.menu_book_outlined),
              onPressed: () => openManual(
                context,
                title: 'Manual de lógica difusa',
                assetPath: 'assets/docs/manual_logica_difusa.pdf',
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'example') fz.loadExample();
                if (value == 'empty') fz.clearSystem();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'example',
                  child: Text('Cargar ejemplo (propina)'),
                ),
                PopupMenuItem(
                  value: 'empty',
                  child: Text('Sistema vacío'),
                ),
              ],
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Variables'),
              Tab(text: 'Reglas'),
              Tab(text: 'Simulación'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<FuzzyMethod>(
                  segments: const [
                    ButtonSegment(
                      value: FuzzyMethod.mamdani,
                      label: Text('Mamdani'),
                    ),
                    ButtonSegment(
                      value: FuzzyMethod.sugeno,
                      label: Text('Sugeno'),
                    ),
                  ],
                  selected: {fz.method},
                  onSelectionChanged: (s) => fz.setMethod(s.first),
                ),
              ),
            ),
            const Expanded(
              child: TabBarView(
                // Evita que el deslizamiento de los sliders cambie de pestaña.
                physics: NeverScrollableScrollPhysics(),
                children: [
                  VariableEditor(),
                  RuleEditor(),
                  SimulationTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}