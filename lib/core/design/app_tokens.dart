import 'package:flutter/material.dart';

/// Paleta compartida del diseño Stitch; evita colores repetidos en widgets.
abstract final class AppColors {
  static const background = Color(0xfff8f9fa);
  static const surface = Colors.white;
  static const navy = Color(0xff003f87);
  static const blue = Color(0xff0056b3);
  static const ink = Color(0xff191c1d);
  static const muted = Color(0xff424752);
  static const outline = Color(0xffc2c6d4);
  static const green = Color(0xff006e1c);
  static const greenLight = Color(0xff91f78e);
  static const red = Color(0xffba1a1a);
  static const redLight = Color(0xffffdad6);
  static const orange = Color(0xffff720b);
  static const softBlue = Color(0xffeaf1fb);
  static const purple = Color(0xff7030a0);
  static const border = Color(0xffe4e8ee);
  static const yellow = Color(0xffffbd00);
}

/// Espaciados reutilizables para conservar el ritmo visual entre pantallas.
abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const page = 20.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}
