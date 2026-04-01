class AsignacionMecanicoRes {
  final String? pase;
  final int? error;
  final String? mecanico;
  final String? uuid;

  AsignacionMecanicoRes({this.pase, this.error, this.mecanico, this.uuid});

  factory AsignacionMecanicoRes.fromJsonDynamic(dynamic json) {
    if (json is List && json.isNotEmpty) {
      return AsignacionMecanicoRes.fromMap(json.first as Map<String, dynamic>);
    } else if (json is Map<String, dynamic>) {
      return AsignacionMecanicoRes.fromMap(json);
    }
    return AsignacionMecanicoRes();
  }

  factory AsignacionMecanicoRes.fromMap(Map<String, dynamic> map) {
    return AsignacionMecanicoRes(
      pase: map['pase'] as String?,
      error: map['error'] is int
          ? map['error'] as int
          : int.tryParse('${map['error']}'),
      mecanico: map['mecanico']?.toString(),
      uuid: map['UUID']?.toString(),
    );
  }

  bool get ok => (error ?? 0) == 0;
}
