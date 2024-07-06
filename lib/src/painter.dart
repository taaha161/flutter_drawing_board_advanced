import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_drawing_board_advanced/src/paint_contents/text.dart';

import 'drawing_controller.dart';
import 'helper/ex_value_builder.dart';
import 'paint_contents/paint_content.dart';

/// 绘图板
class Painter extends StatelessWidget {
  const Painter({
    super.key,
    required this.drawingController,
    this.clipBehavior = Clip.antiAlias,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
  });

  /// 绘制控制器
  final DrawingController drawingController;

  /// 开始拖动
  final Function(PointerDownEvent pde)? onPointerDown;

  /// 正在拖动
  final Function(PointerMoveEvent pme)? onPointerMove;

  /// 结束拖动
  final Function(PointerUpEvent pue)? onPointerUp;

  /// 边缘裁剪方式
  final Clip clipBehavior;

  /// 手指落下
  void _onPointerDown(PointerDownEvent pde) {
    if (!drawingController.couldDraw) {
      return;
    }

    Future<void>.delayed(const Duration(milliseconds: 50), () {
      if (!drawingController.couldDraw) {
        return;
      }

      drawingController.startDraw(pde.localPosition);
      onPointerDown?.call(pde);
    });
  }

  /// 手指移动
  void _onPointerMove(PointerMoveEvent pme) {
    if (!drawingController.couldDraw) {
      if (drawingController.currentContent != null) {
        drawingController.endDraw();
      }
      return;
    }

    drawingController.drawing(pme.localPosition);
    onPointerMove?.call(pme);
  }

  /// 手指抬起
  void _onPointerUp(PointerUpEvent pue) {
    if (!drawingController.couldDraw ||
        drawingController.currentContent == null) {
      return;
    }

    if (drawingController.startPoint == pue.localPosition) {
      drawingController.drawing(pue.localPosition);
    }

    drawingController.endDraw();
    onPointerUp?.call(pue);
  }

  void _onPointerCancel(PointerCancelEvent pce) {
    if (!drawingController.couldDraw) {
      return;
    }

    drawingController.endDraw();
  }

  /// GestureDetector 占位
  void _onPanDown(DragDownDetails ddd) {}

  void _onPanUpdate(DragUpdateDetails dud) {}

  void _onPanEnd(DragEndDetails ded) {}

  Future<String?> _showTextInputDialog(
      BuildContext context, Offset tapPosition) async {
    TextEditingController _textEditingController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierColor: Colors.transparent, // Makes the background transparent
      builder: (BuildContext context) {
        return Align(
          alignment: Alignment(
              (tapPosition.dx - MediaQuery.of(context).size.width / 2) /
                  (MediaQuery.of(context).size.width / 2),
              (tapPosition.dy - MediaQuery.of(context).size.height / 2) /
                  (MediaQuery.of(context).size.height / 2)),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 300,
              height: 150,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.transparent, // Semi-transparent background
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    style: TextStyle(color: Colors.white),
                    controller: _textEditingController,
                    decoration: const InputDecoration(
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        hintText: "Type your text here",
                        hintStyle: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text(
                          'OK',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.of(context)
                              .pop(_textEditingController.text);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      behavior: HitTestBehavior.opaque,
      child: ExValueBuilder<DrawConfig>(
        valueListenable: drawingController.drawConfig,
        shouldRebuild: (DrawConfig p, DrawConfig n) =>
            p.fingerCount != n.fingerCount,
        builder: (_, DrawConfig config, Widget? child) {
          return GestureDetector(
            onPanDown: config.fingerCount <= 1 ? _onPanDown : null,
            onPanUpdate: config.fingerCount <= 1 ? _onPanUpdate : null,
            onPanEnd: config.fingerCount <= 1 ? _onPanEnd : null,
            onTapDown: (details) async {
              if (drawingController.currentContent is TextPainterContent) {
                final textPainterContent =
                    drawingController.currentContent as TextPainterContent;
                log(drawingController.currentContent.toString());
                final String? enteredText =
                    await _showTextInputDialog(context, details.globalPosition);
                if (enteredText != null && enteredText.isNotEmpty) {
                  if (!drawingController.couldDraw) {
                    log("I cannot draw");
                    return;
                  }

                  textPainterContent.startDraw(details.localPosition);
                  textPainterContent.text = enteredText;
                  drawingController.addContent(textPainterContent);
                }
              }
            },
            child: child,
          );
        },
        child: ClipRect(
          clipBehavior: clipBehavior,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _DeepPainter(controller: drawingController),
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _UpPainter(controller: drawingController),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 表层画板
class _UpPainter extends CustomPainter {
  _UpPainter({required this.controller}) : super(repaint: controller.painter);

  final DrawingController controller;

  @override
  void paint(Canvas canvas, Size size) {
    if (controller.currentContent == null) {
      return;
    }

    controller.currentContent?.draw(canvas, size, false);
  }

  @override
  bool shouldRepaint(covariant _UpPainter oldDelegate) => false;
}

/// 底层画板
class _DeepPainter extends CustomPainter {
  _DeepPainter({required this.controller})
      : super(repaint: controller.realPainter);
  final DrawingController controller;

  @override
  void paint(Canvas canvas, Size size) {
    final List<PaintContent> contents = controller.getHistory;

    if (contents.isEmpty) {
      return;
    }

    canvas.saveLayer(Offset.zero & size, Paint());

    for (int i = 0; i < controller.currentIndex; i++) {
      contents[i].draw(canvas, size, true);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DeepPainter oldDelegate) => false;
}
