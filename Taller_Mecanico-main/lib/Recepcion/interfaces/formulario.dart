import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class Formulario extends StatefulWidget {
  const Formulario({super.key});

  @override
  State<Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<Formulario> {
  // ===== Controllers del formulario =====
  final unidadCtrl = TextEditingController();
  final folioCtrl = TextEditingController();
  final fallaCtrl = TextEditingController();
  final choferCtrl = TextEditingController();
  final nombreCtrl = TextEditingController();
  final numeroCtrl = TextEditingController();

  //  FocusNodes para saltar entre campos
  final _fUnidad = FocusNode();
  final _fFolio = FocusNode();
  final _fFalla = FocusNode();
  final _fChofer = FocusNode();
  final _fNombre = FocusNode();
  final _fNumero = FocusNode();

  DateTime? fechaHora;

  //Opcion
  final List<String> _opcionesFirma = const ['Jefe de patio', 'Taller externo'];
  String _tipoFirma = 'Jefe de patio';

  // ===== Estilos reutilizables =====
  final ButtonStyle outlinedTall = OutlinedButton.styleFrom(
    foregroundColor: Colors.black,
    side: const BorderSide(color: Colors.black, width: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    minimumSize: const Size.fromHeight(56),
    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
  );

  Widget monochromeCard({required Widget child, EdgeInsets? padding}) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      );

  final _formKey = GlobalKey<FormState>();
  final _printer = BlueThermalPrinter.instance;

  @override
  void dispose() {
    // Controllers...
    unidadCtrl.dispose();
    folioCtrl.dispose();
    fallaCtrl.dispose();
    choferCtrl.dispose();
    nombreCtrl.dispose();
    numeroCtrl.dispose();

    // Libera FocusNodes
    _fUnidad.dispose();
    _fFolio.dispose();
    _fFalla.dispose();
    _fChofer.dispose();
    _fNombre.dispose();
    _fNumero.dispose();
    super.dispose();
  }

  // Date/Time pickers más ágiles + salto automático al siguiente campo
  Future<void> _pickFechaHora() async {
    final hoy = DateTime.now();

    final d = await showDatePicker(
      context: context,
      initialDate: fechaHora ?? hoy,
      firstDate: DateTime(hoy.year - 1),
      lastDate: DateTime(hoy.year + 1),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (d == null) return;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(fechaHora ?? hoy),
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (t == null) return;

    setState(() {
      fechaHora = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });

    // Al terminar fecha/hora, pasa foco al siguiente campo
    FocusScope.of(context).requestFocus(_fChofer);
  }

  // ESC t n  -> n=16 suele ser CP1252 en la mayoría de ESC/POS.
  Future<void> _setCodePageLatin1() async {
    await _printer.writeBytes(Uint8List.fromList([27, 116, 16])); // ESC t 16
  }

  // Imprime una línea usando latin1 y alineación ESC a n (0: izq, 1: centro, 2: der).
  Future<void> _printLine(String text, {int align = 0}) async {
    // Alinear
    await _printer.writeBytes(
      Uint8List.fromList([27, 97, align]),
    ); // ESC a align
    // Contenido en Latin-1:
    await _printer.writeBytes(Uint8List.fromList(latin1.encode(text)));
    // Nueva línea
    _printer.printNewLine();
  }

  // (Opcional) Tamaño de fuente: ESC ! n (combinación de bits; 0=normal, 16=doble alto, 32=doble ancho, 48=ambas)
  Future<void> _setFontSize({
    bool doubleHeight = false,
    bool doubleWidth = false,
  }) async {
    int n = 0;
    if (doubleHeight) n |= 16;
    if (doubleWidth) n |= 32;
    await _printer.writeBytes(Uint8List.fromList([27, 33, n])); // ESC ! n
  }

  String _fmtFechaHora(DateTime? dt) {
    if (dt == null) return 'Selecciona fecha y hora';
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    // cambia formato si lo prefieres: dd/MM/yyyy HH:mm
  }

  // ====== Permisos BT en tiempo de ejecución ======
  Future<void> _pedirPermisosBT() async {
    final res = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    final denied = res.values.any((s) => s.isDenied || s.isPermanentlyDenied);
    if (denied) {
      throw 'Otorga permisos de Bluetooth y Ubicación para imprimir.';
    }
  }

  // ====== Conexión simple a impresora emparejada ======
  Future<void> _conectarImpresora({String nameContains = 'SPP-R200'}) async {
    final bonded = await _printer.getBondedDevices();
    if (bonded.isEmpty) {
      throw 'No hay impresoras emparejadas. Empareja una en Ajustes → Bluetooth.';
    }
    // Filtra por nombre
    final dev = bonded.firstWhere(
      (d) => (d.name ?? '').toUpperCase().contains(nameContains.toUpperCase()),
      orElse: () => bonded.first,
    );

    try {
      await _printer.connect(dev);
    } catch (_) {
      // Ignora – a veces lanza aunque conecte
    }

    final ok = await _printer.isConnected ?? false;
    if (!ok) throw 'No se pudo conectar a la impresora.';
  }

  // ====== Imprimir ticket ======
  Future<void> _imprimir() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await _pedirPermisosBT();
    await _conectarImpresora(nameContains: 'SPP-RP00III_033055');

    // 1) Code page para acentos
    await _setCodePageLatin1();

    final fechaStr = _fmtFechaHora(fechaHora);
    final unidad = unidadCtrl.text.trim();
    final folio = folioCtrl.text.trim();
    final falla = fallaCtrl.text.trim();
    final chofer = choferCtrl.text.trim();
    final nombre = nombreCtrl.text.trim();
    final numero = numeroCtrl.text.trim();

    final etiquetaFirma = _tipoFirma == 'Jefe de patio'
        ? 'Jefe de patio'
        : 'Taller externo';

    _printer.printNewLine();

    // 2) Título grande y centrado con acentos correctos
    await _setFontSize(doubleHeight: true, doubleWidth: true);
    await _printLine(
      _tipoFirma == 'Jefe de patio'
          ? 'PASE A JEFE DE  PATIO'
          : 'PASE A TALLER  EXTERNO',
      align: 1,
    );
    await _setFontSize(); // volver a normal

    _printer.printNewLine();

    // 3) Campos con acentos
    await _printLine('Unidad: $unidad');
    await _printLine('Folio: $folio');
    await _printLine('Fecha y hora: $fechaStr'); // ← “hora” con minúscula
    await _printLine('Chofer: $chofer');

    _printer.printNewLine();
    await _printLine('Falla reportada:');

    // Envolver descripción (sin perder acentos)
    for (final linea in _wrapText(falla, 32)) {
      await _printLine(linea);
    }

    _printer.printNewLine();

    // Corrige etiquetas y usa las variables correctas:
    await _printLine('Nombre del chofer: $chofer');
    await _printLine('Número del chofer: $numero');

    _printer.printNewLine();

    await _printLine('$etiquetaFirma: $nombre');
    _printer.printNewLine();

    _printer.printNewLine();
    _printer.paperCut();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pase impreso correctamente')));
  }

  // Helper simple para envolver texto a cierto ancho
  List<String> _wrapText(String text, int maxChars) {
    final words = text.split(RegExp(r'\s+'));
    final lines = <String>[];
    var current = StringBuffer();

    for (final w in words) {
      final next = current.isEmpty ? w : '${current.toString()} $w';
      if (next.length <= maxChars) {
        current
          ..clear()
          ..write(next);
      } else {
        if (current.isNotEmpty) lines.add(current.toString());
        current
          ..clear()
          ..write(w);
      }
    }
    if (current.isNotEmpty) lines.add(current.toString());
    return lines;
  }

  void _limpiar() {
    unidadCtrl.clear();
    folioCtrl.clear();
    fallaCtrl.clear();
    choferCtrl.clear();
    nombreCtrl.clear();
    numeroCtrl.clear();
    setState(() => fechaHora = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: false,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      textTheme: Theme.of(context).textTheme
          .apply(bodyColor: Colors.black, displayColor: Colors.black)
          .copyWith(
            headlineSmall: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
            titleLarge: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
            bodyLarge: const TextStyle(fontSize: 18, inherit: false),
          ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black, width: 3),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            'Pase al jefe de patio',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                monochromeCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: unidadCtrl,
                        focusNode: _fUnidad,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_fFolio),
                        decoration: const InputDecoration(
                          labelText: 'Unidad',
                          hintText: 'Ej. ECO-23',
                          prefixIcon: Icon(Icons.local_shipping),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                      //=======FOLIO==========
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: folioCtrl,
                        focusNode: _fFolio,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_fFalla),
                        decoration: const InputDecoration(
                          labelText: 'Número de folio',
                          hintText: 'Ej. JP-0001',
                          prefixIcon: Icon(Icons.confirmation_number),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      //========DESCRIPCION=======
                      TextFormField(
                        controller: fallaCtrl,
                        focusNode: _fFalla,
                        maxLines: 3,
                        textInputAction:
                            TextInputAction.done, // o next (según teclado)
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_fChofer),
                        onEditingComplete: () =>
                            FocusScope.of(context).requestFocus(_fChofer),

                        decoration: const InputDecoration(
                          labelText: 'Falla reportada',
                          hintText: 'Describe brevemente la falla…',
                          prefixIcon: Icon(Icons.report_problem),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // ====== FECHA Y HORA ======
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: outlinedTall,
                              onPressed: _pickFechaHora,
                              icon: const Icon(Icons.calendar_month, size: 22),
                              label: Text(_fmtFechaHora(fechaHora)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ===== Selector: Jefe de patio / Taller externo =====
                      DropdownButtonFormField<String>(
                        value: _tipoFirma,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de firma',
                          prefixIcon: Icon(Icons.how_to_reg),
                        ),
                        items: _opcionesFirma
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _tipoFirma = v ?? 'Jefe de patio'),
                      ),
                      const SizedBox(height: 12),

                      //========CHOFER=========
                      TextFormField(
                        controller: choferCtrl,
                        focusNode: _fChofer,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_fNombre),

                        decoration: const InputDecoration(
                          labelText: 'Chofer',
                          hintText: 'Nombre del chofer',
                          prefixIcon: Icon(Icons.badge),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      //========NUMERO DEL CHOFER=========
                      TextFormField(
                        controller: numeroCtrl,
                        focusNode: _fNumero,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_fNumero),

                        decoration: const InputDecoration(
                          labelText: 'Numero del chofer',
                          hintText: 'Numero del chofer',
                          prefixIcon: Icon(Icons.badge),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // ===== NOMBRE SEGÚN TIPO =====
                      TextFormField(
                        controller: nombreCtrl,
                        focusNode: _fNombre,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          labelText: _tipoFirma == 'Jefe de patio'
                              ? 'Jefe de patio'
                              : 'Taller externo',
                          hintText: _tipoFirma == 'Jefe de patio'
                              ? 'Ej. Juan Pérez'
                              : 'Nombre del taller externo',
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Boton acción
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: outlinedTall,
                        onPressed: _imprimir,
                        icon: const Icon(Icons.print, size: 22),
                        label: Text(
                          'Imprimir pase a ${_tipoFirma.toLowerCase()}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: outlinedTall,
                        onPressed: _limpiar,
                        icon: const Icon(Icons.cleaning_services, size: 22),
                        label: const Text('Limpiar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
