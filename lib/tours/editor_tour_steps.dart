import 'package:graph_maker_app_2/layout/options_config.dart';
import 'package:graph_maker_app_2/models/app_mode.dart';
import 'package:graph_maker_app_2/widgets/tour/tour_models.dart';

const String chapterEditor = 'El editor';
const String chapterCanvas = 'El lienzo';
const String chapterFunctions = 'Funciones';
const String chapterOptions = 'Opciones';

List<TourStep> buildEditorTourSteps({
  required EditorTour tour,
  required TourHost host,
  required AppMode mode,
  required OptionsConfig options,
  TourWait? canvasWait,
}) {
  final String s = tour.subject;
  final bool drawsGraph = tour.canvas != TourCanvas.sort;
  return [
    TourStep(
      area: TourArea.navigation,
      chapter: chapterEditor,
      title: 'Bienvenido a ${mode.label}',
      text: 'Esta es la barra superior. Tócala para abrirla: tiene volver al inicio, deshacer y rehacer, '
          'el menú de algoritmos y más opciones (⋯).',
      desktopText: 'Este es el menú lateral: cambia de algoritmo o vuelve al inicio. «ocultar» lo estrecha para dar más espacio al lienzo.',
    ),
    ..._canvasSteps(tour, canvasWait),
    if (drawsGraph)
      TourStep(
        area: TourArea.zoom,
        chapter: chapterCanvas,
        title: 'Controles de zoom',
        text: '− y + acercan o alejan, el porcentaje vuelve al 100 % y el último botón encuadra todo el $s.',
        desktopText: '− y + acercan o alejan, el porcentaje vuelve al 100 % y el último botón encuadra todo el $s. '
            'Atajos: + y −, 0 para el 100 % y F para encuadrar.',
      ),
    TourStep(
      area: TourArea.functions,
      chapter: chapterFunctions,
      title: 'Funciones',
      text: '${tour.functionsIntro} Toca la flecha para mostrar u ocultar la hoja.',
      desktopText: '${tour.functionsIntro} Solo un panel está abierto a la vez: su flecha lo abre o lo cierra.',
    ),
    ...tour.functionSteps(),
    TourStep(
      key: host.isTouchLayout ? host.anchorFor(TourArea.navigation) : null,
      area: TourArea.options,
      chapter: chapterOptions,
      title: 'Opciones',
      text: 'Las acciones generales viven en la barra superior abierta. El botón ⋯ guarda el resto.',
      desktopText: 'Las acciones generales del $s. Al abrir este panel se cierra Funciones.',
    ),
    ..._optionSteps(options, host, s),
  ];
}

List<TourStep> _canvasSteps(EditorTour tour, TourWait? wait) {
  final String s = tour.subject;
  switch (tour.canvas) {
    case TourCanvas.sort:
      return const [
        TourStep(
          area: TourArea.canvas,
          chapter: chapterEditor,
          title: 'Los bolos',
          text: 'Cada bolo es un valor: cuanto mayor es el número, más grande es el bolo. '
              'Mientras se ordena, los colores muestran qué hace el algoritmo (mira la leyenda en Funciones).',
        ),
      ];
    case TourCanvas.graph:
    case TourCanvas.tree:
      final bool tree = tour.canvas == TourCanvas.tree;
      return [
        TourStep(
          area: TourArea.canvas,
          chapter: chapterEditor,
          title: 'El lienzo',
          text: tree
              ? 'Aquí se dibuja el árbol. Toca un espacio vacío para crear un nodo: te pedirá su valor.'
              : 'Aquí dibujas el $s. Toca un espacio vacío para crear un nodo.',
          desktopText: tree
              ? 'Aquí se dibuja el árbol. Haz clic en un espacio vacío para crear un nodo: te pedirá su valor.'
              : 'Aquí dibujas el $s. Haz clic en un espacio vacío para crear un nodo.',
          gesture: TourGesture.tap,
          wait: wait,
        ),
        TourStep(
          area: TourArea.canvas,
          chapter: chapterCanvas,
          title: tree ? 'Unir padre e hijo' : 'Crear una arista',
          text: tree
              ? 'Arrastra desde el nodo padre hasta el hijo. Un hijo menor o igual va a la izquierda; uno mayor, a la derecha.'
              : 'Arrastra desde un nodo hasta otro y suelta encima. Se abrirá una ventana para el peso.',
          gesture: TourGesture.drag,
        ),
        const TourStep(
          area: TourArea.canvas,
          chapter: chapterCanvas,
          title: 'Mover un nodo',
          text: 'Mantén el dedo medio segundo sobre un nodo (vibra un poco) y luego arrástralo.',
          desktopText: 'Mantén pulsado el clic medio segundo sobre un nodo y luego arrástralo.',
          gesture: TourGesture.hold,
        ),
        const TourStep(
          area: TourArea.canvas,
          chapter: chapterCanvas,
          title: 'Editar y borrar',
          text: 'Un toque sobre un nodo o una arista la edita. Un doble toque la borra.',
          desktopText: 'Un clic sobre un nodo o una arista la edita. Un doble clic la borra.',
          gesture: TourGesture.doubleTap,
        ),
        const TourStep(
          area: TourArea.canvas,
          chapter: chapterCanvas,
          title: 'Moverte por el lienzo',
          text: 'El lienzo no tiene bordes. Arrastra con un dedo desde un espacio vacío, o con dos dedos, para moverlo.',
          desktopText: 'El lienzo no tiene bordes. Desplázalo con la rueda o con dos dedos en el trackpad. '
              'También puedes mantener Espacio y arrastrar, o arrastrar con el botón central.',
          gesture: TourGesture.pan,
        ),
        const TourStep(
          area: TourArea.canvas,
          chapter: chapterCanvas,
          title: 'Acercar y alejar',
          text: 'Pellizca con dos dedos. El punto entre tus dedos se queda quieto.',
          desktopText: 'Ctrl (⌘ en Mac) + rueda, o pellizca en el trackpad. Se acerca hacia donde está el cursor.',
          gesture: TourGesture.pinch,
        ),
      ];
  }
}

List<TourStep> _optionSteps(OptionsConfig options, TourHost host, String subject) {
  String? describe(OptionKind kind) => switch (kind) {
        OptionKind.undo => 'Revierte el último cambio (hasta 20 pasos).',
        OptionKind.redo => 'Vuelve a aplicar lo que deshiciste.',
        OptionKind.save => 'Guarda el $subject con un nombre para usarlo después.',
        OptionKind.open => 'Carga un $subject que guardaste antes.',
        OptionKind.clear => 'Borra todo el $subject. Se puede deshacer.',
        OptionKind.manual => 'Abre la guía en PDF de este modo.',
        OptionKind.help => 'Vuelve a ver este recorrido cuando quieras.',
        OptionKind.aiChat => 'Pregúntale al asistente cómo usar la app o sobre tu grafo.',
      };
  String? describeDesktop(OptionKind kind) => switch (kind) {
        OptionKind.undo => 'Revierte el último cambio (hasta 20 pasos). Atajo: Ctrl+Z.',
        OptionKind.redo => 'Vuelve a aplicar lo que deshiciste. Atajo: Ctrl+Shift+Z o Ctrl+Y.',
        _ => null,
      };
  return [
    for (final OptionItem item in options.visibleOptions())
      TourStep(
        key: host.optionKeys[item.kind],
        area: TourArea.options,
        chapter: chapterOptions,
        title: item.kind.label,
        text: describe(item.kind)!,
        desktopText: describeDesktop(item.kind),
      ),
  ];
}
