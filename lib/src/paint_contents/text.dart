import 'package:flutter/painting.dart';
import '../draw_path/draw_path.dart';
import '../paint_extension/ex_paint.dart';

import 'paint_content.dart';

/// Custom drawing of text
class TextPainterContent extends PaintContent {
  TextPainterContent();

  TextPainterContent.data({
    required this.startPoint,
    required this.text,
    required Paint paint,
  }) : super.paint(paint);

  factory TextPainterContent.fromJson(Map<String, dynamic> data) {
    return TextPainterContent.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      text: data['text'] as String,
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  Offset startPoint = Offset.zero;
  String text = "";

  @override
  void startDraw(Offset startPoint) => this.startPoint = startPoint;

  @override
  void drawing(Offset nowPoint) {
    // No need to implement this for text drawing
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: paint.color,
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, startPoint);
  }

  @override
  TextPainterContent copy() => TextPainterContent();

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'startPoint': startPoint.OffsettoJson(),
      'text': text,
      'paint': paint.toJson(),
    };
  }
}

// Helper functions to convert between JSON and Offset/Paint
Offset jsonToOffset(Map<String, dynamic> json) {
  return Offset(json['dx'] as double, json['dy'] as double);
}

Paint jsonToPaint(Map<String, dynamic> json) {
  final paint = Paint()
    ..color = Color(json['color'] as int)
    ..style = PaintingStyle.values[json['style'] as int]
    ..strokeWidth = (json['strokeWidth'] as int).toDouble();
  return paint;
}

extension OffsetExtension on Offset {
  Map<String, dynamic> OffsettoJson() {
    return <String, dynamic>{'dx': dx, 'dy': dy};
  }
}
