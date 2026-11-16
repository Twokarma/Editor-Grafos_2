import 'package:flutter/foundation.dart';
import 'package:graph_maker_app_2/algorithms/sorts.dart';
import 'package:graph_maker_app_2/tours/editor_tour_steps.dart';
import 'package:graph_maker_app_2/widgets/panels/sort_functions.dart';
import 'package:graph_maker_app_2/widgets/panels/tree_functions.dart';
import 'package:graph_maker_app_2/widgets/tour/tour_models.dart';

EditorTour treeTour(TreeTourKeys keys) => EditorTour(
      canvas: TourCanvas.tree,
      subject: 'árbol',
      functionsIntro: 'Aquí construyes, completas o generas árboles binarios de búsqueda.',
      functionSteps: () => [
        TourStep(
          key: keys.traversals,
          area: TourArea.functions,
          chapter: chapterFunctions,
          title: 'Recorridos',
          text: 'Preorden, inorden y postorden del árbol dibujado. Toca uno para numerar los nodos en el lienzo. '
              'Un hijo con valor menor o igual al del padre va a la izquierda; uno mayor, a la derecha.',
          desktopText: 'Preorden, inorden y postorden del árbol dibujado. Haz clic en uno para numerar los nodos en el lienzo. '
              'Un hijo con valor menor o igual al del padre va a la izquierda; uno mayor, a la derecha.',
        ),
        TourStep(
          key: keys.pair,
          area: TourArea.functions,
          chapter: chapterFunctions,
          title: 'Pareja de recorridos',
          text: 'Elige si vas a escribir el inorden con el postorden o con el preorden.',
        ),
        TourStep(
          key: keys.inField,
          area: TourArea.functions,
          chapter: chapterFunctions,
          title: 'Inorden',
          text: 'Los valores en inorden (de menor a mayor), separados por comas o espacios. Empieza con el árbol actual.',
        ),
        TourStep(
          key: keys.otherField,
          area: TourArea.functions,
          chapter: chapterFunctions,
          title: 'Segundo recorrido',
          text: 'El postorden o el preorden de los mismos valores.',
        ),
        TourStep(
          key: keys.build,
          area: TourArea.functions,
          chapter: chapterFunctions,
          title: 'Construir',
          text: 'Dibuja el único árbol que tiene esos dos recorridos y lo encuadra en el lienzo.',
        ),
        TourStep(
          key: keys.insertField,
          area: TourArea.functions,
          chapter: chapterFunctions,
          title: 'Insertar valores',
          text: 'Escribe uno o varios valores separados por comas: se agregan al árbol siguiendo la regla de izquierda y derecha.',
        ),
        TourStep(
          key: keys.insert,
          area: TourArea.functions,
          chapter: chapterFunctions,
          title: 'Insertar',
          text: 'Agrega los valores, uno por uno y en orden, al árbol actual.',
        ),
        TourStep(
          key: keys.count,
          area: TourArea.functions,
          chapter: chapterFunctions,
          title: 'Cantidad de nodos',
          text: 'Tamaño del árbol aleatorio.',
        ),
        TourStep(
          key: keys.generate,
          area: TourArea.functions,
          chapter: chapterFunctions,
          title: 'Generar',
          text: 'Reemplaza el lienzo por un árbol aleatorio. Se puede deshacer.',
        ),
      ],
    );

EditorTour sortTour({
  required SortKind kind,
  required SortTourKeys keys,
  required ValueListenable<int> shuffles,
  required VoidCallback onStart,
}) =>
    EditorTour(
      canvas: TourCanvas.sort,
      subject: 'secuencia',
      functionsIntro: 'Aquí preparas los bolos y ves a ${kind.title} ordenarlos paso a paso, con un cronómetro.',
      onStart: onStart,
      functionSteps: () {
        final int start = shuffles.value;
        return [
          TourStep(
            key: keys.count,
            area: TourArea.functions,
            chapter: chapterFunctions,
            title: 'Cantidad de bolos',
            text: 'Elige cuántos bolos ordenar, de 1 a 20. Al cambiarla se mezclan de nuevo.',
          ),
          TourStep(
            key: keys.speed,
            area: TourArea.functions,
            chapter: chapterFunctions,
            title: 'Velocidad',
            text: 'De ×0.5 (lenta) a ×5 (muy rápida). Puedes cambiarla incluso mientras ordena.',
          ),
          TourStep(
            key: keys.shuffle,
            area: TourArea.functions,
            chapter: chapterFunctions,
            title: 'Mezclar',
            text: 'Desordena los bolos que tienes.',
            wait: TourWait(
              listenable: shuffles,
              isDone: () => shuffles.value > start,
              prompt: 'Ahora tú: pulsa Mezclar',
            ),
          ),
          TourStep(
            key: keys.solve,
            area: TourArea.functions,
            chapter: chapterFunctions,
            title: 'Resolver',
            text: 'Ejecuta ${kind.title} paso a paso. Mientras ordena, este botón cambia a Detener.',
          ),
          TourStep(
            key: keys.random,
            area: TourArea.functions,
            chapter: chapterFunctions,
            title: 'Aleatorio',
            text: 'Genera valores al azar entre 1 y 99, que pueden repetirse.',
          ),
          TourStep(
            key: keys.enter,
            area: TourArea.functions,
            chapter: chapterFunctions,
            title: 'Ingresar',
            text: 'Escribe tus propios valores, separados por comas o espacios.',
          ),
          TourStep(
            key: keys.legend,
            area: TourArea.functions,
            chapter: chapterFunctions,
            title: 'Colores',
            text: 'Qué significa cada color mientras ${kind.title} trabaja.',
          ),
        ];
      },
    );
