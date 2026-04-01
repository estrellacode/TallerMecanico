import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tallermecanico/Recepcion/interfaces/formulario.dart';
import 'package:tallermecanico/interfaces/Asignacion.dart';
import 'package:tallermecanico/interfaces/Servicio.dart';

class Principal extends StatefulWidget {
  const Principal({super.key});
  @override
  State<Principal> createState() => _PrincipalState();
}

class _PrincipalState extends State<Principal> {
  final url = TextEditingController();

  @override
  void dispose() {
    url.dispose();
    super.dispose();
  }

  Future<void> solicitarPermisosBluetooth() async {
    final perms = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location, // requerido por algunos dispositivos para escaneo BT
    ].request();

    if (perms.values.any((s) => s.isDenied || s.isPermanentlyDenied)) {
      throw 'Otorga permisos de Bluetooth y Ubicación para imprimir.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).copyWith(
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

    final ButtonStyle outlinedTall = OutlinedButton.styleFrom(
      foregroundColor: Colors.black,
      side: const BorderSide(color: Colors.black, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      minimumSize: const Size.fromHeight(64), // solo altura
      textStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: .1,
      ),
    ).copyWith(alignment: Alignment.center);

    // Estilo de los textfield
    Widget monochromeCard({required Widget child, EdgeInsets? padding}) =>
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: padding ?? const EdgeInsets.all(10),
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
            'Taller Mecanico',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
          toolbarTextStyle: const TextStyle(color: Colors.black),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        width: 140,
                        cacheWidth: 280,
                        filterQuality: FilterQuality.low,
                      ),
                      Text(
                        'Taller Mecánico',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),

                // ============== Botones =============
                monochromeCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: outlinedTall,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const Servicio(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.assignment_return, size: 26),
                          label: const Text(
                            'Nuevo folio de hoja de servicio',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: outlinedTall,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const Asignacion(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.local_shipping, size: 26),
                          label: const Text(
                            'Asignar mecanico a vehiculo',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: outlinedTall,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const Formulario(),
                              ),
                            );
                          },

                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Icon(Icons.person, size: 26),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 40),
                                child: Center(
                                  child: Text(
                                    'Imprimir pase al jefe de patio',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: const Text(
              'Agropecuaria El Avión S.P.R. de R.L.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}
