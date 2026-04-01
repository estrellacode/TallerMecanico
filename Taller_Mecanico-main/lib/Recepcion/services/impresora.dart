import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';

class Impresora {
  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;
  BluetoothDevice? _cachedDevice;

  /// Intenta conectar a un dispositivo ya emparejado.
  /// Puedes filtrar por nombre parcial
  Future<bool> connect({String nameContains = 'SPP-R200'}) async {
    final bonded = await _printer.getBondedDevices();
    if (bonded.isEmpty) return false;

    // Busca por nombre. Si no encuentra, toma el primero para pruebas.
    _cachedDevice = bonded.firstWhere(
      (d) => (d.name ?? '').toUpperCase().contains(nameContains.toUpperCase()),
      orElse: () => bonded.first,
    );

    try {
      await _printer.connect(_cachedDevice!);
      return await _printer.isConnected ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> ensureConnected({String nameContains = 'SPP-R200'}) async {
    final connected = await _printer.isConnected ?? false;
    if (!connected) {
      final ok = await connect(nameContains: nameContains);
      if (!ok) {
        throw 'No se pudo conectar a la impresora. ¿Está emparejada y encendida?';
      }
    }
  }

  Future<void> printPase({
    required String folio,
    required String mecanico,
    required String vehiculo,
    String nombreImpresoraContiene = 'SPP-RP00III_033055', //
  }) async {
    await ensureConnected(nameContains: nombreImpresoraContiene);

    // ===== Contenido del ticket =====
    _printer.printNewLine();
    _printer.printCustom('PASE A JEFE DE PATIO', 3, 1); // grande, centrado
    _printer.printNewLine();

    _printer.printCustom('Folio: _________________', 1, 0);
    _printer.printCustom('Mecánico: _________________', 1, 0);
    _printer.printCustom('Vehículo: _________________', 1, 0);

    final fecha = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    _printer.printCustom('Fecha: $fecha', 1, 0);

    _printer.printNewLine();
    _printer.printQRcode(folio, 200, 200, 1); // QR con el folio
    _printer.printNewLine();
    _printer.paperCut();
  }

  Future<void> disconnect() async {
    try {
      await _printer.disconnect();
    } catch (_) {}
  }
}
