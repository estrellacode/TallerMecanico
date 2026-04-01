class Folios {
  final String idFolioEsi;
  final int? economico; // viene en "nombre"
  final String? empleado; // viene en "descripcion"
  final DateTime? fecha;
  final String estatus;
  final String? uuid;

  Folios({
    required this.idFolioEsi,
    this.economico,
    this.empleado,
    this.fecha,
    required this.estatus,
    this.uuid,
  });

  factory Folios.fromMap(Map<String, dynamic> m) {
    // "nombre" puede venir como int o como String
    int? econ;
    final rawNombre = m['nombre'];
    if (rawNombre is int) {
      econ = rawNombre;
    } else if (rawNombre is String) {
      econ = int.tryParse(rawNombre);
    }

    // parsear fecha "2025-11-19 08:44:13"
    DateTime? f;
    final rawFecha = m['fecha'] as String?;
    if (rawFecha != null && rawFecha.isNotEmpty) {
      // DateTime.parse acepta "2025-11-19 08:44:13" en la mayoría de casos,
      // si diera lata, se puede forzar con replace:
      f = DateTime.tryParse(rawFecha.replaceFirst(' ', 'T'));
    }

    return Folios(
      idFolioEsi: m['id_folio_esi'] as String,
      economico: econ,
      empleado: m['descripcion'] as String?,
      fecha: f,
      estatus: (m['estatus'] ?? '') as String,
      uuid: m['UUID']?.toString(),
    );
  }
}
