import 'package:flutter/material.dart';
import '../theme/neo_brutal_theme.dart';

/// Avatar circular com iniciais — não depende de foto de perfil (o app
/// ainda não tem upload de imagem), então a identidade visual do usuário é
/// sempre 1 ou 2 letras do nome sobre um bloco sólido.
class NeoAvatar extends StatelessWidget {
  const NeoAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.color,
    this.onTap,
  });

  final String name;
  final double size;
  final Color? color;
  final VoidCallback? onTap;

  /// Duas iniciais (primeiro nome + último sobrenome) quando o nome tem mais
  /// de uma palavra — mais fácil de reconhecer entre várias pessoas do que
  /// uma letra só, sem virar poluição visual. Cai para 1 letra com nome
  /// de uma palavra só.
  static String initialsOf(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final avatar = Container(
      width: size,
      height: size,
      decoration: NeoBrutal.decoration(
        color: color ?? scheme.primary,
        borderColor: scheme.ink,
        radius: 999,
        offset: NeoBrutal.shadowOffsetSmall,
      ),
      alignment: Alignment.center,
      child: Text(
        initialsOf(name),
        style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w900,
            color: Colors.white),
      ),
    );

    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }
}
