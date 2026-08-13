import 'package:flutter/material.dart';

import '../../../../core/theme/neo_brutal_theme.dart';
import '../../../../core/ui/neo_auth_backdrop.dart';
import 'vaijunto_logo.dart';

/// Estrutura compartilhada das telas de acesso.
///
/// Mantém marca, navegação, contexto e formulário dentro da primeira viewport,
/// enquanto o mapa vivo ocupa os vazios ao redor sem adicionar decisões.
class AuthVisualShell extends StatelessWidget {
  const AuthVisualShell({
    super.key,
    required this.code,
    required this.title,
    required this.description,
    required this.content,
    this.stepLabel,
    this.showBack = false,
    this.onBack,
    this.afterContent,
    this.fixedAction,
  });

  final String code;
  final String title;
  final String description;
  final String? stepLabel;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget content;
  final Widget? afterContent;
  final Widget? fixedAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const NeoAuthBackdrop(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AuthBrandRail(
                              showBack: showBack,
                              onBack: onBack,
                            ),
                            const SizedBox(height: 22),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    code,
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      color: scheme.tertiary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                if (stepLabel != null)
                                  Text(
                                    stepLabel!,
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      color: scheme.primary,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Text(
                              title.toUpperCase(),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontSize: 28,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 20),
                            content,
                            if (afterContent != null) ...[
                              const SizedBox(height: 20),
                              afterContent!,
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (fixedAction != null)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      border: Border(
                        top: BorderSide(
                          color: scheme.ink,
                          width: NeoBrutal.borderWidth,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 11, 20, 14),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: fixedAction!,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBrandRail extends StatelessWidget {
  const _AuthBrandRail({required this.showBack, this.onBack});

  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          children: [
            const VaiJuntoLogo(size: 44, showWordmark: false),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VAIJUNTO',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    'MOBILIDADE UNIVERSITÁRIA',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
            if (showBack)
              Semantics(
                button: true,
                label: 'Voltar',
                child: GestureDetector(
                  onTap: onBack ?? () => Navigator.of(context).maybePop(),
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      border: Border.all(color: scheme.ink, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_back_rounded, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'VOLTAR',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border.all(color: scheme.ink, width: 2),
                ),
                child: Text(
                  'FATEC // SJC',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.tertiary,
                    fontSize: 8,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(height: 3, color: scheme.ink),
            Container(width: 72, height: 3, color: scheme.primary),
            Positioned(
              left: 78,
              child: Container(width: 24, height: 3, color: scheme.tertiary),
            ),
          ],
        ),
      ],
    );
  }
}
