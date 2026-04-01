import 'package:flutter/foundation.dart';

@immutable
class Economico {
  final int idEconomico;
  final String placas;
  final String economico;
  final String activo;
  final int idTipoEco;
  final String descripcion;
  final int tipoGasolina;
  final double rendimientoEstablecido;
  final String centroCosto;
  final DateTime? actualizado;

  const Economico({
    required this.idEconomico,
    required this.placas,
    required this.economico,
    required this.activo,
    required this.idTipoEco,
    required this.descripcion,
    required this.tipoGasolina,
    required this.rendimientoEstablecido,
    required this.centroCosto,
    required this.actualizado,
  });

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static DateTime? _parseFecha(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s.replaceFirst(' ', 'T'));
  }

  factory Economico.fromJson(Map<String, dynamic> json) => Economico(
    idEconomico: _toInt(json['idEconomico']),
    placas: (json['placas'] ?? '').toString(),
    economico: (json['economico'] ?? '').toString(),
    activo: (json['activo'] ?? '').toString(),
    idTipoEco: _toInt(json['idTipoEco']),
    descripcion: (json['descripcion'] ?? '').toString(),
    tipoGasolina: _toInt(json['tipoGasolina']),
    rendimientoEstablecido: _toDouble(json['rendimientoEstablecido']),
    centroCosto: (json['centroCosto'] ?? '').toString(),
    actualizado: _parseFecha(json['ACTUALIZADO']),
  );

  Map<String, dynamic> toJson() => {
    'idEconomico': idEconomico,
    'placas': placas,
    'economico': economico,
    'activo': activo,
    'idTipoEco': idTipoEco,
    'descripcion': descripcion,
    'tipoGasolina': tipoGasolina,
    'rendimientoEstablecido': rendimientoEstablecido,
    'centroCosto': centroCosto,
    'ACTUALIZADO': actualizado?.toIso8601String(),
  };
}
