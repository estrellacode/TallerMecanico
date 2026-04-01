import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:honeywell_scanner/honeywell_scanner.dart';
import 'package:honeywell_scanner/scanner_callback.dart';

class Salidasproductos extends StatefulWidget {
  final String folio;
  final String chofer;
  final String? economico;

  const Salidasproductos({
    super.key,
    required this.folio,
    required this.chofer,
    this.economico,
  });

  @override
  State<Salidasproductos> createState() => _SalidasproductosState();
}

class _SalidasproductosState extends State<Salidasproductos>
    with WidgetsBindingObserver
    implements ScannerCallback {
  // Valor del código QR (último escaneado o escrito)
  String? codigoQr;

  // Honeywell scanner
  final HoneywellScanner scanner = HoneywellScanner();
  bool scannerActivo = false;

  // Escritura manual
  final TextEditingController _qrCtrl = TextEditingController();
  final FocusNode _qrFocus = FocusNode();
  bool escribirManual = false;

  final ButtonStyle outlinedTall = OutlinedButton.styleFrom(
    foregroundColor: Colors.black,
    side: const BorderSide(color: Colors.black, width: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    minimumSize: const Size(0, 56),
    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
  );

  Widget monochromeCard({required Widget child, EdgeInsets? padding}) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scanner.setScannerCallback(this);
    _iniciarScanner();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _qrCtrl.dispose();
    _qrFocus.dispose();
    _pausarScanner();
    try {
      scanner.disposeScanner();
    } catch (_) {}
    super.dispose();
  }

  // ===== Ciclo de vida =====
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!escribirManual) _iniciarScanner();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _pausarScanner();
    }
  }

  // ===== Control del escáner =====
  Future<void> _iniciarScanner() async {
    try {
      await scanner.startScanner();
    } catch (_) {
      try {
        await scanner.startScanning();
      } catch (_) {}
    }
    if (mounted) {
      setState(() => scannerActivo = true);
    }
  }

  Future<void> _pausarScanner() async {
    try {
      await scanner.stopScanner();
    } catch (_) {
      try {
        await scanner.stopScanning();
      } catch (_) {}
    }
    if (mounted) {
      setState(() => scannerActivo = false);
    }
  }

  // ===== Escritura manual =====
  Future<void> _mostrarTecladoManual() async {
    await _pausarScanner();
    setState(() => escribirManual = true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _qrFocus.requestFocus();
      await SystemChannels.textInput.invokeMethod('TextInput.show');
    });
  }

  Future<void> _cerrarTecladoYReanudar() async {
    _qrFocus.unfocus();
    await SystemChannels.textInput.invokeMethod('TextInput.hide');
    setState(() => escribirManual = false);
    await _iniciarScanner();
  }

  void _confirmarManual() {
    final code = _qrCtrl.text.trim();
    if (code.isEmpty) {
      // si quieres puedes mostrar un SnackBar aquí
      _cerrarTecladoYReanudar();
      return;
    }

    setState(() {
      codigoQr = code;
    });

    _cerrarTecladoYReanudar();
  }

  void _reiniciarCodigo() {
    setState(() {
      codigoQr = null;
      _qrCtrl.clear();
    });
  }

  // ===== Callbacks del Honeywell =====
  @override
  Future<void> onDecoded(ScannedData? data) async {
    final code = data?.code?.trim();
    if (!mounted) return;
    if (code == null || code.isEmpty) return;

    // Si está en modo escribir manual, ignoramos lecturas
    if (escribirManual) return;

    setState(() {
      codigoQr = code;
      _qrCtrl.text = code; // se refleja en el TextField
    });
  }

  @override
  void onError(Exception error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error de escaneo: $error')));
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Colors.black,
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
            bodyLarge: const TextStyle(fontSize: 18),
            bodyMedium: const TextStyle(fontSize: 16),
          ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Colors.black54, fontSize: 16),
        labelStyle: const TextStyle(color: Colors.black, fontSize: 16),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 2),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 3),
          borderRadius: BorderRadius.all(Radius.circular(16)),
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
            'Salidas',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            IconButton(
              tooltip: 'Limpiar código',
              onPressed: _reiniciarCodigo,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 100),
            children: [
              // ===== Encabezado (igual que antes) =====
              monochromeCard(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HdrRow(label: 'Movimiento:', value: 'Salidas'),
                    const SizedBox(height: 12),
                    _HdrRow(label: 'Folio:', value: widget.folio),
                    const SizedBox(height: 12),
                    _HdrRow(label: 'Chofer:', value: widget.chofer),
                    const SizedBox(height: 12),
                    _HdrRow(
                      label: 'Economico:',
                      value: (widget.economico ?? '').isEmpty
                          ? null
                          : widget.economico,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ===== Campo de escaneo / escritura del QR =====
              monochromeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Código QR:',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _qrCtrl,
                      focusNode: _qrFocus,
                      readOnly: !escribirManual,
                      keyboardType: escribirManual
                          ? TextInputType.text
                          : TextInputType.none,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'QR',
                        hintText: 'Escanea el código o pulsa Escribir',
                        prefixIcon: Icon(Icons.qr_code_2),
                      ),
                      onSubmitted: (_) => _confirmarManual(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.qr_code_scanner, size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            scannerActivo && !escribirManual
                                ? 'Escáner listo, apunta al código.'
                                : 'Modo escritura manual.',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ===== Botones inferiores: Volver / Escribir =====
              monochromeCard(
                child: Row(
                  children: [
                    // Volver (izquierda)
                    OutlinedButton.icon(
                      style: outlinedTall,
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back, size: 26),
                      label: const Text('Volver'),
                    ),
                    const Spacer(),
                    // Escribir / Confirmar (derecha)
                    OutlinedButton(
                      style: outlinedTall,
                      onPressed: () async {
                        if (!escribirManual) {
                          // Activar modo escritura
                          await _mostrarTecladoManual();
                        } else {
                          // Confirmar valor escrito
                          _confirmarManual();
                        }
                      },
                      child: Text(escribirManual ? 'Confirmar' : 'Escribir'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== Row para encabezado con línea inferior =====
class _HdrRow extends StatelessWidget {
  final String label;
  final String? value;

  const _HdrRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    final labelStyle =
        (Theme.of(context).textTheme.titleLarge ??
        const TextStyle(fontSize: 20, fontWeight: FontWeight.w700));
    final valueStyle =
        (Theme.of(context).textTheme.bodyLarge ??
        const TextStyle(fontSize: 18));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 130),
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(label, style: labelStyle, textAlign: TextAlign.left),
          ),
        ),
        Expanded(
          child: Container(
            height: 32,
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: (value == null || value!.isEmpty)
                  ? const SizedBox(height: 26)
                  : Text(
                      value!,
                      style: valueStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
