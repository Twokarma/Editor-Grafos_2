import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:graph_maker_app_2/models/app_mode.dart';
import 'package:graph_maker_app_2/providers/graph_provider.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';

class _Palette {
  static const paper = AppColors.paper;
  static const ink = AppColors.darkBlue;
  static const body = AppColors.darkBlue;
  static const muted = Color(0xC7023047);
  static const primary = AppColors.darkBlue;
  static const accent = AppColors.blue;
  static const deep = AppColors.darkBlue;
  static const tint = AppColors.cream;
  static const surface = AppColors.marfil;
  static const divider = Color(0x33023047);
  static const orange = AppColors.orange;
  static const highlight = AppColors.mustard;
  static const cyan = AppColors.cian;
  static const mustard = AppColors.mustard;
  static const lightBlue = AppColors.lightBlue;
  static const video = AppColors.darkBlue;
  static const videoHover = AppColors.orange;
  static const videoLight = AppColors.mustard;
  static const videoLightHover = AppColors.white;
  static const white = AppColors.white;
}

TextStyle _display({double? size, FontWeight weight = FontWeight.w800, FontStyle? style, double? height, double? spacing, Color color = _Palette.ink}) =>
    GoogleFonts.bricolageGrotesque(fontSize: size, fontWeight: weight, fontStyle: style, height: height, letterSpacing: spacing, color: color);

TextStyle _sans({double? size, FontWeight weight = FontWeight.w400, FontStyle? style, double? height, double? spacing, Color color = _Palette.ink}) =>
    GoogleFonts.ibmPlexSans(fontSize: size, fontWeight: weight, fontStyle: style, height: height, letterSpacing: spacing, color: color);

TextStyle _mono({double? size, Color color = _Palette.ink}) =>
    GoogleFonts.ibmPlexMono(fontSize: size, fontWeight: FontWeight.w500, color: color);

double _fluid(double width, double factor, double min, double max) => (width * factor).clamp(min, max);

void _openMode(BuildContext context, AppMode mode) {
  final GraphProvider main = context.read<GraphProvider>();
  if (mode.usesCopy) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider<GraphProvider>(
        create: (_) => GraphProvider(initialGraph: main.snapshot(), graphRules: mode.rules),
        child: mode.buildScreen(main),
      ),
    ));
  } else {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => mode.buildScreen(main)));
  }
}

