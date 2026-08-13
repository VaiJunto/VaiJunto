import 'package:flutter/material.dart';

/// Paleta e constantes do estilo visual do app: neobrutalismo (bordas
/// grossas pretas, sombra dura deslocada, sem gradiente suave) com um
/// pouco de futurismo (cores neon, saturadas) e street art (leve rotação
/// tipo adesivo colado torto em alguns elementos).
///
/// Regra do estilo, pra manter consistência: NADA de `blurRadius` em
/// sombra (sombra é sempre sólida, só com offset) e NADA de borda fina —
/// [borderWidth] é o mínimo em qualquer contorno.
class NeoBrutal {
  const NeoBrutal._();

  // Cores "neon" — usadas em blocos sólidos, nunca como texto sobre fundo
  // claro (contraste ruim); sempre com [ink] ou [paper] por cima.
  static const Color yellow = Color(0xFFFFDE2D);
  static const Color pink = Color(0xFFFF3EA5);
  static const Color cyan = Color(0xFF00E5FF);
  static const Color lime = Color(0xFFB6FF3B);
  static const Color orange = Color(0xFFFF7A1A);
  static const Color violet = Color(0xFF8C6BFF);

  static const Color paperLight = Color(0xFFFBF6E9);
  static const Color paperDark = Color(0xFF15131C);
  static const Color surfaceDark = Color(0xFF201D29);

  static const Color inkLight = Color(0xFF111014);
  static const Color inkDark = Color(0xFFF4F0E6);

  static const double borderWidth = 3;
  static const double borderRadius = 10;
  static const Offset shadowOffset = Offset(5, 5);
  static const Offset shadowOffsetSmall = Offset(3, 3);

  /// Contorno + sombra dura padrão. [pressed] achata a sombra e desloca o
  /// bloco pro canto dela — usado pelo [NeoButton] pra simular "afundar".
  static BoxDecoration decoration({
    required Color color,
    required Color borderColor,
    Color? shadowColor,
    double radius = borderRadius,
    Offset offset = shadowOffset,
    bool pressed = false,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: pressed
          ? []
          : [
              BoxShadow(
                color: shadowColor ?? borderColor,
                offset: offset,
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
    );
  }
}

extension NeoBrutalColorScheme on ColorScheme {
  /// Cor de borda/sombra "tinta" do tema atual (preto no claro, quase
  /// branco no escuro) — os contornos duros precisam disso em vez de preto
  /// fixo pra não sumir no fundo escuro.
  Color get ink => brightness == Brightness.dark ? NeoBrutal.inkDark : NeoBrutal.inkLight;
}

ThemeData buildNeoBrutalTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final ink = isDark ? NeoBrutal.inkDark : NeoBrutal.inkLight;
  final paper = isDark ? NeoBrutal.paperDark : NeoBrutal.paperLight;
  final surface = isDark ? NeoBrutal.surfaceDark : Colors.white;

  // Só 2 cores de marca, cada uma com um papel fixo em todo o app — ver
  // DESIGN.md. primary = ação principal (todo CTA), secondary = seleção/
  // destaque (nunca um botão de ação). tertiary (ciano) fica reservado
  // pra feedback de sistema (ver AppSnackbar), não é decoração.
  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: NeoBrutal.pink,
    onPrimary: Colors.white,
    primaryContainer: NeoBrutal.pink,
    onPrimaryContainer: Colors.white,
    secondary: NeoBrutal.yellow,
    onSecondary: NeoBrutal.inkLight,
    secondaryContainer: NeoBrutal.yellow,
    onSecondaryContainer: NeoBrutal.inkLight,
    tertiary: NeoBrutal.cyan,
    onTertiary: NeoBrutal.inkLight,
    error: const Color(0xFFFF3B3B),
    onError: Colors.white,
    surface: surface,
    onSurface: ink,
    surfaceContainerHighest: isDark ? const Color(0xFF2A2733) : const Color(0xFFF0EAD6),
    onSurfaceVariant: isDark ? NeoBrutal.inkDark.withOpacity(0.75) : NeoBrutal.inkLight.withOpacity(0.7),
    outline: ink,
    inverseSurface: ink,
    onInverseSurface: paper,
  );

  final baseTextTheme = ThemeData(brightness: brightness).textTheme;
  final textTheme = baseTextTheme.copyWith(
    headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
    titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
    titleMedium: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
    bodySmall: baseTextTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
    labelMedium: baseTextTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.4),
  ).apply(bodyColor: ink, displayColor: ink);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: paper,
    textTheme: textTheme,
    dividerColor: ink,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: paper,
      foregroundColor: ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 22),
      shape: Border(bottom: BorderSide(color: ink, width: NeoBrutal.borderWidth)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      labelStyle: TextStyle(color: ink, fontWeight: FontWeight.w700),
      hintStyle: TextStyle(color: ink.withOpacity(0.45), fontWeight: FontWeight.w500),
      helperStyle: TextStyle(color: ink.withOpacity(0.7), fontWeight: FontWeight.w600),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NeoBrutal.borderRadius),
        borderSide: BorderSide(color: ink, width: NeoBrutal.borderWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NeoBrutal.borderRadius),
        borderSide: BorderSide(color: ink, width: NeoBrutal.borderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NeoBrutal.borderRadius),
        borderSide: BorderSide(color: NeoBrutal.pink, width: NeoBrutal.borderWidth),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NeoBrutal.borderRadius),
        borderSide: const BorderSide(color: Color(0xFFFF3B3B), width: NeoBrutal.borderWidth),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NeoBrutal.borderRadius),
        borderSide: const BorderSide(color: Color(0xFFFF3B3B), width: NeoBrutal.borderWidth),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? NeoBrutal.pink : surface,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? NeoBrutal.yellow : surface,
      ),
      trackOutlineColor: WidgetStateProperty.all(ink),
      trackOutlineWidth: WidgetStateProperty.all(NeoBrutal.borderWidth),
    ),
    snackBarTheme: const SnackBarThemeData(backgroundColor: Colors.transparent, elevation: 0),
  );
}
