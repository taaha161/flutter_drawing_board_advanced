import 'dart:math';
import 'dart:developer' as logger;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'drawing_controller.dart';

import 'helper/ex_value_builder.dart';
import 'helper/get_size.dart';
import 'paint_contents/circle.dart';
import 'paint_contents/eraser.dart';
import 'paint_contents/rectangle.dart';
import 'paint_contents/simple_line.dart';
import 'paint_contents/smooth_line.dart';
import 'paint_contents/straight_line.dart';
import 'painter.dart';

/// 默认工具栏构建器
typedef DefaultToolsBuilder = List<DefToolItem> Function(
  Type currType,
  DrawingController controller,
);

/// 画板
class DrawingBoard extends StatefulWidget {
  const DrawingBoard(
      {super.key,
      required this.background,
      this.controller,
      this.showDefaultActions = false,
      this.showDefaultTools = false,
      this.onPointerDown,
      this.onPointerMove,
      this.onPointerUp,
      this.clipBehavior = Clip.antiAlias,
      this.defaultToolsBuilder,
      this.boardClipBehavior = Clip.hardEdge,
      this.panAxis = PanAxis.free,
      this.boardBoundaryMargin,
      this.boardConstrained = false,
      this.maxScale = 20,
      this.minScale = 0.2,
      this.boardPanEnabled = true,
      this.boardScaleEnabled = true,
      this.boardScaleFactor = 200.0,
      this.onInteractionEnd,
      this.onInteractionStart,
      this.onInteractionUpdate,
      this.transformationController,
      this.alignment = Alignment.topCenter,
      required this.onTimerStart,
      this.buttonText});

  /// 画板背景控件
  final Widget background;

  /// 画板控制器
  final DrawingController? controller;

  /// 显示默认样式的操作栏
  final bool showDefaultActions;

  /// 显示默认样式的工具栏
  final bool showDefaultTools;

  /// 开始拖动
  final Function(PointerDownEvent pde)? onPointerDown;

  /// 正在拖动
  final Function(PointerMoveEvent pme)? onPointerMove;

  /// 结束拖动
  final Function(PointerUpEvent pue)? onPointerUp;

  /// 边缘裁剪方式
  final Clip clipBehavior;

  /// 默认工具栏构建器
  final DefaultToolsBuilder? defaultToolsBuilder;

  /// 缩放板属性
  final Clip boardClipBehavior;
  final PanAxis panAxis;
  final EdgeInsets? boardBoundaryMargin;
  final bool boardConstrained;
  final double maxScale;
  final double minScale;
  final void Function(ScaleEndDetails)? onInteractionEnd;
  final void Function(ScaleStartDetails)? onInteractionStart;
  final void Function(ScaleUpdateDetails)? onInteractionUpdate;
  final bool boardPanEnabled;
  final bool boardScaleEnabled;
  final double boardScaleFactor;
  final TransformationController? transformationController;
  final AlignmentGeometry alignment;

  final VoidCallback? onTimerStart;
  final String? buttonText;

  /// 默认工具项列表
  static List<DefToolItem> defaultTools(VoidCallback? onTimerStart,
      Type currType, DrawingController controller, String? buttonText) {
    return <DefToolItem>[
      DefToolItem(
          startButton: false,
          color: Colors.white,
          activeColor: Colors.yellow,
          isActive: currType == SimpleLine,
          icon: Icons.edit,
          onTap: () => controller.setPaintContent(SimpleLine())),
      DefToolItem(
          startButton: false,
          color: Colors.white,
          activeColor: Colors.yellow,
          isActive: currType == SmoothLine,
          icon: Icons.brush,
          onTap: () => controller.setPaintContent(SmoothLine())),
      DefToolItem(
          startButton: false,
          color: Colors.white,
          activeColor: Colors.yellow,
          isActive: currType == StraightLine,
          icon: Icons.show_chart,
          onTap: () => controller.setPaintContent(StraightLine())),
      DefToolItem(
          startButton: false,
          color: Colors.white,
          activeColor: Colors.yellow,
          isActive: currType == Rectangle,
          icon: CupertinoIcons.stop,
          onTap: () => controller.setPaintContent(Rectangle())),
      DefToolItem(
          startButton: false,
          color: Colors.white,
          activeColor: Colors.yellow,
          isActive: currType == Circle,
          icon: CupertinoIcons.circle,
          onTap: () => controller.setPaintContent(Circle())),
      DefToolItem(
          startButton: false,
          color: Colors.white,
          activeColor: Colors.yellow,
          isActive: currType == Eraser,
          icon: CupertinoIcons.bandage,
          onTap: () => controller.setPaintContent(Eraser(color: Colors.white))),
      DefToolItem(
          startButton: true,
          isActive: false,
          onTap: onTimerStart,
          buttonText: buttonText)
    ];
  }

