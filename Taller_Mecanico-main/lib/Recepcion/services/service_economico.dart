import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:tallermecanico/Recepcion/models/models_economicos.dart';

class EconomicoService {
  EconomicoService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const baseUrl = 'http://192.168.16.40';

  String _sanitizeEconomico(String raw, {int minLen = 1, int? maxLen}) {
    final matches = RegExp(r'\d+').allMatches(raw);
    if (matches.isEmpty) return '';
    final longest = matches.reduce(
      (a, b) => a.group(0)!.length >= b.group(0)!.length ? a : b,
    );
    var digits = longest.group(0)!;
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    if (digits.isEmpty) return '';
    if (maxLen != null && digits.length > maxLen) {
      digits = digits.substring(0, maxLen);
    }
    if (digits.length < minLen) return '';
    return digits;
  }

  Future<Economico?> buscarPorEconomico(String raw) async {
    final numero = _sanitizeEconomico(raw);
    if (numero.isEmpty) return null;

    final uri = Uri.parse('$baseUrl/api/hst/economico/$numero');

    debugPrint('GET $uri');
    final resp = await _client
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 12));

    final preview = resp.body.isEmpty
        ? '(empty)'
        : resp.body.substring(0, resp.body.length.clamp(0, 120));
    debugPrint('HTTP ${resp.statusCode} body(120): $preview');

    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode} al consultar económico');
    }

    final body = resp.body.isEmpty ? '[]' : resp.body;

    final parsed = json.decode(body);

    if (parsed is List &&
        parsed.isNotEmpty &&
        parsed.first is Map<String, dynamic>) {
      return Economico.fromJson(parsed.first as Map<String, dynamic>);
    }
    if (parsed is Map<String, dynamic>) {
      return Economico.fromJson(parsed);
    }
    return null;
  }

  void dispose() => _client.close();
}

Economico? _parseEconomico(String body) {
  final parsed = json.decode(body);
  if (parsed is List && parsed.isNotEmpty) {
    final first = parsed.first;
    if (first is Map<String, dynamic>) {
      return Economico.fromJson(first);
    }
  } else if (parsed is Map<String, dynamic>) {
    return Economico.fromJson(parsed);
  }
  return null;
}