Future<void> _openLink(String url) async {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

String _modeName(AppMode mode) => mode.group == ModeGroup.sort ? '${mode.label} Sort' : mode.label;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _conceptsKey = GlobalKey();
  final GlobalKey _methodsKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final BuildContext? target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      backgroundColor: _Palette.paper,
      body: SafeArea(
        child: DefaultTextStyle(
          style: _sans(size: 16),
          child: SingleChildScrollView(
            controller: _scroll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Hero(
                  width: width,
                  onOpenEditor: () => _openMode(context, AppMode.graphMaker),
                  onSeeMethods: () => _scrollTo(_methodsKey),
                ),
                Center(child: _ScrollCue(onTap: () => _scrollTo(_conceptsKey))),
                const SizedBox(height: 48),
                _Section(
                  key: _conceptsKey,
                  child: _ConceptsSection(scroll: _scroll, width: width),
                ),
                _MethodsSection(key: _methodsKey, scroll: _scroll, width: width),
                const _Footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _Section({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(24, 24, 24, 40)});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final double width;
  final VoidCallback onOpenEditor;
  final VoidCallback onSeeMethods;

  const _Hero({required this.width, required this.onOpenEditor, required this.onSeeMethods});

  @override
  Widget build(BuildContext context) {
    final Widget text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'EDITOR DE GRAFOS Y ALGORITMOS',
          style: _sans(size: 14, weight: FontWeight.w600, spacing: 2, color: _Palette.primary),
        ),
        const SizedBox(height: 12),
        Text(
          'Graph M4ker',
          style: _display(
            size: _fluid(width, 0.10, 56, 128),
            style: FontStyle.italic,
            height: 0.92,
            spacing: -0.04 * _fluid(width, 0.10, 56, 128),
          ),
        ),
        const SizedBox(height: 14),
        Text('by Windows98', style: _sans(size: 20, style: FontStyle.italic, color: _Palette.muted)),
        const SizedBox(height: 28),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(
            'Dibuja nodos y aristas, encuentra rutas críticas, resuelve asignaciones '
            'y mira cómo se ordenan los datos paso a paso.',
            style: _sans(size: 18, height: 1.6, color: _Palette.body),
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _PillButton(label: 'Abrir el editor', filled: true, onTap: onOpenEditor),
            _PillButton(label: 'Ver algoritmos', filled: false, onTap: onSeeMethods),
          ],
        ),
      ],
    );

    final Widget art = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: AspectRatio(aspectRatio: 420 / 320, child: _HeroGraph()),
      ),
    );

    return _Section(
      padding: EdgeInsets.fromLTRB(24, width >= 600 ? 72 : 48, 24, 40),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth >= 820) {
          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: 40),
              Expanded(child: art),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [text, const SizedBox(height: 40), art],
        );
      }),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _PillButton({required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? _Palette.primary : Colors.transparent,
      shape: StadiumBorder(side: filled ? BorderSide.none : const BorderSide(color: _Palette.ink, width: 1.5)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: _sans(size: 16, weight: FontWeight.w600, color: filled ? _Palette.white : _Palette.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScrollCue extends StatefulWidget {
  final VoidCallback onTap;
  const _ScrollCue({required this.onTap});

  @override
  State<_ScrollCue> createState() => _ScrollCueState();
}

class _ScrollCueState extends State<_ScrollCue> with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _bob.stop();
    } else if (!_bob.isAnimating) {
      _bob.repeat();
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, child) {
        final double t = math.sin(_bob.value * math.pi);
        return Transform.translate(offset: Offset(0, 8 * t), child: child);
      },
      child: TextButton(
        onPressed: widget.onTap,
        style: TextButton.styleFrom(foregroundColor: _Palette.muted),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Desliza para aprender', style: _sans(size: 14, color: _Palette.muted)),
            const SizedBox(height: 6),
            const Icon(Icons.arrow_downward, size: 22, color: _Palette.muted),
          ],
        ),
      ),
    );
  }
}

class _ScrollProgress extends StatefulWidget {
  final ScrollController scroll;
  final bool once;
  final Widget Function(BuildContext context, double progress) builder;

  const _ScrollProgress({required this.scroll, required this.builder, this.once = false});

  @override
  State<_ScrollProgress> createState() => _ScrollProgressState();
}

class _ScrollProgressState extends State<_ScrollProgress> {
  double _progress = 0;
  bool _measured = false;

