import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tallermecanico/Recepcion/models/models_asignarmecanico.dart';

class MecanicoAsignacionService {
  MecanicoAsignacionService({http.Client? client})
    : _client = client ?? http.Client();

  static const baseUrl = 'http://192.168.16.40';
  final http.Client _client;
  static const _url = '$baseUrl/api/hst/mecanico';

  Future<AsignacionMecanicoRes> asignar({
    required String folio,
    required String mecanico, // ya limpio (sin ceros izq. ni letra)
  }) async {
    final uri = Uri.parse(_url);
    final r = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'folio': folio.trim(), 'mecanico': mecanico.trim()}),
    );

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('HTTP ${r.statusCode}: ${r.body}');
    }

    dynamic decoded;
    try {
      decoded = json.decode(r.body);
    } catch (_) {
      decoded = null;
    }
    return AsignacionMecanicoRes.fromJsonDynamic(decoded);
  }
}
