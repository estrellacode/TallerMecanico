import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tallermecanico/almacen/interfaces/regresosproductos.dart';
import 'package:tallermecanico/almacen/models/models_folior.dart';
import 'package:tallermecanico/almacen/services/service_folioR.dart';

// ====== PANTALLA: Regresos (antes "Regresos") ======
class Regresos extends StatefulWidget {
  const Regresos({super.key});

  @override
  State<Regresos> createState() => _RegresosState();
}

class _RegresosState extends State<Regresos> {
  static const double wFolio = 200;
  static const double wChofer = 420;
  static const double totalTableWidth = wFolio + wChofer;

  final _hScrollCtrl = ScrollController();
  final service =
      FoliorService(); // debe tener fetchFolios(): Future<List<Folios>>
  final fmt = DateFormat('yyyy-MM-dd HH:mm');

  List<Folior> folios = [];
  bool cargando = true;
  String? error;

  String? folio; // encabezado seleccionado
  String? chofer;
  String? economico;
  int? seleccionarfila;

  @override
  void initState() {
    super.initState();
    cargarFolios();
  }

  @override
  void dispose() {
    _hScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> cargarFolios() async {
    setState(() {
      cargando = true;
      error = null;
      seleccionarfila = null;
      folio = chofer = economico = null;
    });

    try {
      final list = await service.fetchFolios();
      setState(() => folios = list);
    } catch (e) {
      setState(() => error = e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo cargar: $e')));
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  String _formateaNombre(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return '-';
    if (s.contains(',')) {
      final parts = s.split(',');
      final izq = parts[0].trim(); // apellidos
      final der = parts.sublist(1).join(',').trim(); // nombres
      return '${_toTitle(der)} ${_toTitle(izq)}';
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

  String _toTitle(String x) => x
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  final ButtonStyle outlinedTall = OutlinedButton.styleFrom(
    foregroundColor: Colors.black,
    side: const BorderSide(color: Colors.black, width: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    minimumSize: const Size(0, 56),
    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            'Regresos',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
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
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(5, 5, 5, 100),
                  children: [
                    // ===== Encabezado =====
                    monochromeCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const InfoRow(
                            label: 'Movimiento:',
                            value: 'Regresos',
                          ),
                          const SizedBox(height: 12),
                          InfoRow(label: 'Folio:', value: folio),
                          const SizedBox(height: 12),
                          InfoRow(label: 'Chofer:', value: chofer),
                          const SizedBox(height: 12),
                          InfoRow(label: 'Economico:', value: economico),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // ===== Tabla =====
                    monochromeCard(child: _tabla(monochromeCard)),
                  ],
                ),
              ),
              // ===== Footer =====
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                child: monochromeCard(
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        style: outlinedTall,
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back, size: 26),
                        label: const Text('Volver'),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        style: outlinedTall,
                        onPressed: (seleccionarfila == null)
                            ? null
                            : () {
                                final f = folios[seleccionarfila!];
                                final choferTxt = _formateaNombre(
                                  (f.empleado ?? '').trim(),
                                );
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => Regresosproductos(
                                      folio: f.idFolioEsi,
                                      chofer: choferTxt,
                                      economico: f.economico?.toString(),
                                    ),
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

  Widget _tabla(
    Widget Function({required Widget child, EdgeInsets? padding})
    monochromeCard,
  ) {
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
            Text('Error al cargar:\n$error', textAlign: TextAlign.center),
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
                // ===== Header =====
                Container(
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF6F6F6),
                    border: Border(
                      bottom: BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  child: Row(
                    children: const [
                      SizedBox(
                        width: _RegresosState.wFolio,
                        child: _HeaderCell('Folio'),
                      ),
                      SizedBox(
                        width: _RegresosState.wChofer,
                        child: _HeaderCell('Chofer'),
                      ),
                    ],
                  ),
                ),
                // ===== Body =====
                SizedBox(
                  height: 400,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    // +1 para forzar línea inferior aun con 1 solo dato
                    itemCount: folios.length + 1,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.black12,
                    ),
                    itemBuilder: (context, i) {
                      // Último: separador final (línea inferior global)
                      if (i == folios.length) {
                        return const SizedBox.shrink();
                      }

                      final f = folios[i];
                      final isSel = (seleccionarfila == i);
                      final choferTxt = _formateaNombre(
                        (f.empleado ?? '').trim(),
                      );

                      return Material(
                        color: isSel
                            ? const Color(0xFFDEE9FF)
                            : Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              final wasSelected = (seleccionarfila == i);
                              seleccionarfila = wasSelected ? null : i;
                              if (!wasSelected) {
                                folio = f.idFolioEsi;
                                chofer = choferTxt;
                                economico = f.economico?.toString() ?? '';
                              } else {
                                folio = chofer = economico = null;
                              }
                            });
                          },
                          child: SizedBox(
                            height: 48,
                            child: Row(
                              children: [
                                Container(
                                  width: wFolio,
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
                                SizedBox(
                                  width: wChofer,
                                  child: _BodyCell(choferTxt),
                                ),
                              ],
                            ),
                          ),
                        ),
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

// ===== Widgets auxiliares (Regresos) =====
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
    this.labelMinWidth = 100,
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
          child: Container(
            height: 32,
            alignment: Alignment.centerLeft,
            decoration: underline
                ? const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.black, width: 2),
                    ),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
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
