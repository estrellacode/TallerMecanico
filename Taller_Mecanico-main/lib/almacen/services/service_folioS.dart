import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tallermecanico/almacen/models/models_folios.dart';

class FoliosService {
  static const _url = '';
  final http.Client _client = http.Client();

  Future<List<Folios>> fetchFolios() async {
    final uri = Uri.parse(_url);
    final res = await _client.get(uri);

    if (res.statusCode != 200) {
      throw Exception('Error HTTP ${res.statusCode}: ${res.body}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final foliosJson = (body['folios'] as List?) ?? const [];

    return foliosJson
        .map((e) => Folios.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  void dispose() {
    _client.close();
  }
}
