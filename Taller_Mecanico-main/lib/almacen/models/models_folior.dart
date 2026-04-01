// models/models_folios.dart
class Folior {
  final String idFolioEsi; // "RT251105.1"
  final int? economico; // 10001
  final DateTime? fecha; // "2025-11-05 13:18:58"
  final String? empleado; // "SEGURA CASTAÑEDA, JOSE LEONIDES"
  final String? estatus; // "A"
  final String? total, iva, subTotal, descuento;

  Folior({
    required this.idFolioEsi,
    this.economico,
    this.fecha,
    this.empleado,
    this.estatus,
    this.total,
    this.iva,
    this.subTotal,
    this.descuento,
  });

  factory Folior.fromJson(Map<String, dynamic> j) {
    DateTime? parsed;
    final f = j['fecha']?.toString();
    if (f != null && f.trim().isNotEmpty) {
      // "YYYY-MM-DD HH:mm:ss" -> ISO-like
      parsed = DateTime.tryParse(f.replaceFirst(' ', 'T'));
    }
    return Folior(
      idFolioEsi: j['id_folio_esi']?.toString() ?? '',
      economico: int.tryParse(j['economico']?.toString() ?? ''),
      fecha: parsed,
      empleado: j['empleado']?.toString(),
      estatus: j['estatus']?.toString(),
      total: j['total']?.toString(),
      iva: j['iva']?.toString(),
      subTotal: j['subTotal']?.toString(),
      descuento: j['descuento']?.toString(),
    );
  }
}