  @override
  void initState() {
    super.initState();
    widget.scroll.addListener(_measure);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void dispose() {
    widget.scroll.removeListener(_measure);
    super.dispose();
  }

  void _measure() {
    if (!mounted) return;
    final RenderObject? object = context.findRenderObject();
    if (object is! RenderBox || !object.hasSize) return;
    final double viewport = MediaQuery.sizeOf(context).height;
    final double top = object.localToGlobal(Offset.zero).dy;
    final double span = math.max(1, math.min(object.size.height, viewport));
    double p = ((viewport - top) / span).clamp(0.0, 1.0);
    if (widget.once && p < _progress) p = _progress;
    if (!_measured || (p - _progress).abs() > 0.002) {
      setState(() {
        _progress = p;
        _measured = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.builder(context, 1);
    return widget.builder(context, _measured ? _progress : 0);
  }
}

class _Reveal extends StatelessWidget {
  final ScrollController scroll;
  final Widget child;

  const _Reveal({required this.scroll, required this.child});

  @override
  Widget build(BuildContext context) {
    return _ScrollProgress(
      scroll: scroll,
      once: true,
      builder: (context, p) {
        final bool shown = p >= 0.18;
        return AnimatedOpacity(
          opacity: shown ? 1 : 0,
          duration: const Duration(milliseconds: 900),
          curve: Curves.ease,
          child: AnimatedSlide(
            offset: shown ? Offset.zero : const Offset(0, 0.6),
            duration: const Duration(milliseconds: 900),
            curve: const Cubic(.16, .84, .24, 1),
            child: child,
          ),
        );
      },
    );
  }
}

class _Concept {
  final String number;
  final String title;
  final String text;
  final String video;
  final Color background;
  final Color titleColor;
  final Color textColor;
  final Color pillBackground;
  final Color pillText;
  final Color artBackground;
  final String artLabel;
  final CustomPainter art;
  final bool reversed;
  final bool lightVideoButton;

  const _Concept({
    required this.number,
    required this.title,
    required this.text,
    required this.video,
    required this.background,
    required this.titleColor,
    required this.textColor,
    required this.pillBackground,
    required this.pillText,
    required this.artBackground,
    required this.artLabel,
    required this.art,
    this.reversed = false,
    this.lightVideoButton = false,
  });
}

final List<_Concept> _concepts = [
  _Concept(
    number: '01',
    title: '¿Qué es un grafo?',
    text: 'Un grafo es una estructura que representa relaciones entre objetos. Los objetos se llaman '
        'nodos (o vértices) y las relaciones entre ellos se llaman aristas.',
    video: 'https://www.youtube.com/results?search_query=que+es+un+grafo+teoria+de+grafos',
    background: _Palette.white,
    titleColor: _Palette.ink,
    textColor: _Palette.body,
    pillBackground: _Palette.tint,
    pillText: _Palette.primary,
    artBackground: _Palette.tint,
    artLabel: 'Ilustración: nodos unidos por aristas',
    art: _ViewBoxPainter(const Size(320, 200), _paintGraphBasics),
  ),
  _Concept(
    number: '02',
    title: '¿Para qué sirven?',
    text: 'Sirven para modelar redes: rutas entre ciudades, conexiones entre computadoras, relaciones '
        'entre personas, dependencias entre tareas. Permiten responder preguntas como cuál es el camino '
        'más corto o cómo asignar recursos al menor costo.',
    video: 'https://www.youtube.com/results?search_query=aplicaciones+de+la+teoria+de+grafos',
    background: _Palette.ink,
    titleColor: _Palette.white,
    textColor: _Palette.surface,
    pillBackground: _Palette.mustard,
    pillText: _Palette.ink,
    artBackground: Color(0x33219EBC),
    artLabel: 'Ilustración: rutas entre ciudades en un mapa',
    art: _ViewBoxPainter(const Size(320, 200), _paintRoutes),
    reversed: true,
    lightVideoButton: true,
  ),
  _Concept(
    number: '03',
    title: 'Concepto matemático de un grafo',
    text: 'Formalmente, un grafo es un par G = (V, E), donde V es un conjunto de vértices y E es un '
        'conjunto de aristas, cada una formada por un par de vértices de V.',
    video: 'https://www.youtube.com/results?search_query=definicion+formal+de+grafo+G%3D(V%2CE)',
    background: _Palette.white,
    titleColor: _Palette.ink,
    textColor: _Palette.body,
    pillBackground: _Palette.tint,
    pillText: _Palette.primary,
    artBackground: _Palette.surface,
    artLabel: 'Ilustración: conjunto de vértices V y conjunto de aristas E',
    art: _ViewBoxPainter(const Size(320, 200), _paintSets),
  ),
  _Concept(
    number: '04',
    title: 'Tipos de grafos',
    text: 'Dirigidos y no dirigidos, ponderados y no ponderados, simples y multigrafos, conexos y no '
        'conexos, bipartitos, árboles, entre otros.',
    video: 'https://www.youtube.com/results?search_query=tipos+de+grafos',
    background: _Palette.accent,
    titleColor: _Palette.ink,
    textColor: _Palette.ink,
    pillBackground: _Palette.white,
    pillText: _Palette.ink,
    artBackground: _Palette.deep,
    artLabel: 'Ilustración: grafo dirigido, no dirigido y árbol',
    art: _ViewBoxPainter(const Size(320, 200), _paintKinds),
    reversed: true,
    lightVideoButton: true,
  ),
];

class _ConceptsSection extends StatelessWidget {
  final ScrollController scroll;
  final double width;

  const _ConceptsSection({required this.scroll, required this.width});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Reveal(
          scroll: scroll,
          child: Text(
            'Antes de empezar',
            style: _display(size: _fluid(width, 0.06, 36, 72), height: 1, spacing: -0.03 * _fluid(width, 0.06, 36, 72)),
          ),
        ),
        const SizedBox(height: 40),
        for (int i = 0; i < _concepts.length; i++) ...[
          if (i > 0) const SizedBox(height: 56),
          _SlideInCard(
            scroll: scroll,
            fromLeft: i.isEven,
            maxCardWidth: 1000,
            child: Align(
              alignment: i.isEven ? Alignment.centerLeft : Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: _ConceptCard(concept: _concepts[i]),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SlideInCard extends StatefulWidget {
  final ScrollController scroll;
  final bool fromLeft;
  final double maxCardWidth;
  final Widget child;

  const _SlideInCard({
    required this.scroll,
    required this.fromLeft,
    required this.maxCardWidth,
    required this.child,
  });

  @override
  State<_SlideInCard> createState() => _SlideInCardState();
}

class _SlideInCardState extends State<_SlideInCard> with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _shown = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker(_tick);
  Duration _lastTick = Duration.zero;
  double _target = 0;
  double _rowLeft = 0;
  double _rowWidth = 0;
  bool _measured = false;

  static const double _followSpeed = 9;

  @override
  void initState() {
    super.initState();
    widget.scroll.addListener(_measure);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void dispose() {
    widget.scroll.removeListener(_measure);
    _ticker.dispose();
    _shown.dispose();
    super.dispose();
  }

  void _measure() {
    if (!mounted) return;
    final RenderObject? object = context.findRenderObject();
    if (object is! RenderBox || !object.hasSize) return;
    final double viewport = MediaQuery.sizeOf(context).height;
    final Offset origin = object.localToGlobal(Offset.zero);
    final double span = math.max(1, math.min(object.size.height, viewport) * 0.85);
    final double target = ((viewport - origin.dy) / span).clamp(0.0, 1.0);

    if (origin.dx != _rowLeft || object.size.width != _rowWidth) {
      setState(() {
        _rowLeft = origin.dx;
        _rowWidth = object.size.width;
      });
    }

    if (!_measured) {
      _measured = true;
      _target = target;
      _shown.value = target;
      return;
    }
    if (target == _target) return;
    _target = target;
    if (!_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    double seconds = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (seconds <= 0 || seconds > 0.1) seconds = 1 / 60;
    double value = _shown.value;
    value += (_target - value) * (1 - math.exp(-_followSpeed * seconds));
    if ((_target - value).abs() < 0.0005) {
      value = _target;
      _ticker.stop();
    }
    _shown.value = value;
  }

  double _hiddenOffset(double screenWidth) {
    final double cardWidth = math.min(widget.maxCardWidth, _rowWidth);
    final double cardLeft = widget.fromLeft ? _rowLeft : _rowLeft + _rowWidth - cardWidth;
    const double gap = 32;
    return widget.fromLeft ? -(cardLeft + cardWidth + gap) : screenWidth - cardLeft + gap;
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final Widget child = RepaintBoundary(child: widget.child);
    return ValueListenableBuilder<double>(
      valueListenable: _shown,
      child: child,
      builder: (context, value, child) {
        final double eased = Curves.easeInOutCubic.transform(value);
        if (eased <= 0) {
          return Opacity(opacity: 0, child: child);
        }
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(_hiddenOffset(screenWidth) * (1 - eased), 0),
            child: child,
          ),
        );
      },
    );
  }
}

class _ConceptCard extends StatefulWidget {
  final _Concept concept;
  const _ConceptCard({required this.concept});

  @override
  State<_ConceptCard> createState() => _ConceptCardState();
}

class _ConceptCardState extends State<_ConceptCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final _Concept c = widget.concept;

    final Widget art = Semantics(
      label: c.artLabel,
      image: true,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: DecoratedBox(
          decoration: BoxDecoration(color: c.artBackground, borderRadius: BorderRadius.circular(22)),
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.88,
              child: AspectRatio(aspectRatio: 320 / 200, child: CustomPaint(painter: c.art)),
            ),
          ),
        ),
      ),
    );

    final Widget text = Padding(
      padding: c.reversed ? const EdgeInsets.fromLTRB(12, 8, 4, 8) : const EdgeInsets.fromLTRB(4, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: ShapeDecoration(color: c.pillBackground, shape: const StadiumBorder()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(c.number, style: _mono(size: 14, color: c.pillText)),
            ),
          ),
          const SizedBox(height: 14),
          Text(c.title, style: _display(size: 34, weight: FontWeight.w600, spacing: -0.34, color: c.titleColor, height: 1.15)),
          const SizedBox(height: 14),
          Text(c.text, style: _sans(size: 17, height: 1.65, color: c.textColor)),
          const SizedBox(height: 14),
          _YoutubeButton(url: c.video, light: c.lightVideoButton),
        ],
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            if (_hovered)
              BoxShadow(color: _Palette.ink.withValues(alpha: 0.12), blurRadius: 40, offset: const Offset(0, 18)),
          ],
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth >= 708) {
            final List<Widget> parts = [
              Expanded(child: art),
              const SizedBox(width: 28),
              Expanded(child: text),
            ];
            return Row(children: c.reversed ? parts.reversed.toList() : parts);
          }
          final List<Widget> parts = [art, const SizedBox(height: 28), text];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: c.reversed ? parts.reversed.toList() : parts,
          );
        }),
      ),
    );
  }
}

