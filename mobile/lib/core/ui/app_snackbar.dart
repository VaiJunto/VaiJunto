import 'package:flutter/material.dart';
import '../theme/neo_brutal_theme.dart';

/// Snackbars padronizados do app: bloco sólido com borda grossa e sombra
/// dura, igual ao resto dos componentes — nada de cantos suaves ou
/// elevação Material aqui.
enum _SnackKind { success, error, info }

extension _SnackKindStyle on _SnackKind {
  IconData get icon => switch (this) {
        _SnackKind.success => Icons.check_circle_rounded,
        _SnackKind.error => Icons.error_rounded,
        _SnackKind.info => Icons.info_rounded,
      };

  Color background() => switch (this) {
        _SnackKind.success => NeoBrutal.lime,
        _SnackKind.error => const Color(0xFFFF3B3B),
        _SnackKind.info => NeoBrutal.cyan,
      };
}

class AppSnackbar {
  const AppSnackbar._();

  static void success(BuildContext context, String message) =>
      _show(context, message, _SnackKind.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, _SnackKind.error);

  static void info(BuildContext context, String message) =>
      _show(context, message, _SnackKind.info);

  static void _show(BuildContext context, String message, _SnackKind kind) {
    final ink = Theme.of(context).colorScheme.ink;

    ScaffoldMessenger.of(context)
      // Evita empilhar mensagens quando o usuário toca várias vezes.
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: NeoBrutal.decoration(
              color: kind.background(),
              borderColor: ink,
              offset: NeoBrutal.shadowOffsetSmall,
            ),
            child: Row(
              children: [
                Icon(kind.icon, color: ink, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          padding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(),
          duration: Duration(milliseconds: kind == _SnackKind.error ? 3000 : 2200),
          dismissDirection: DismissDirection.horizontal,
        ),
      );
  }
}
