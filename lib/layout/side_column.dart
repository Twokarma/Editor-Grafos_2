import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class SideColumn extends MultiChildRenderObjectWidget {
  final double gap;
  final double summaryCap;
  final double optionsCap;
  final double minFunctionsHeight;
  final bool hasSummary;

  SideColumn({
    super.key,
    Widget? summary,
    required Widget functions,
    required Widget options,
    required this.gap,
    required this.summaryCap,
    required this.optionsCap,
    required this.minFunctionsHeight,
  })  : hasSummary = summary != null,
        super(children: [?summary, functions, options]);

  @override
  RenderSideColumn createRenderObject(BuildContext context) => RenderSideColumn(
        gap: gap,
        summaryCap: summaryCap,
        optionsCap: optionsCap,
        minFunctionsHeight: minFunctionsHeight,
        hasSummary: hasSummary,
      );

  @override
  void updateRenderObject(BuildContext context, RenderSideColumn renderObject) {
    renderObject
      ..gap = gap
      ..summaryCap = summaryCap
      ..optionsCap = optionsCap
      ..minFunctionsHeight = minFunctionsHeight
      ..hasSummary = hasSummary;
  }
}

class _SideColumnParentData extends ContainerBoxParentData<RenderBox> {}

class RenderSideColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _SideColumnParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _SideColumnParentData> {
  RenderSideColumn({
    required this._gap,
    required this._summaryCap,
    required this._optionsCap,
    required this._minFunctionsHeight,
    required this._hasSummary,
  });

  double _gap;
  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsLayout();
  }

  double _summaryCap;
  set summaryCap(double v) {
    if (v == _summaryCap) return;
    _summaryCap = v;
    markNeedsLayout();
  }

  double _optionsCap;
  set optionsCap(double v) {
    if (v == _optionsCap) return;
    _optionsCap = v;
    markNeedsLayout();
  }

  double _minFunctionsHeight;
  set minFunctionsHeight(double v) {
    if (v == _minFunctionsHeight) return;
    _minFunctionsHeight = v;
    markNeedsLayout();
  }

  bool _hasSummary;
  set hasSummary(bool v) {
    if (v == _hasSummary) return;
    _hasSummary = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SideColumnParentData) child.parentData = _SideColumnParentData();
  }

  @override
  void performLayout() {
    final double width = constraints.maxWidth;
    final double height = constraints.maxHeight;
    final List<RenderBox> kids = getChildrenAsList();
    final RenderBox? summary = _hasSummary ? kids[0] : null;
    final RenderBox functions = kids[_hasSummary ? 1 : 0];
    final RenderBox options = kids[_hasSummary ? 2 : 1];

    double summaryHeight = 0;
    if (summary != null) {
      summary.layout(
        BoxConstraints(minWidth: width, maxWidth: width, maxHeight: min(_summaryCap, height)),
        parentUsesSize: true,
      );
      summaryHeight = summary.size.height + _gap;
    }

    final double natural = options.getMaxIntrinsicHeight(width);
    final double roomForFunctions = height - summaryHeight - _gap - natural;
    final double optionsMax = roomForFunctions < _minFunctionsHeight ? min(natural, _optionsCap) : natural;
    options.layout(
      BoxConstraints(
        minWidth: width,
        maxWidth: width,
        maxHeight: max(0.0, min(optionsMax, height - summaryHeight - _gap)),
      ),
      parentUsesSize: true,
    );

    final double functionsHeight = max(0.0, height - summaryHeight - _gap - options.size.height);
    functions.layout(BoxConstraints.tightFor(width: width, height: functionsHeight), parentUsesSize: true);

    if (summary != null) (summary.parentData! as _SideColumnParentData).offset = Offset.zero;
    (functions.parentData! as _SideColumnParentData).offset = Offset(0, summaryHeight);
    (options.parentData! as _SideColumnParentData).offset = Offset(0, height - options.size.height);
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
