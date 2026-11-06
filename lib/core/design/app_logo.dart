import 'package:flutter/widgets.dart';

/// Marca de Solar Safe Smart Station usada dentro de la interfaz Flutter.
///
/// La fuente única es `design/mobile/logo.png`. El script `tool/sync_logo.sh`
/// prepara a partir de ella los iconos de inicio de Android, iOS y Web.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    'design/mobile/logo.png',
    width: size,
    height: size,
    // `contain` conserva la proporción de la ilustración si el contenedor
    // cambia de forma en una pantalla futura.
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
  );
}
