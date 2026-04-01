import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:tallermecanico/almacen/models/models_folior.dart';

List<Folior> _parseFolior(String body) {
  final decoded = json.decode(body);
  if (decoded is List) {
    return decoded.map<Folior>((e) => Folior.fromJson(e)).toList();
  } else if (decoded is Map<String, dynamic>) {
    // por si algún día regresa un objeto único
    return [Folior.fromJson(decoded)];
  }
  throw Exception('Formato no esperado: ${decoded.runtimeType}');
}

class FoliorService {
  static const String _url = '';

  Future<List<Folior>> fetchFolios() async {
    final r = await http.get(Uri.parse(_url));
    if (r.statusCode != 200) {
      throw Exception('HTTP ${r.statusCode}');
    }
    final list = await compute(_parseFolior, r.body);

    // ordenar por fecha desc si existe
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    list.sort((a, b) => (b.fecha ?? epoch).compareTo(a.fecha ?? epoch));
    return list;
  }
}
