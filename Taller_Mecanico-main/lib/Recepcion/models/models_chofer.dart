import 'package:flutter/foundation.dart';

@immutable
class Chofer {
  final int idchofer;
  final int visible;
  final String nombre;

  const Chofer({
    required this.idchofer,
    required this.visible,
    required this.nombre,
  });

  factory Chofer.fromJson(Map<String, dynamic> json) => Chofer(
    idchofer: (json['idchofer'] as num).toInt(),
    visible: (json['visible'] as num?)?.toInt() ?? 0,
    nombre: (json['nombre'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {
    'idchofer': idchofer,
    'visible': visible,
    'nombre': nombre,
  };
}
