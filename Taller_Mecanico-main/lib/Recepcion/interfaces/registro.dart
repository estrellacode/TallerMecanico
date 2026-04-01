//========== SELECCIÓN DEL FOLIO Y ASIGNACIÓN DEL MECANICO ========

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:honeywell_scanner/honeywell_scanner.dart';
import 'package:honeywell_scanner/scanner_callback.dart';
import 'package:tallermecanico/Recepcion/models/models_chofer.dart';
import 'package:tallermecanico/Recepcion/services/service_asignarmecanico.dart';
import 'package:tallermecanico/Recepcion/services/service_chofer.dart';

enum ScanTarget { qrmecanico }

class Registro extends StatefulWidget {
  const Registro({super.key, required this.folioSeleccionado});

  final String folioSeleccionado;

  @override
  State<Registro> createState() => _RegistroState();
}

class _RegistroState extends State<Registro>
    with WidgetsBindingObserver
    implements ScannerCallback {
  bool _busy = false;

  // Resultado del mecánico encontrado
  Chofer? _mec;
  String? _mecNumero; // número limpio (del QR/teclado)
  String? _mecNombreFmt;

  // Teclado en automatico:
  final _focusMecanico = FocusNode();

  // Activar escritura manual por campo
  bool escribirMecanico = false;

  // ======= Honeywell scanner =======
  final HoneywellScanner scanner = HoneywellScanner();
  bool scannerActivo = false;

  // ===== Servicio Chofer =====
  final _mecanicoService = ChoferService();

  //Valores mostrados
  String? mecanico;
  String? mensajeExito;

  // Controllers visibles en UI
  final mecanicoQR = TextEditingController();
  final mensajeExitoso = TextEditingController();

  //Asignación de mecanico
  final _asigService = MecanicoAsignacionService();
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scanner.setScannerCallback(this);
    _iniciarScanner();
  }

  // Helpers
  String _limpiaNumero(String raw) {
    final matches = RegExp(r'\d+').allMatches(raw);
    if (matches.isEmpty) return '';
    var digits = matches
        .map((m) => m.group(0)!)
        .reduce((a, b) => a.length >= b.length ? a : b);
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    return digits;
  }

  String _nombresLuegoApellidos(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.length >= 3) {
      final apellidos = parts.take(2).join(' ');
      final nombres = parts.skip(2).join(' ');
      return ('$nombres $apellidos').trim();
    } else if (parts.length == 2) {
      return ('${parts[1]} ${parts[0]}').trim();
    }
    return s.trim();
  }

  Future<void> _mostrarDialogo({
    required String titulo,
    required String mensaje,
  }) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ========== Alert Dialog con el mismo diseño ==========
  Future<void> _mostrarFolioESIDialog(String folio, {String? subtitulo}) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false, // que no se cierre por tocar fuera
      builder: (ctx) {
        final titleStyle = const TextStyle(
          fontSize: 24, // grande
          fontWeight: FontWeight.w900,
          color: Colors.black,
        );
        final folioStyle = const TextStyle(
          fontSize: 26, // MUY grande
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          color: Colors.black,
        );
        final bodyStyle = const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        );

        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          title: Row(
            children: [
              const Icon(Icons.receipt_long, size: 30, color: Colors.black),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Asignación exitosa',
                  style: titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (subtitulo != null) ...[
                Text(subtitulo, style: bodyStyle, textAlign: TextAlign.center),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Center(
                  child: SelectableText(
                    folio,
                    style: folioStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.check_circle,
                  size: 24,
                  color: Colors.white,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                label: const Text('Cerrar'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _resetUI() {
    setState(() {
      mecanicoQR.clear();
      mecanico = null;
      _mec = null;
      _mecNumero = null;
      _mecNombreFmt = null;
    });
    if (!escribirMecanico) {
      _iniciarScanner(); // deja listo el siguiente escaneo
    }
  }

  Future<void> _activarEscritura() async {
    await _pausarScanner();
    setState(() => escribirMecanico = true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _focusMecanico.requestFocus();

      await SystemChannels.textInput.invokeMethod('TextInput.show');
    });
  }

  Future<void> _iniciarScanner() async {
    try {
      await scanner.startScanner();
    } catch (_) {
      try {
        await scanner.startScanning();
      } catch (_) {}
    }
    if (mounted) setState(() => scannerActivo = true);
  }

  Future<void> _pausarScanner() async {
    try {
      await scanner.stopScanner();
    } catch (_) {
      try {
        await scanner.stopScanning();
      } catch (_) {}
    }
    if (mounted) setState(() => scannerActivo = false);
  }

  Future<void> _buscarMecanicoPorNumero(String raw) async {
    if (!mounted || _busy) return;
    setState(() => _busy = true);

    try {
      await _pausarScanner();

      final numeroLimpio = _limpiaNumero(raw);
      if (numeroLimpio.isEmpty) {
        await _mostrarDialogo(
          titulo: 'Número inválido',
          mensaje: 'Escanea o escribe un número de mecánico válido.',
        );
        return;
      }

      final ch = await _mecanicoService.buscarPorNumero(numeroLimpio);

      if (ch == null) {
        setState(() {
          _mec = null;
          _mecNombreFmt = null;
          _mecNumero = null;
        });
        await _mostrarDialogo(
          titulo: 'No encontrado',
          mensaje:
              'No se encontró un mecánico con ese número. '
              'Verifica el código y vuelve a intentar.',
        );
        return;
      }

      final nombreCrudo = ch.nombre.trim();
      setState(() {
        _mec = ch;
        _mecNumero = numeroLimpio;
        _mecNombreFmt = _nombresLuegoApellidos(nombreCrudo);
      });

      // 4) Ahora sí: asignar al folio
      await _asignarMecanicoAFolio(_mecNumero!);
    } catch (e) {
      await _mostrarDialogo(
        titulo: 'Error',
        mensaje: 'Ocurrió un error al consultar/asignar el mecánico.\n$e',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
      if (!escribirMecanico) {
        await _iniciarScanner();
      }
    }
  }

  Future<void> _asignarMecanicoAFolio(String mecanicoLimpio) async {
    if (_enviando) return;
    setState(() => _enviando = true);

    try {
      final res = await _asigService.asignar(
        folio: widget.folioSeleccionado,
        mecanico: mecanicoLimpio,
      );
      final ok = (res.ok == true) || (res.pase != null && res.pase!.isNotEmpty);

      if (ok) {
        final subtitulo = (_mecNombreFmt != null && _mecNumero != null)
            ? 'Mecánico: $_mecNombreFmt  (#$_mecNumero)'
            : null;

        await _mostrarFolioESIDialog(
          widget.folioSeleccionado,
          subtitulo: subtitulo,
        );

        _resetUI();

        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        final msg = res.pase ?? 'No se pudo asignar el mecánico.';
        await _mostrarDialogo(titulo: 'No asignado', mensaje: msg);
      }
    } catch (e) {
      await _mostrarDialogo(titulo: 'Error', mensaje: '$e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Future<void> onDecoded(ScannedData? data) async {
    final code = data?.code?.trim();
    if (code == null || code.isEmpty) return;
    if (escribirMecanico) return;

    final numeroPreview = _limpiaNumero(code);
    setState(() {
      mecanicoQR.text = code;
      mecanico = code;
      _mecNumero = numeroPreview;
    });

    await _buscarMecanicoPorNumero(code);
    mecanicoQR.clear(); // limpia el TextField para el próximo escaneo
  }

  Future<void> _mostrarAlertaBonita({
    required String titulo,
    required String mensaje,
  }) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final titleStyle = const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        );
        final bodyStyle = const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        );

        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 30,
                color: Colors.black,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  titulo,
                  style: titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mensaje, style: bodyStyle, textAlign: TextAlign.center),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.check_circle,
                  size: 24,
                  color: Colors.white,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                label: const Text('Cerrar'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _focusMecanico.dispose();
    _pausarScanner();
    _pausarScanner();
    try {
      scanner.disposeScanner();
    } catch (_) {}
    mecanicoQR.dispose();
    super.dispose();
  }

  //========= Ciclo de vida ]===============
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _iniciarScanner();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _pausarScanner();
    }
  }

  @override
  void onError(Exception error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error de escaneo:$error')));
  }

  // Metodo para cerrar escritura
  void _cerrarEscritura() {
    setState(() => escribirMecanico = false);
    _focusMecanico.unfocus();
    _iniciarScanner(); // reanuda el escáner Honeywell
  }

  final ButtonStyle outlinedTall = OutlinedButton.styleFrom(
    foregroundColor: Colors.black,
    side: const BorderSide(color: Colors.black, width: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    minimumSize: const Size(0, 50),
    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
  );

  final ButtonStyle outlinedSmall = OutlinedButton.styleFrom(
    foregroundColor: Colors.black,
    side: const BorderSide(color: Colors.black, width: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    minimumSize: const Size(0, 40), // más bajito
    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // reduce hitbox
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

    Widget card(Widget child, {EdgeInsets pad = const EdgeInsets.all(16)}) =>
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: pad,
          child: child,
        );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            'Taller Mecánico',
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
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(5),
                  children: [
                    // Folio + hora (opcional)
                    card(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            label: 'Folio Seleccionado:',
                            value: widget.folioSeleccionado,
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                      pad: const EdgeInsets.symmetric(horizontal: 16),
                    ),

                    const SizedBox(height: 16),

                    // Campo Mecánico + Filtrar
                    card(
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título de sección
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: const [
                              Text(
                                'Mecanico:',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // === TextField estilo Taller (mismo formato) ===
                          TextField(
                            controller: mecanicoQR,
                            focusNode: _focusMecanico,
                            readOnly:
                                !escribirMecanico, // bloqueado si no está en modo "Escribir"
                            keyboardType: TextInputType
                                .text, // cambia a number si solo quieres dígitos
                            textInputAction: TextInputAction.done,
                            onTap: () {
                              if (!escribirMecanico) _activarEscritura();
                            },
                            onChanged: (v) =>
                                setState(() => mecanico = v.trim()),
                            onSubmitted: (v) async {
                              setState(() => mecanico = v.trim());
                              final preview = _limpiaNumero(v);
                              setState(() => _mecNumero = preview);
                              if (mecanico != null && mecanico!.isNotEmpty) {
                                await _buscarMecanicoPorNumero(mecanico!);
                              }
                              _cerrarEscritura();
                            },
                            decoration: const InputDecoration(
                              hintText:
                                  'Escanea/escribe el número del mecánico',
                            ),
                            style: const TextStyle(fontSize: 18), // legible 40+
                          ),

                          const SizedBox(height: 12),

                          // Botones: Filtrar / Escribir-Cerrar
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: outlinedTall,
                                  onPressed: () async {
                                    final raw = mecanicoQR.text.trim();
                                    final preview = _limpiaNumero(raw);
                                    setState(() => _mecNumero = preview);

                                    if (preview.isEmpty) {
                                      await _mostrarAlertaBonita(
                                        titulo: 'Falta información',
                                        mensaje:
                                            'No se puede proceder sin escanear o colocar el mecánico.',
                                      );
                                      return;
                                    }

                                    await _buscarMecanicoPorNumero(raw);
                                  },

                                  child: const Text('Filtrar'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  style: outlinedTall,
                                  onPressed: () async {
                                    if (escribirMecanico) {
                                      _cerrarEscritura();
                                    } else {
                                      await _activarEscritura();
                                    }
                                  },
                                  child: Text(
                                    escribirMecanico ? 'Cerrar' : 'Escribir',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Pie fijo
              const SizedBox(height: 8),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180), //
                  child: monochromeCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: OutlinedButton.icon(
                      style: outlinedTall.copyWith(
                        minimumSize: WidgetStateProperty.all(const Size(0, 40)),
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                        ),
                        textStyle: WidgetStateProperty.all(
                          const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back, size: 20),
                      label: const Text('Volver'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({super.key, required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final labelStyle =
        textTheme.titleLarge ??
        const TextStyle(fontWeight: FontWeight.w700, fontSize: 20);

    // Fuerza color negro y herencia para que siempre se pinte
    final valueStyle = (textTheme.bodyLarge ?? const TextStyle(fontSize: 20))
        .copyWith(color: Colors.black, inherit: true);

    final v = value?.trim() ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text(label, style: labelStyle, textAlign: TextAlign.left),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 3),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.black26, width: 2),
              ),
            ),
            child: (v.isEmpty)
                ? const SizedBox(height: 32)
                : Text(
                    v,
                    style: valueStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
          ),
        ),
      ],
    );
  }
}
