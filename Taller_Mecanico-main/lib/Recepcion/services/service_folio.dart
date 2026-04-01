// services/service_folio.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/models_foliochofer.dart';

List<FolioChofer> _parseFolios(String body) {
  final decoded = json.decode(body);
  dynamic payload = decoded;
  if (decoded is Map && decoded['folios'] is List) {
    payload = decoded['folios'];
  }

  if (payload is List) {
    return payload
        .map<FolioChofer>(
          (e) => FolioChofer.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  } else if (payload is Map<String, dynamic>) {
    return [FolioChofer.fromJson(payload)];
  }
  throw Exception('Formato no esperado: ${decoded.runtimeType}');
}

class FolioService {
  static const baseUrl = 'http://192.168.16.40';
  static const _url = '$baseUrl/api/hst/folioChofer';

  Future<List<FolioChofer>> fetchFolios() async {
    final r = await http.get(Uri.parse(_url));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    final list = await compute(_parseFolios, r.body);

    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    list.sort((a, b) {
      final db = b.fecha ?? epoch;
      final da = a.fecha ?? epoch;
      return db.compareTo(da);
    });

    return list;
  }
}
