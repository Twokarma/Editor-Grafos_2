import 'package:flutter/widgets.dart';
import 'package:graph_maker_app_2/tours/editor_tour_steps.dart';
import 'package:graph_maker_app_2/widgets/tour/tour_models.dart';

TourStep _function(GlobalKey key, String title, String text) =>
    TourStep(key: key, area: TourArea.functions, chapter: chapterFunctions, title: title, text: text);

class GraphMakerTourKeys {
  final GlobalKey matrix = GlobalKey();
}

EditorTour graphMakerTour(GraphMakerTourKeys keys) => EditorTour(
      canvas: TourCanvas.graph,
      subject: 'grafo',
      functionsIntro: 'Aquí ves cuántos nodos y aristas tiene tu grafo.',
      functionSteps: () => [
        _function(keys.matrix, 'Matriz M[x]',
            'Abre la tabla del grafo: cada fila es un nodo de origen, cada columna uno de destino y cada celda el peso de la arista.'),
      ],
    );

class AssignmentTourKeys {
  final GlobalKey minimize = GlobalKey();
  final GlobalKey maximize = GlobalKey();
  final GlobalKey matrix = GlobalKey();
}

EditorTour assignmentTour(AssignmentTourKeys keys) => EditorTour(
      canvas: TourCanvas.graph,
      subject: 'grafo',
      functionsIntro: 'Dibuja aristas con su costo desde cada origen hasta cada destino. Aquí verás qué origen va con qué destino y el costo total.',
      functionSteps: () => [
        _function(keys.minimize, 'Minimizar', 'Calcula la asignación de menor costo total con el método húngaro.'),
        _function(keys.maximize, 'Maximizar', 'Calcula la asignación de mayor costo total.'),
        _function(keys.matrix, 'Matriz M[x]',
            'Abre la matriz de costos. Si hay más orígenes que destinos (o al revés), el algoritmo agrega nodos ficticios.'),
      ],
    );

class JohnsonTourKeys {
  final GlobalKey from = GlobalKey();
  final GlobalKey to = GlobalKey();
  final GlobalKey objective = GlobalKey();
  final GlobalKey matrix = GlobalKey();
}

EditorTour johnsonTour(JohnsonTourKeys keys) => EditorTour(
      canvas: TourCanvas.graph,
      subject: 'grafo',
      functionsIntro: 'Johnson calcula los caminos entre todos los pares de nodos. Aquí eliges cuál ver.',
      functionSteps: () => [
        _function(keys.from, 'Desde (origen)', 'El nodo donde empieza el camino.'),
        _function(keys.to, 'Hacia (destino)', 'El nodo al que quieres llegar.'),
        _function(keys.objective, 'Maximizar o minimizar', 'Cambia entre el camino de mayor costo y el de menor costo.'),
        _function(keys.matrix, 'Matriz M[x]', 'Muestra las matrices de distancias que calculó Johnson.'),
      ],
    );

class KruskalTourKeys {
  final GlobalKey minimum = GlobalKey();
  final GlobalKey maximum = GlobalKey();
  final GlobalKey steps = GlobalKey();
}

EditorTour kruskalTour(KruskalTourKeys keys) => EditorTour(
      canvas: TourCanvas.graph,
      subject: 'grafo',
      functionsIntro: 'Kruskal une todos los nodos con las aristas de menor (o mayor) peso sin formar ciclos. '
          'Aquí las aristas no tienen dirección.',
      functionSteps: () => [
        _function(keys.minimum, 'Árbol mínimo', 'Elige las aristas más livianas. El árbol queda resaltado en el lienzo.'),
        _function(keys.maximum, 'Árbol máximo', 'Elige las aristas más pesadas.'),
        _function(keys.steps, 'Ver pasos', 'Recorre cada arista en orden: si entra al árbol o si formaría un ciclo.'),
      ],
    );

class DijkstraTourKeys {
  final GlobalKey from = GlobalKey();
  final GlobalKey to = GlobalKey();
  final GlobalKey objective = GlobalKey();
  final GlobalKey solve = GlobalKey();
  final GlobalKey steps = GlobalKey();
}

EditorTour dijkstraTour(DijkstraTourKeys keys) => EditorTour(
      canvas: TourCanvas.graph,
      subject: 'grafo',
      functionsIntro: 'Dijkstra busca el camino entre dos nodos. Las aristas pueden ser dirigidas o no.',
      functionSteps: () => [
        _function(keys.from, 'Desde', 'El nodo donde empieza el camino.'),
        _function(keys.to, 'Hacia', 'El nodo al que quieres llegar.'),
        _function(keys.objective, 'Minimizar o maximizar',
            'El camino más corto o el más largo. Para maximizar, las aristas deben ser dirigidas y sin ciclos.'),
        _function(keys.solve, 'Buscar el camino', 'Calcula el camino y lo resalta en el lienzo.'),
        _function(keys.steps, 'Ver pasos', 'Muestra cómo el algoritmo fue fijando cada distancia.'),
      ],
    );

class TransportTourKeys {
  final GlobalKey minimize = GlobalKey();
  final GlobalKey maximize = GlobalKey();
  final GlobalKey steps = GlobalKey();
}

EditorTour transportTour(TransportTourKeys keys) => EditorTour(
      canvas: TourCanvas.graph,
      subject: 'grafo',
      functionsIntro: 'Los nodos con aristas salientes son orígenes y los que las reciben son destinos. '
          'El peso de cada arista es el costo de enviar una unidad.',
      functionSteps: () => [
        _function(keys.minimize, 'Minimizar',
            'Te pide la oferta de cada origen y la demanda de cada destino, arma una solución con la esquina noroeste y la mejora con MODI.'),
        _function(keys.maximize, 'Maximizar', 'Lo mismo, buscando el mayor costo total.'),
        _function(keys.steps, 'Ver pasos', 'Muestra la tabla inicial y cada mejora de MODI.'),
      ],
    );
