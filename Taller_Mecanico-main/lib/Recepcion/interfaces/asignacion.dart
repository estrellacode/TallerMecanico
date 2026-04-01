// ====== PANTALLA DE TABLA PARA SELECCIÓN DE FOLIO  =======

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tallermecanico/Recepcion/interfaces/principal.dart';
import 'package:tallermecanico/Recepcion/interfaces/registro.dart';
import 'package:tallermecanico/Recepcion/models/models_foliochofer.dart';
import 'package:tallermecanico/Recepcion/services/service_folio.dart';

class Asignacion extends StatefulWidget {
  const Asignacion({super.key});
  @override
  State<Asignacion> createState() => _AsignacionState();
}

class _AsignacionState extends State<Asignacion> {
  // Controla el scroll horizontal de la tabla.
  final _hScrollCtrl = ScrollController();

  // ======= Servicio, datos y estado =======
  final service = FolioService();
  final fmt = DateFormat('yyyy-MM-dd HH:mm');
  List<FolioChofer> folios = [];
  bool cargando = true;
  String? error;

  DateTime _lastRefresh = DateTime.fromMillisecondsSinceEpoch(0);
  static const _refreshCooldown = Duration(seconds: 2);

  String _formateaNombre(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return '-';

    if (s.contains(',')) {
      final parts = s.split(',');
      final izq = parts[0].trim();
      final der = parts.sublist(1).join(',').trim();
      final nombres = _toTitle(der);
      final apes = _toTitle(izq);
      return '$nombres $apes';
    }

    final tokens = s.split(RegExp(r'\s+'));
    if (tokens.length >= 3) {
      final apP = tokens[0];
      final apM = tokens[1];
      final nombres = tokens.sublist(2).join(' ');
      return '${_toTitle(nombres)} ${_toTitle(apP)} ${_toTitle(apM)}';
    }

    return _toTitle(s);
  }

