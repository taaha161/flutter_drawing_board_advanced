import 'dart:developer';

import 'operation_step.dart';

class MoveTo extends OperationStep {
  const MoveTo(this.x, this.y);

  factory MoveTo.fromJson(Map<String, dynamic> data) {
    try {
      final double doubleX = (data['x'] is int)
          ? (data['x'] as int).toDouble()
          : data['x'] as double;
      final double doubleY = (data['y'] is int)
          ? (data['y'] as int).toDouble()
          : data['y'] as double;
      return MoveTo(doubleX, doubleY);
    } catch (e) {
      log(e.toString());
      return MoveTo(0.0, 0.0); // Return a default value in case of an exception
    }
  }

  final double x;
  final double y;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': 'moveTo',
      'x': x,
      'y': y,
    };
  }
}