  static Widget buildDefaultActions(
      DrawingController controller, BuildContext context) {
    return _DrawingBoardState.buildDefaultActions(controller, context);
  }

  static Widget buildDefaultTools(DrawingController controller,
      {DefaultToolsBuilder? defaultToolsBuilder, Axis axis = Axis.horizontal}) {
    return _DrawingBoardState.buildDefaultTools(controller,
        defaultToolsBuilder: defaultToolsBuilder, axis: axis);
  }

  @override
  State<DrawingBoard> createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard> {
  late final DrawingController _controller =
      widget.controller ?? DrawingController();

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = InteractiveViewer(
      maxScale: widget.maxScale,
      minScale: widget.minScale,
      boundaryMargin: widget.boardBoundaryMargin ??
          EdgeInsets.all(MediaQuery.of(context).size.width),
      clipBehavior: widget.boardClipBehavior,
      panAxis: widget.panAxis,
      constrained: widget.boardConstrained,
      onInteractionStart: widget.onInteractionStart,
      onInteractionUpdate: widget.onInteractionUpdate,
      onInteractionEnd: widget.onInteractionEnd,
      scaleFactor: widget.boardScaleFactor,
      panEnabled: widget.boardPanEnabled,
      scaleEnabled: widget.boardScaleEnabled,
      transformationController: widget.transformationController,
      child: Align(alignment: widget.alignment, child: _buildBoard),
    );

    return Listener(
      onPointerDown: (PointerDownEvent pde) =>
          _controller.addFingerCount(pde.localPosition),
      onPointerUp: (PointerUpEvent pue) =>
          _controller.reduceFingerCount(pue.localPosition),
      onPointerCancel: (PointerCancelEvent pce) =>
          _controller.reduceFingerCount(pce.localPosition),
      child: Column(
        children: <Widget>[
          Expanded(child: content), // Use Expanded to take available space
          SizedBox(
            height: 100,
          ),
          if (widget.showDefaultActions)
            Column(
              children: [
                buildDefaultActions(_controller, context),
                SizedBox(
                  height: 10,
                ),
                buildDefaultTools(_controller,
                    onTimerStart: widget.onTimerStart,
                    buttonText: widget.buttonText,
                    defaultToolsBuilder: widget.defaultToolsBuilder)
              ],
            )

          // if (widget.showDefaultTools)
          //   buildDefaultTools(_controller,
          //       onTimerStart: widget.onTimerStart,
          //       buttonText: widget.buttonText,
          //       defaultToolsBuilder: widget.defaultToolsBuilder),
        ],
      ),
    );
  }