class _YoutubeButton extends StatefulWidget {
  final String url;
  final bool light;
  const _YoutubeButton({required this.url, required this.light});

  @override
  State<_YoutubeButton> createState() => _YoutubeButtonState();
}

class _YoutubeButtonState extends State<_YoutubeButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool light = widget.light;
    final Color background = light
        ? (_hovered ? _Palette.videoLightHover : _Palette.videoLight)
        : (_hovered ? _Palette.videoHover : _Palette.video);
    final Color foreground = light || _hovered ? _Palette.ink : _Palette.white;
    final Color iconCircle = light || _hovered ? _Palette.ink : _Palette.orange;
    final Color iconTriangle = light || _hovered ? background : _Palette.white;
    final double lift = _hovered ? -3 : 0;

    return Semantics(
      button: true,
      link: true,
      label: 'Ver en YouTube',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: () => _openLink(widget.url),
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1,
            duration: const Duration(milliseconds: 250),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.translationValues(0, lift, 0),
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.fromLTRB(14, 0, 20, 0),
              decoration: ShapeDecoration(color: background, shape: const StadiumBorder()),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: CustomPaint(
                      size: const Size(22, 22),
                      painter: _PlayIconPainter(circle: iconCircle, triangle: iconTriangle),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('Ver en YouTube', style: _sans(size: 16, weight: FontWeight.w600, color: foreground)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MethodsSection extends StatefulWidget {
  final ScrollController scroll;
  final double width;

  const _MethodsSection({super.key, required this.scroll, required this.width});

  @override
  State<_MethodsSection> createState() => _MethodsSectionState();
}

class _MethodsSectionState extends State<_MethodsSection> with SingleTickerProviderStateMixin {
  final ScrollController _row = ScrollController();
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 900 + 90 * AppMode.values.length),
  );
  int? _openIndex;

  @override
  void dispose() {
    _row.dispose();
    _enter.dispose();
    super.dispose();
  }

  void _maybeEnter(double progress) {
    if (progress < 0.18 || _enter.isAnimating || _enter.isCompleted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _enter.value = 1;
      } else {
        _enter.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.width;
    final double side = width > 1200 ? (width - 1152) / 2 : 24;
    const List<AppMode> modes = AppMode.values;
    final double total = _enter.duration!.inMilliseconds.toDouble();

    return Padding(
      padding: const EdgeInsets.only(top: 72, bottom: 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Section(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Reveal(
                  scroll: widget.scroll,
                  child: Text(
                    'ALGORITMOS Y ORDENAMIENTOS',
                    style: _display(size: _fluid(width, 0.07, 36, 84), height: 0.95, spacing: -0.03 * _fluid(width, 0.07, 36, 84)),
                  ),
                ),
                const SizedBox(height: 16),
                _Reveal(
                  scroll: widget.scroll,
                  child: Text(
                    'Pasa el cursor sobre una tarjeta (web) o tócala (móvil) para ver de qué trata.',
                    style: _sans(size: 16, color: _Palette.muted),
                  ),
                ),
              ],
            ),
          ),
          _ScrollProgress(
            scroll: widget.scroll,
            once: true,
            builder: (context, p) {
              _maybeEnter(p);
              return ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: false,
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                  },
                ),
                child: Scrollbar(
                  controller: _row,
                  thumbVisibility: true,
                  interactive: true,
                  child: SingleChildScrollView(
                    controller: _row,
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    padding: EdgeInsets.fromLTRB(side, 32, side, 40),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < modes.length; i++) ...[
                          if (i > 0) const SizedBox(width: 20),
                          AnimatedBuilder(
                            animation: _enter,
                            builder: (context, child) {
                              final double start = (90 * i) / total;
                              final double end = math.min(1, (90 * i + 900) / total);
                              final double t = const Cubic(.16, .84, .24, 1)
                                  .transform(Interval(start, end).transform(_enter.value));
                              return Opacity(
                                opacity: t,
                                child: Transform.translate(offset: Offset(160 * (1 - t), 0), child: child),
                              );
                            },
                            child: _MethodCard(
                              mode: modes[i],
                              open: _openIndex == i,
                              onToggle: () => setState(() => _openIndex = _openIndex == i ? null : i),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatefulWidget {
  final AppMode mode;
  final bool open;
  final VoidCallback onToggle;

  const _MethodCard({required this.mode, required this.open, required this.onToggle});

  @override
  State<_MethodCard> createState() => _MethodCardState();
}

class _MethodCardState extends State<_MethodCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool expanded = widget.open || _hovered;
    final Duration motion = const Duration(milliseconds: 350);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: motion,
        curve: const Cubic(.2, .8, .2, 1),
        child: AnimatedContainer(
          duration: motion,
          curve: const Cubic(.2, .8, .2, 1),
          width: 248,
          transform: Matrix4.translationValues(0, _hovered ? -10 : 0, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _Palette.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              if (_hovered)
                BoxShadow(color: _Palette.ink.withValues(alpha: 0.18), blurRadius: 40, offset: const Offset(0, 22)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                button: true,
                expanded: widget.open,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => setState(() => _pressed = true),
                  onTapCancel: () => setState(() => _pressed = false),
                  onTapUp: (_) => setState(() => _pressed = false),
                  onTap: widget.onToggle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: _hovered ? _Palette.accent : _Palette.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(widget.mode.icon, size: 64, color: _hovered ? _Palette.white : _Palette.primary),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 14, 6, 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(_modeName(widget.mode), style: _sans(size: 18, weight: FontWeight.w600)),
                            ),
                            AnimatedRotation(
                              turns: widget.open ? 0.125 : 0,
                              duration: motion,
                              child: const Icon(Icons.add, size: 22, color: _Palette.ink),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 450),
                curve: Curves.ease,
                alignment: Alignment.topCenter,
                child: AnimatedOpacity(
                  opacity: expanded ? 1 : 0,
                  duration: motion,
                  child: expanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(6, 6, 6, 14),
                              child: Text(
                                widget.mode.description,
                                style: _sans(size: 15, height: 1.5, color: _Palette.muted),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                              child: SizedBox(
                                height: 44,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _Palette.primary,
                                    foregroundColor: _Palette.white,
                                    shape: const StadiumBorder(),
                                    textStyle: _sans(size: 16, weight: FontWeight.w600, color: _Palette.white),
                                  ),
                                  onPressed: () => _openMode(context, widget.mode),
                                  child: const Text('Abrir'),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: _Palette.divider))),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      alignment: Alignment.center,
      child: Text('Graph M4ker · by Windows98', style: _sans(size: 14, color: _Palette.muted)),
    );
  }
}

class _HeroGraph extends StatefulWidget {
  const _HeroGraph();

  @override
  State<_HeroGraph> createState() => _HeroGraphState();
}

class _HeroGraphState extends State<_HeroGraph> with SingleTickerProviderStateMixin {
  late final AnimationController _flow = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _flow.stop();
    } else if (!_flow.isAnimating) {
      _flow.repeat();
    }
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _flow,
        builder: (context, _) => CustomPaint(
          painter: _ViewBoxPainter(const Size(420, 320), (canvas) => _paintHero(canvas, _flow.value * 56)),
        ),
      ),
    );
  }
}

class _ViewBoxPainter extends CustomPainter {
  final Size viewBox;
  final void Function(Canvas canvas) draw;

  _ViewBoxPainter(this.viewBox, this.draw);

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = math.min(size.width / viewBox.width, size.height / viewBox.height);
    canvas.save();
    canvas.translate((size.width - viewBox.width * scale) / 2, (size.height - viewBox.height * scale) / 2);
    canvas.scale(scale);
    draw(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ViewBoxPainter oldDelegate) => true;
}

Paint _stroke(Color color, double width) => Paint()
  ..color = color
  ..strokeWidth = width
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round;

Paint _fill(Color color) => Paint()..color = color;

void _line(Canvas canvas, Offset a, Offset b, Paint paint) => canvas.drawLine(a, b, paint);

void _dashedPath(Canvas canvas, Path path, Paint paint, double on, double off, double phase) {
  for (final metric in path.computeMetrics()) {
    final double period = on + off;
    double start = -(phase % period);
    while (start < metric.length) {
      final double a = math.max(0, start);
      final double b = math.min(metric.length, start + on);
      if (b > a) canvas.drawPath(metric.extractPath(a, b), paint);
      start += period;
    }
  }
}

void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint, double phase) {
  _dashedPath(canvas, Path()..moveTo(a.dx, a.dy)..lineTo(b.dx, b.dy), paint, 6, 8, phase);
}

void _label(Canvas canvas, String text, Offset baselineCenter, TextStyle style) {
  final TextPainter painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  final double baseline = painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  painter.paint(canvas, Offset(baselineCenter.dx - painter.width / 2, baselineCenter.dy - baseline));
}

void _node(Canvas canvas, Offset center, double radius, Color color, String text, double fontSize, double baselineDrop) {
  canvas.drawCircle(center, radius, _fill(color));
  _label(
    canvas,
    text,
    center + Offset(0, baselineDrop),
    _sans(size: fontSize, weight: FontWeight.w600, color: _Palette.white),
  );
}

void _paintHero(Canvas canvas, double phase) {
  const a = Offset(60, 160), b = Offset(170, 70), c = Offset(170, 250);
  const d = Offset(270, 160), e = Offset(370, 80), f = Offset(370, 250);
  final Paint orange = _stroke(_Palette.orange, 4);
  final Paint purple = _stroke(_Palette.highlight, 6);
  final Paint teal = _stroke(_Palette.cyan, 4);
  final double p = -phase;
  _dashedLine(canvas, a, b, orange, p);
  _dashedLine(canvas, a, c, orange, p);
  _dashedLine(canvas, b, d, orange, p);
  _dashedLine(canvas, c, d, purple, p);
  _dashedLine(canvas, d, e, purple, p);
  _dashedLine(canvas, d, f, teal, p);
  _node(canvas, a, 28, _Palette.accent, 'A', 20, 7);
  _node(canvas, b, 28, _Palette.accent, 'B', 20, 7);
  _node(canvas, c, 28, _Palette.accent, 'C', 20, 7);
  _node(canvas, d, 28, _Palette.ink, 'D', 20, 7);
  _node(canvas, e, 28, _Palette.accent, 'E', 20, 7);
  _node(canvas, f, 28, _Palette.accent, 'F', 20, 7);
}

void _paintGraphBasics(Canvas canvas) {
  const a = Offset(60, 100), b = Offset(150, 45), c = Offset(150, 155), d = Offset(260, 100);
  final Paint orange = _stroke(_Palette.orange, 5);
  _line(canvas, a, b, orange);
  _line(canvas, a, c, orange);
  _line(canvas, b, d, orange);
  _line(canvas, c, d, orange);
  _line(canvas, b, c, _stroke(_Palette.cyan, 5));
  _node(canvas, a, 24, _Palette.accent, 'A', 18, 6);
  _node(canvas, b, 24, _Palette.accent, 'B', 18, 6);
  _node(canvas, c, 24, _Palette.accent, 'C', 18, 6);
  _node(canvas, d, 24, _Palette.ink, 'D', 18, 6);
}

void _paintRoutes(Canvas canvas) {
  final Path road = Path()
    ..moveTo(20, 160)
    ..cubicTo(80, 120, 90, 60, 160, 70)
    ..cubicTo(230, 80, 260, 30, 300, 50);
  canvas.drawPath(road, _stroke(const Color(0x598ECAE6), 14));
  final Paint sand = _stroke(_Palette.mustard, 4);
  _dashedPath(canvas, Path()..moveTo(50, 140)..lineTo(130, 80)..lineTo(210, 120)..lineTo(280, 55), sand, 8, 8, 0);
  _dashedPath(canvas, Path()..moveTo(130, 80)..lineTo(210, 40), sand, 8, 8, 0);
  for (final Offset point in const [Offset(50, 140), Offset(130, 80), Offset(210, 120), Offset(280, 55), Offset(210, 40)]) {
    canvas.drawCircle(point, 11, _fill(_Palette.mustard));
    canvas.drawCircle(point, 4, _fill(_Palette.ink));
  }
}

void _paintSets(Canvas canvas) {
  canvas.drawOval(Rect.fromCenter(center: const Offset(90, 100), width: 140, height: 156), _fill(_Palette.white));
  canvas.drawOval(Rect.fromCenter(center: const Offset(90, 100), width: 140, height: 156), _stroke(_Palette.accent, 3));
  canvas.drawOval(Rect.fromCenter(center: const Offset(235, 100), width: 140, height: 156), _fill(_Palette.white));
  canvas.drawOval(Rect.fromCenter(center: const Offset(235, 100), width: 140, height: 156), _stroke(_Palette.orange, 3));
  TextStyle mono(Color color) => GoogleFonts.ibmPlexMono(fontSize: 16, fontWeight: FontWeight.w600, color: color);
  _label(canvas, 'V', const Offset(90, 44), mono(_Palette.accent));
  _label(canvas, 'E', const Offset(235, 44), mono(_Palette.orange));
  _label(canvas, 'a', const Offset(70, 88), mono(_Palette.ink));
  _label(canvas, 'b', const Offset(110, 88), mono(_Palette.ink));
  _label(canvas, 'c', const Offset(70, 128), mono(_Palette.ink));
  _label(canvas, 'd', const Offset(110, 128), mono(_Palette.ink));
  _label(canvas, '(a,b)', const Offset(235, 82), mono(_Palette.ink));
  _label(canvas, '(b,d)', const Offset(235, 110), mono(_Palette.ink));
  _label(canvas, '(c,a)', const Offset(235, 138), mono(_Palette.ink));
}

void _paintKinds(Canvas canvas) {
  final Paint white = _stroke(_Palette.white, 3);
  const List<List<Offset>> lines = [
    [Offset(30, 60), Offset(80, 140)],
    [Offset(80, 140), Offset(30, 140)],
    [Offset(130, 60), Offset(180, 140)],
    [Offset(180, 140), Offset(130, 140)],
    [Offset(130, 60), Offset(130, 140)],
    [Offset(260, 45), Offset(225, 105)],
    [Offset(260, 45), Offset(295, 105)],
    [Offset(225, 105), Offset(205, 160)],
    [Offset(225, 105), Offset(245, 160)],
  ];
  for (final List<Offset> l in lines) {
    _line(canvas, l[0], l[1], white);
  }
  canvas.drawPath(Path()..moveTo(80, 140)..lineTo(68, 136)..lineTo(74, 128)..close(), _fill(_Palette.white));
  canvas.drawPath(Path()..moveTo(30, 140)..lineTo(40, 134)..lineTo(40, 146)..close(), _fill(_Palette.white));
  for (final Offset p in const [Offset(30, 60), Offset(80, 140), Offset(30, 140)]) {
    canvas.drawCircle(p, 10, _fill(_Palette.mustard));
  }
  for (final Offset p in const [Offset(130, 60), Offset(180, 140), Offset(130, 140)]) {
    canvas.drawCircle(p, 10, _fill(_Palette.lightBlue));
  }
  for (final Offset p in const [Offset(260, 45), Offset(225, 105), Offset(295, 105), Offset(205, 160), Offset(245, 160)]) {
    canvas.drawCircle(p, 10, _fill(_Palette.white));
  }
}

class _PlayIconPainter extends CustomPainter {
  final Color circle;
  final Color triangle;

  _PlayIconPainter({required this.circle, required this.triangle});

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 24;
    canvas.drawCircle(Offset(12 * s, 12 * s), 11 * s, _fill(circle));
    canvas.drawPath(
      Path()
        ..moveTo(10 * s, 8 * s)
        ..lineTo(16 * s, 12 * s)
        ..lineTo(10 * s, 16 * s)
        ..close(),
      _fill(triangle),
    );
  }

  @override
  bool shouldRepaint(covariant _PlayIconPainter oldDelegate) =>
      oldDelegate.circle != circle || oldDelegate.triangle != triangle;
}
