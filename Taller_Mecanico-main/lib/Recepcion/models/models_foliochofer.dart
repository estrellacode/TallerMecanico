class FolioChofer {
  final String idFolioEsi;
  final String? nombre;
  final String? descripcion;
  final String? estatus;
  final DateTime? fecha;
  final String? total, iva, subTotal, descuento, uuid;

  FolioChofer({
    required this.idFolioEsi,
    this.nombre,
    this.descripcion,
    this.estatus,
    this.fecha,
    this.total,
    this.iva,
    this.subTotal,
    this.descuento,
    this.uuid,
  });

  factory FolioChofer.fromJson(Map<String, dynamic> j) {
    DateTime? parsed;
    final f = j['fecha']?.toString();
    if (f != null && f.trim().isNotEmpty) {
      parsed = DateTime.tryParse(f.replaceFirst(' ', 'T'));
    }
    return FolioChofer(
      idFolioEsi: j['id_folio_esi']?.toString() ?? '',
      nombre: j['nombre']?.toString(),
      descripcion: j['descripcion']?.toString(),
      estatus: j['estatus']?.toString(),
      fecha: parsed,
      total: j['total']?.toString(),
      iva: j['iva']?.toString(),
      subTotal: j['subTotal']?.toString(),
      descuento: j['descuento']?.toString(),
      uuid: j['UUID']?.toString(),
    );
  }
}
