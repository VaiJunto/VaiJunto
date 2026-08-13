import 'package:flutter/material.dart';
import '../app_version.dart';
import 'neo_card.dart';

/// Selo de versão pro rodapé, no mesmo tratamento visual dos outros badges
/// do app — pequeno de propósito, é informação de diagnóstico, não deve
/// competir com os botões da tela.
class AppVersionLabel extends StatelessWidget {
  const AppVersionLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return NeoBadge(
      rotation: -0.03,
      child: Text('v$kAppVersion'),
    );
  }
}
