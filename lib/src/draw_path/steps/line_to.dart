import 'dart:developer';

import 'operation_step.dart';

class LineTo extends OperationStep {
  LineTo(this.x, this.y);

  factory LineTo.fromJson(Map<String, dynamic> data) {
    try {
      final double doubleX = (data['x'] is int)
          ? (data['x'] as int).toDouble()
          : data['x'] as double;
      final double doubleY = (data['y'] is int)
          ? (data['y'] as int).toDouble()
          : data['y'] as double;
      return LineTo(doubleX, doubleY);
    } catch (e) {
      log(e.toString());
      return LineTo(0.0, 0.0); // Return a default value in case of an exception
    }
  }

  final double x;
  final double y;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': 'lineTo',
      'x': x,
      'y': y,
    };
  }
}
