// ======== ESCANEO DEL CHOFER Y ECONOMICO ==========
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:honeywell_scanner/honeywell_scanner.dart';
import 'package:honeywell_scanner/scanner_callback.dart';
import 'package:http/http.dart' as http;
import 'package:tallermecanico/Recepcion/interfaces/principal.dart';
import 'package:tallermecanico/Recepcion/models/models_chofer.dart';
import 'package:tallermecanico/Recepcion/models/models_economicos.dart';
import 'package:tallermecanico/Recepcion/services/service_chofer.dart';
import 'package:tallermecanico/Recepcion/services/service_economico.dart';

enum ScanTarget { chofer, economico }

class Servicio extends StatefulWidget {
  const Servicio({super.key});

  @override
  State<Servicio> createState() => _ServicioState();
}

class _ServicioState extends State<Servicio>
    with WidgetsBindingObserver
    implements ScannerCallback {
  // ===== Servicio Chofer =====
  final _choferService = ChoferService();

  // ===== Servicio Económico =====
  final _economicoService = EconomicoService();

  // Antirebote para evitar múltiples búsquedas simultáneas
  bool _busy = false;

  // Teclado en automatico:
  final _focusChofer = FocusNode();
  final _focusEconomico = FocusNode();

  // Valores mostrados/resultados
  String? chofer;
  String? economico;

  // Controllers visibles en UI
  final choferQR = TextEditingController();
  final economicoQR = TextEditingController();

  // Activar escritura manual por campo
  bool escribirChofer = false;
  bool escribirEconomico = false;

  //Cuando se identifica ocultamos la edicion
  bool _choferFijado = false;

  // Mostrar nombre encontrado
  Chofer? _chofer;
  String? _choferNombre;
  String? _choferNombreFmt;
  String? _choferNumero;

  // Mostrar Económico encontrado
  Economico? _eco;
  String? _ecoNumero;
  String? _ecoDescripcion;

  // Revisar si los datos se enviaron o no
  bool _enviando = false;

  //Cambiar el dominio
  static const baseUrl = 'http://192.168.16.40';

  // ======= Honeywell scanner =======
  final HoneywellScanner scanner = HoneywellScanner();
  bool scannerActivo = false;
  ScanTarget target = ScanTarget.chofer; // primero CHOFER

  // ===== Estilos para destacar número y nombre =====
  final TextStyle _numeroGrandeStyle = const TextStyle(
    fontSize: 20, // más grande
    fontWeight: FontWeight.w900,
    letterSpacing: 0.5,
  );

  final TextStyle _nombreSobreLineaStyle = const TextStyle(
    fontSize: 18, // más grande que antes
    fontWeight: FontWeight.w800,
  );

  //Cambiar el chofer si se quiere editar
  void _habilitarCambioChofer() {
    // vuelve a mostrar TextField y botones para re-escanear/escribir
    setState(() {
      _choferFijado = false;
      escribirChofer = false; // empieza en modo escaneo
      target = ScanTarget.chofer;
    });
    _iniciarScanner();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scanner.setScannerCallback(this);
    _iniciarScanner();
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

  Future<void> _mostrarTeclado(FocusNode node, {required bool esChofer}) async {
    await _pausarScanner();
    setState(() {
      escribirChofer = esChofer;
      escribirEconomico = !esChofer;
      target = esChofer ? ScanTarget.chofer : ScanTarget.economico;
    });

    // Pide foco y abre teclado después del frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      node.requestFocus();
      await SystemChannels.textInput.invokeMethod('TextInput.show');
    });
  }

  Future<void> _ocultarTeclado() async {
    setState(() {
      escribirChofer = false;
      escribirEconomico = false;
    });
    _focusChofer.unfocus();
    _focusEconomico.unfocus();

    // Cierra el teclado explícitamente
    await SystemChannels.textInput.invokeMethod('TextInput.hide');

    // Reanuda el escáner
    await _iniciarScanner();
  }

  //Diseño para los AlertDialog
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
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                label: const Text('Cerrar'),
              ),
            ),
          ],
        );
      },
    );
  }

  // Función para crear el folio
  Future<void> _crearFolio() async {
    if (_enviando) return;

    // 1) Tomar números actuales desde UI/estado
    //    Chofer: limpio (sin letra / sin ceros a la izquierda)
    final choferNumero = _limpiaNumero(
      (_choferNumero?.trim().isNotEmpty ?? false)
          ? _choferNumero!
          : choferQR.text.trim(),
    );

    //    Económico
    final economicoNumero = (_ecoNumero?.trim().isNotEmpty ?? false)
        ? _ecoNumero!.trim()
        : economicoQR.text.trim();

    if (choferNumero.isEmpty || economicoNumero.isEmpty) {
      await _mostrarAlertaBonita(
        titulo: 'Faltan datos',
        mensaje: 'Verifica que el chofer y el económico estén capturados.',
      );
      return;
    }

    setState(() => _enviando = true);
    await _pausarScanner();

    try {
      final uri = Uri.parse('$baseUrl/api/hst/folio');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chofer': choferNumero,
          'economico': economicoNumero,
        }),
      );

      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
      }

      final decoded = jsonDecode(resp.body);
      String? folio;
      if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
        folio = (decoded.first as Map)['folioESI']?.toString();
      }

      if (folio == null || folio.isEmpty) {
        throw Exception('Respuesta sin folioESI válido.');
      }

      await _mostrarFolioESIDialog(folio);
      await _resetForm();
    } catch (e) {
      await _mostrarDialogo(
        titulo: 'Error',
        mensaje: 'No se pudo crear el folio.\n$e',
      );
    } finally {
      setState(() => _enviando = false);
      // Reanuda escáner si no hay teclado abierto
      if (!escribirChofer && !escribirEconomico) {
        await _iniciarScanner();
      }
    }
  }

  @override
  void dispose() {
    _choferService.dispose(); // cierra http.Client
    _focusChofer.dispose();
    _focusEconomico.dispose();
    _economicoService.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _pausarScanner();
    try {
      scanner.disposeScanner();
    } catch (_) {}
    choferQR.dispose();
    economicoQR.dispose();
    super.dispose();
  }

  //========= Ciclo de vida ===============
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _iniciarScanner();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _pausarScanner();
    }
  }

  // ================== Scanner callbacks ==================
  @override
  Future<void> onDecoded(ScannedData? data) async {
    final code = data?.code?.trim();
    if (code == null || code.isEmpty) return;

    if (escribirChofer || escribirEconomico) return;

    if (target == ScanTarget.chofer) {
      final numeroPreview = _limpiaNumero(code);
      setState(() {
        choferQR.text = code;
        chofer = code;
        _choferNumero = numeroPreview;
      });

      final ok = await _buscarChoferPorNumero(code);

      choferQR.clear();

      if (mounted) {
        setState(() {
          target = ok ? ScanTarget.economico : ScanTarget.chofer;
        });
      }
    } else {
      // === ECONÓMICO ===
      setState(() {
        economicoQR.text = code;
        economico = code;
      });

      await _buscarEconomico(code);
    }
  }

  @override
  void onError(Exception error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error de escaneo: $error')));
  }

  String _limpiaNumero(String raw) {
    final matches = RegExp(r'\d+').allMatches(raw);
    if (matches.isEmpty) return '';

    var digits = matches
        .map((m) => m.group(0)!)
        .reduce((a, b) => a.length >= b.length ? a : b);
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    return digits;
  }

  // Reordena "APELLIDO_P APELLIDO_M NOMBRES..." -> "NOMBRES... APELLIDO_P APELLIDO_M"
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

  // ================== Apoyo UI ==================
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Busca chofer en API, actualiza _choferNombre y refleja en línea
  Future<bool> _buscarChoferPorNumero(String raw) async {
    if (!mounted || _busy) return false;
    setState(() => _busy = true);

    try {
      await _pausarScanner();

      final numeroLimpio = _limpiaNumero(raw);
      if (numeroLimpio.isEmpty) {
        await _mostrarAlertaBonita(
          titulo: 'Número inválido',
          mensaje: 'Escanea o escribe un número de chofer válido.',
        );
        return false;
      }

      final ch = await _choferService.buscarPorNumero(numeroLimpio);

      if (ch == null) {
        setState(() {
          _chofer = null;
          _choferNombre = null;
          _choferNombreFmt = null;
          _choferNumero = null;
        });
        await _mostrarAlertaBonita(
          titulo: 'No encontrado',
          mensaje: 'No se encontró un chofer con ese número.',
        );
        //
        return false;
      }

      final nombreCrudo = ch.nombre.trim();
      setState(() {
        _chofer = ch;
        _choferNombre = nombreCrudo;
        _choferNombreFmt = _nombresLuegoApellidos(nombreCrudo);
        _choferNumero = numeroLimpio;
        chofer = choferQR.text.trim();
      });

      return true;
    } catch (e) {
      await _mostrarAlertaBonita(
        titulo: 'Error',
        mensaje: 'Ocurrió un error al consultar el chofer.\n$e',
      );
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
      if (!escribirChofer && !escribirEconomico) {
        await _iniciarScanner();
      }
    }
  }

  //Buscar economico
  Future<void> _buscarEconomico(String raw) async {
    if (!mounted || _busy) return;
    setState(() => _busy = true);

    try {
      await _pausarScanner();

      final numero = raw.trim();
      if (numero.isEmpty) {
        setState(() {
          _eco = null;
          _ecoNumero = null;
          _ecoDescripcion = null;
        });
        await _mostrarDialogo(
          titulo: 'Número inválido',
          mensaje: 'Escribe un número económico válido.',
        );
        return;
      }

      final eco = await _economicoService.buscarPorEconomico(numero);

      if (eco == null) {
        setState(() {
          _eco = null;
          _ecoNumero = null;
          _ecoDescripcion = null;
        });
        await _mostrarDialogo(
          titulo: 'No encontrado',
          mensaje: 'No se encontró un económico con ese número.',
        );
      } else {
        setState(() {
          _eco = eco;
          _ecoNumero = numero;
          _ecoDescripcion = eco.descripcion;
          economico = economicoQR.text.trim();
        });
      }
    } catch (e) {
      await _mostrarDialogo(
        titulo: 'Error',
        mensaje: 'Ocurrió un error al consultar el económico.\n$e',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
      if (!escribirChofer && !escribirEconomico) {
        await _iniciarScanner();
      }
    }
  }

  Future<void> _mostrarFolioESIDialog(String folio) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
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
                  'Folio creado',
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

  // Limpiar la pantalla
  Future<void> _resetForm() async {
    // Cierra teclado y limpia focos
    _focusChofer.unfocus();
    _focusEconomico.unfocus();
    await SystemChannels.textInput.invokeMethod('TextInput.hide');

    // Pausa y reanuda el escáner con una breve espera
    await _pausarScanner();
    await Future.delayed(const Duration(milliseconds: 150));

    if (!mounted) return;
    setState(() {
      // === Chofer ===
      _chofer = null;
      _choferNombre = null;
      _choferNombreFmt = null;
      _choferNumero = null;
      chofer = null;
      choferQR.clear();
      escribirChofer = false;
      _choferFijado = false;

      // === Económico ===
      _eco = null;
      _ecoNumero = null;
      _ecoDescripcion = null;
      economico = null;
      economicoQR.clear();
      escribirEconomico = false;

      target = ScanTarget.chofer;

      _busy = false;
      _enviando = false;
    });

    await _iniciarScanner();
  }

  Future<void> _confirmarCampo({required bool esChofer}) async {
    setState(() {
      if (esChofer) {
        chofer = choferQR.text.trim();
      } else {
        economico = economicoQR.text.trim();
      }
    });

    if (esChofer && (chofer?.isNotEmpty ?? false)) {
      await _buscarChoferPorNumero(chofer!);
    }

    await _ocultarTeclado(); // oculta teclado y reanuda scanner
  }

  // ================== UI ==================
  final ButtonStyle outlinedTall = OutlinedButton.styleFrom(
    foregroundColor: Colors.black,
    side: const BorderSide(color: Colors.black, width: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    minimumSize: const Size(0, 50),
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
            'Gasolina Magna',
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
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              // ===== CHOFER =====
              monochromeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chofer:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_choferNombreFmt != null &&
                        _choferNombreFmt!.isNotEmpty) ...[
                      // Vista solo de datos cuando ya se encontró chofer
                      if (_choferNumero != null &&
                          _choferNumero!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.tag, size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _choferNumero!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _numeroGrandeStyle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Nombre con línea debajo
                      _lineaResultado(
                        centro: _choferNombreFmt ?? '',
                        textStyle: _nombreSobreLineaStyle,
                      ),

                      const SizedBox(height: 8),

                      // Botón Cancelar
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          style: outlinedTall,
                          onPressed: () async {
                            setState(() {
                              _choferFijado = false;
                              _choferNombreFmt = null;
                              _choferNumero = null;
                              choferQR.clear();
                              chofer = null;

                              target = ScanTarget.chofer;

                              escribirChofer = false;
                              escribirEconomico = false;
                            });

                            _focusChofer.unfocus();
                            _focusEconomico.unfocus();
                            await SystemChannels.textInput.invokeMethod(
                              'TextInput.hide',
                            );

                            await _pausarScanner();
                            await Future.delayed(
                              const Duration(milliseconds: 150),
                            );
                            await _iniciarScanner();
                          },
                          child: const Text('Cancelar'),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: choferQR,
                        focusNode: _focusChofer,
                        readOnly: !escribirChofer,
                        keyboardType: escribirChofer
                            ? TextInputType.text
                            : TextInputType.none,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Chofer',
                          hintText: 'Escanea o pulsa Escribir',
                          prefixIcon: Icon(Icons.person),
                        ),
                        onSubmitted: (v) async {
                          final preview = _limpiaNumero(v);
                          setState(() => _choferNumero = preview);
                          setState(() => chofer = v.trim());
                          if (chofer != null && chofer!.isNotEmpty) {
                            await _buscarChoferPorNumero(chofer!);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: outlinedTall,
                              onPressed: () async {
                                final v = choferQR.text.trim();
                                setState(() => chofer = v);
                                if (v.isNotEmpty) {
                                  final ok = await _buscarChoferPorNumero(v);
                                  if (mounted) {
                                    setState(() {
                                      target = ok
                                          ? ScanTarget.economico
                                          : ScanTarget.chofer;
                                    });
                                  }
                                }
                              },
                              child: const Text('Filtrar'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              style: outlinedTall,
                              onPressed: () async {
                                if (!escribirChofer) {
                                  await _mostrarTeclado(
                                    _focusChofer,
                                    esChofer: true,
                                  );
                                } else {
                                  await _confirmarCampo(esChofer: true);
                                }
                              },
                              child: Text(
                                escribirChofer ? 'Confirmar' : 'Escribir',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // ===== ECONÓMICO =====
              monochromeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Placas Económico:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_ecoDescripcion != null &&
                        _ecoDescripcion!.isNotEmpty) ...[
                      if (_ecoNumero != null && _ecoNumero!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.tag, size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _ecoNumero!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _numeroGrandeStyle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      _lineaResultado(
                        centro: _ecoDescripcion ?? '',
                        textStyle: _nombreSobreLineaStyle,
                      ),

                      const SizedBox(height: 8),

                      // Botón Cancelar para volver a escribir/filtrar otro
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          style: outlinedTall,
                          onPressed: () async {
                            setState(() {
                              _eco = null;
                              _ecoNumero = null;
                              _ecoDescripcion = null;
                              economicoQR.clear();
                              economico = null;

                              target = ScanTarget.economico;

                              escribirChofer = false;
                              escribirEconomico = false;
                            });

                            _focusEconomico.unfocus();
                            await SystemChannels.textInput.invokeMethod(
                              'TextInput.hide',
                            );
                            await _pausarScanner();
                            await Future.delayed(
                              const Duration(milliseconds: 150),
                            );
                            await _iniciarScanner();
                          },
                          child: const Text('Cancelar'),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: economicoQR,
                        focusNode: _focusEconomico,
                        readOnly: false,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Placas/No. Económico',
                          hintText: 'Escribe el número económico',
                          prefixIcon: Icon(Icons.directions_car),
                        ),
                        onSubmitted: (v) async {
                          final t = v.trim();
                          setState(() {
                            _ecoNumero = t;
                            economico = t;
                          });
                          if (t.isNotEmpty) {
                            await _buscarEconomico(t);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: outlinedTall,
                          onPressed: () async {
                            final v = economicoQR.text.trim();
                            setState(() {
                              economico = v;
                              _ecoNumero = v;
                            });
                            if (v.isNotEmpty) {
                              await _buscarEconomico(v);
                            }
                          },
                          child: const Text('Filtrar'),
                        ),
                      ),

                      if ((economico ?? '').isNotEmpty)
                        _lineaResultado(centro: economico!, bold: true),
                    ],
                  ],
                ),
              ),

              // ===== Botones =====
              monochromeCard(
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      style: outlinedTall,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const Principal()),
                        );
                      },
                      icon: const Icon(Icons.arrow_back, size: 26),
                      label: const Text('Volver'),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      style: outlinedTall,
                      onPressed: _enviando
                          ? null
                          : () async {
                              await _crearFolio();
                            },
                      icon: _enviando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check, size: 26),
                      label: Text(_enviando ? 'Creando...' : 'Crear Folio'),
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

  Widget _lineaResultado({
    required String centro,
    bool bold = false,
    TextStyle? textStyle,
  }) {
    final base = TextStyle(
      fontSize: 18,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    );

    return Container(
      padding: const EdgeInsets.only(bottom: 1),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
      ),
      child: Text(
        centro,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        textAlign: TextAlign.center,
        style: (textStyle ?? base),
      ),
    );
  }
}