  String _toTitle(String x) {
    return x
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  // Datos del encabezado
  String? folio;
  String? chofer;

  // Índice de la fila seleccionada en la tabla (null = ninguna).
  int? seleccionarfila;

  // Color de fondo para resaltar la fila seleccionada.
  Color _rowColor(bool selected) =>
      selected ? const Color(0xFFDEE9FF) : Colors.transparent;

  @override
  void initState() {
    super.initState();
    cargarFolios();
  }

  // ======== Cargar la tabla ============
  Future<void> cargarFolios() async {
    setState(() {
      cargando = true;
      error = null;
      seleccionarfila = null;
      // Limpia encabezado al recargar
      folio = chofer = null;
    });

    try {
      final list = await service.fetchFolios();

      // ===== PRUEBA PARA VER QUE SI SE TOMEN LOS DATOS =========
      debugPrint('Folios recibidos: ${list.length}');
      if (list.isNotEmpty) {
        debugPrint(
          'Primer folio: ${list.first.idFolioEsi} | Chofer: ${list.first.descripcion}',
        );
      }

      setState(() {
        folios = list;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final sm = ScaffoldMessenger.of(context);
        sm.clearSnackBars(); // evita solapamientos
        sm.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(12),
            content: Text('No se pudieron cargar los folios: $e'),
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _hScrollCtrl.dispose();
    super.dispose();
  }

  /// Estilo común para los botones inferiores:
  final ButtonStyle outlinedTall = OutlinedButton.styleFrom(
    foregroundColor: Colors.black,
    side: const BorderSide(color: Colors.black, width: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    minimumSize: const Size(0, 64),
    textStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: .2,
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Tema visual general
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

    /// Contenedor reutilizable con estética tipo "tarjeta".
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

    return Theme(
      data: theme,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
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
          actions: [
            IconButton(
              tooltip: 'Actualizar',
              onPressed: cargarFolios,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),

        body: SafeArea(
          child: Column(
            children: [
              // Parte scrollable.
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(5, 5, 5, 100),
                  children: [
                    // ===== Encabezado de información =====
                    monochromeCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InfoRow(
                            label: 'Movimiento: Asignar mecanico',
                            labelFontSize: 18,
                            valueFontSize: 18,
                            underline: false,
                          ),
                          const SizedBox(height: 12),
                          InfoRow(
                            label: 'Folio:',
                            value: folio,
                            labelFontSize: 18,
                            valueFontSize: 18,
                          ),
                          const SizedBox(height: 12),
                          InfoRow(
                            label: 'Chofer:',
                            value: chofer,
                            labelFontSize: 18,
                            valueFontSize: 18,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ======= Tabla de registros desde el API =======
                    monochromeCard(child: _cuerpoTabla()),
                  ],
                ),
              ),

              // ===== Pie fijo con botones de acción =====
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                child: monochromeCard(
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        style: outlinedTall,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const Principal(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_back, size: 26),
                        label: const Text('Volver'),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        style: outlinedTall,
                        onPressed: (seleccionarfila == null)
                            ? null
                            : () {
                                final folioSel =
                                    folio; // se llena al tocar la fila
                                final choferSel = chofer; // opcional

                                if (folioSel == null ||
                                    folioSel.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Selecciona un folio primero',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        Registro(folioSeleccionado: folioSel),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.check, size: 26),
                        label: const Text('Aceptar'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======== Creación de la tabla ===========
  Widget _cuerpoTabla() {
    if (cargando) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Ocurrió un error al cargar los datos:\n$error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: cargarFolios,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (folios.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('Sin registros')),
      );
    }

    // === columnas: Folio y Chofer ===
    const double wFolio = 200;
    const double wChofer = 420;
    const double wDivider = 1;
    const double totalTableWidth = wFolio + wDivider + wChofer;

    // Altura aprox. del footer (card + botones).
    const double kFooterOverlapPadding = 110.0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        controller: _hScrollCtrl,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _hScrollCtrl,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalTableWidth,
            child: Column(
              children: [
                // Encabezado con línea inferior suave
                Container(
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF6F6F6),
                    border: Border(
                      bottom: BorderSide(color: Colors.black12, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Columna "Folio" con borde derecho
                      Container(
                        width: wFolio,
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.black26, width: 1),
                          ),
                        ),
                        child: const _HeaderCell('Folio'),
                      ),

                      // Columna "Chofer"
                      const SizedBox(
                        width: wChofer,
                        child: _HeaderCell('Chofer'),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  height: 400,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: folios.length + 2,

                    itemBuilder: (context, i) {
                      // 1) Spacer para que no lo tape el footer con botones
                      if (i == folios.length + 1) {
                        return const SizedBox(height: 110.0);
                      }
                      // 2) Divider final bajo la última fila
                      if (i == folios.length) {
                        return const Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.black12,
                        );
                      }

                      // 3) Fila normal
                      final f = folios[i];
                      final isSel = (seleccionarfila == i);

                      final choferTxt = (() {
                        final d = (f.descripcion ?? '').trim();
                        if (d.isNotEmpty) return d;
                        final n = (f.nombre ?? '').trim();
                        return n.isNotEmpty ? n : '-';
                      })();

                      void onTapRow() {
                        setState(() {
                          final wasSelected = (seleccionarfila == i);
                          seleccionarfila = wasSelected ? null : i;
                          if (!wasSelected) {
                            folio = f.idFolioEsi;
                            chofer = _formateaNombre(choferTxt);
                          } else {
                            folio = chofer = null;
                          }
                        });
                      }

                      return Column(
                        children: [
                          Material(
                            color: isSel
                                ? const Color(0xFFDEE9FF)
                                : Colors.transparent,
                            child: InkWell(
                              onTap: onTapRow,
                              child: SizedBox(
                                height: 48,
                                child: Row(
                                  children: [
                                    // Columna Folio (con divisor vertical)
                                    Container(
                                      width: 200, // = wFolio
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: Colors.black26,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: _BodyCell(f.idFolioEsi),
                                    ),
                                    // Columna Chofer
                                    SizedBox(
                                      width: 420, // = wChofer
                                      child: _BodyCell(
                                        _formateaNombre(choferTxt),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Divider entre filas
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.black12,
                          ),
                        ],
                      );
                    },
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

/// Fila de información para el encabezado.
class InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final double labelMinWidth;
  final double? labelFontSize;
  final double? valueFontSize;
  final bool underline;

  const InfoRow({
    super.key,
    required this.label,
    this.value,
    this.labelMinWidth = 70,
    this.labelFontSize,
    this.valueFontSize,
    this.underline = true,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyleBase =
        Theme.of(context).textTheme.titleLarge ??
        const TextStyle(fontSize: 20, fontWeight: FontWeight.w700);
    final valueStyleBase =
        Theme.of(context).textTheme.bodyLarge ?? const TextStyle(fontSize: 18);

    final labelStyle = labelStyleBase.copyWith(fontSize: labelFontSize);
    final valueStyle = valueStyleBase.copyWith(fontSize: valueFontSize);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: labelMinWidth),
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(label, style: labelStyle, textAlign: TextAlign.left),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 32, // alto del renglón
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                if (underline)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        height: 2, // grosor de la línea
                        color:
                            Colors.black26, // súbele si la quieres más visible
                      ),
                    ),
                  ),

                // Texto por encima de la línea
                Container(
                  padding: const EdgeInsets.only(right: 4),
                  // usa el color del card para que “corte” bien la línea
                  color: Colors.white, // <- tu monochromeCard usa fondo blanco
                  child: (value == null || value!.isEmpty)
                      ? const SizedBox(height: 26)
                      : Text(
                          value!,
                          style: valueStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool alignRight;
  const _HeaderCell(this.text, {this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    final style =
        (Theme.of(context).textTheme.titleLarge ??
        const TextStyle(fontSize: 18, fontWeight: FontWeight.w700));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          text,
          style: style.copyWith(fontWeight: FontWeight.w800),
          softWrap: false,
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final String text;
  final bool alignRight;
  const _BodyCell(this.text, {this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    final style =
        (Theme.of(context).textTheme.bodyLarge ??
        const TextStyle(fontSize: 16));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          text,
          style: style,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
