import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

abstract final class ColoresAplicacion {
  static const fondo = Color(0xFF0B0B0F);
  static const superficie = Color(0xFF0E0E12);
  static const principal = Color(0xFFC8A2B7);
  static const texto = Color(0xFFF5F1EA);
  static const textoSecundario = Color(0xFF9CA3AF);
  static const textoAyuda = Color(0xFF6B7C93);
  static const borde = Color(0x599CA3AF);
}

abstract final class TemaAplicacion {
  static final oscuro = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: ColoresAplicacion.fondo,
    colorScheme: const ColorScheme.dark(
      primary: ColoresAplicacion.principal,
      onPrimary: ColoresAplicacion.fondo,
      secondary: ColoresAplicacion.principal,
      onSecondary: ColoresAplicacion.fondo,
      secondaryContainer: Color(0x2EC8A2B7),
      onSecondaryContainer: ColoresAplicacion.texto,
      surface: ColoresAplicacion.superficie,
      onSurface: ColoresAplicacion.texto,
    ),
    chipTheme: const ChipThemeData(showCheckmark: false),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColoresAplicacion.superficie,
      hintStyle: const TextStyle(
        color: ColoresAplicacion.textoAyuda,
        fontSize: 16,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: ColoresAplicacion.borde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: ColoresAplicacion.principal),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ColoresAplicacion.principal,
        foregroundColor: ColoresAplicacion.fondo,
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: const Size(double.infinity, 49),
      ),
    ),
  );
}

class DesplazamientoRevela extends MaterialScrollBehavior {
  const DesplazamientoRevela();
  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
  };
}