  /// 构建画板
  Widget get _buildBoard {
    return RepaintBoundary(
      key: _controller.painterKey,
      child: ExValueBuilder<DrawConfig>(
        valueListenable: _controller.drawConfig,
        shouldRebuild: (DrawConfig p, DrawConfig n) =>
            p.angle != n.angle || p.size != n.size,
        builder: (_, DrawConfig dc, Widget? child) {
          Widget c = child!;

          if (dc.size != null) {
            final bool isHorizontal = dc.angle.toDouble() % 2 == 0;
            final double max = dc.size!.longestSide;

            if (!isHorizontal) {
              c = SizedBox(width: max, height: max, child: c);
            }
          }

          return Transform.rotate(angle: dc.angle * pi / 2, child: c);
        },
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[_buildImage, _buildPainter],
          ),
        ),
      ),
    );
  }

  /// 构建背景
  Widget get _buildImage => GetSize(
        onChange: (Size? size) => _controller.setBoardSize(size),
        child: widget.background,
      );

  /// 构建绘制层
  Widget get _buildPainter {
    return ExValueBuilder<DrawConfig>(
      valueListenable: _controller.drawConfig,
      shouldRebuild: (DrawConfig p, DrawConfig n) => p.size != n.size,
      builder: (_, DrawConfig dc, Widget? child) {
        return SizedBox(
          width: dc.size?.width,
          height: dc.size?.height,
          child: child,
        );
      },
      child: Painter(
        drawingController: _controller,
        onPointerDown: widget.onPointerDown,
        onPointerMove: widget.onPointerMove,
        onPointerUp: widget.onPointerUp,
      ),
    );
  }

  static Widget buildDefaultActions(
      DrawingController controller, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Color(0XFF069FDE),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(CupertinoIcons.arrow_turn_up_left),
              color: Colors.white,
              onPressed: () => controller.undo(),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.arrow_turn_up_right),
              color: Colors.white,
              onPressed: () => controller.redo(),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.rotate_right),
              color: Colors.white,
              onPressed: () => controller.turn(),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.trash),
              color: Colors.white,
              onPressed: () => controller.clear(),
            ),
            IconButton(
              icon: const Icon(Icons.color_lens),
              color: Colors.white,
              onPressed: () {
                _showColorPicker(controller, context);
              },
            ),
            SizedBox(
              height: 24,
              width: 160,
              child: ExValueBuilder<DrawConfig>(
                valueListenable: controller.drawConfig,
                shouldRebuild: (DrawConfig p, DrawConfig n) =>
                    p.strokeWidth != n.strokeWidth,
                builder: (_, DrawConfig dc, ___) {
                  return Slider(
                    value: dc.strokeWidth,
                    max: 50,
                    min: 1,
                    activeColor: Colors.white,
                    inactiveColor: Colors.grey,
                    onChanged: (double v) =>
                        controller.setStyle(strokeWidth: v),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showColorPicker(
      DrawingController controller, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Pick a color',
            style: TextStyle(color: Colors.black),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: Colors.red,
              onColorChanged: (Color color) {
                controller.setStyle(color: color);
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Done',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Build default toolbar
  static Widget buildDefaultTools(
    DrawingController controller, {
    VoidCallback? onTimerStart,
    DefaultToolsBuilder? defaultToolsBuilder,
    String? buttonText,
    Axis axis = Axis.horizontal,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Color(0XFF069FDE),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: SingleChildScrollView(
        scrollDirection: axis,
        padding: EdgeInsets.zero,
        child: ExValueBuilder<DrawConfig>(
          valueListenable: controller.drawConfig,
          shouldRebuild: (DrawConfig p, DrawConfig n) =>
              p.contentType != n.contentType,
          builder: (_, DrawConfig dc, ___) {
            final Type currType = dc.contentType;

            final List<Widget> children =
                (defaultToolsBuilder?.call(currType, controller) ??
                        DrawingBoard.defaultTools(
                            onTimerStart, currType, controller, buttonText))
                    .map((DefToolItem item) => _DefToolItemWidget(item: item))
                    .toList();

            return axis == Axis.horizontal
                ? Row(children: children)
                : Column(children: children);
          },
        ),
      ),
    );
  }
}

/// 默认工具项配置文件
class DefToolItem {
  DefToolItem(
      {required this.startButton,
      this.icon,
      required this.isActive,
      this.onTap,
      this.color,
      this.activeColor = Colors.blue,
      this.iconSize,
      this.buttonText});

  final Function()? onTap;
  bool isActive;

  final bool startButton;
  final IconData? icon;
  final double? iconSize;
  final Color? color;
  final Color activeColor;
  final String? buttonText;
}

/// 默认工具项 Widget
class _DefToolItemWidget extends StatelessWidget {
  const _DefToolItemWidget({
    required this.item,
  });

  final DefToolItem item;

  @override
  Widget build(BuildContext context) {
    return item.startButton
        ? TextButton(
            onPressed: item.onTap,
            child: Text(
              item.buttonText!,
              style: TextStyle(color: Colors.white),
            ))
        : IconButton(
            onPressed: item.onTap,
            icon: Icon(
              item.icon,
              color: item.isActive ? item.activeColor : item.color,
              size: item.iconSize,
            ),
          );
  }
}
