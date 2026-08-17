import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/neo_brutal_theme.dart';

/// Renderiza uma newsletter administrativa no formato embed: bloco com fundo
/// próprio, faixa de acento à esquerda, título, componentes empilhados e
/// rodapé opcional.
///
/// O mesmo widget serve ao preview do painel e à leitura no app — é o que
/// garante que o admin veja exatamente o que a pessoa vai receber. Por isso
/// ele não fala com a rede: recebe os componentes já resolvidos (mídia com
/// `url`) e só desenha.
class NewsletterEmbed extends StatelessWidget {
  const NewsletterEmbed({
    super.key,
    required this.title,
    required this.components,
    required this.settings,
    this.sentAt,
  });

  final String title;
  final List<Map<String, dynamic>> components;
  final Map<String, dynamic> settings;
  final DateTime? sentAt;

  /// Espaço entre componentes: "levemente maior que um parágrafo".
  static const double _gap = 22;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = _color(settings['backgroundColor'], Colors.white);
    final accent = _color(settings['accentColor'], scheme.secondary);
    final onBackground =
        ThemeData.estimateBrightnessForColor(background) == Brightness.dark
            ? Colors.white
            : NeoBrutal.inkLight;
    final footer = (settings['footer'] ?? '').toString().trim();
    final showDateTime = settings['showDateTime'] != false;

    return Container(
      decoration: NeoBrutal.decoration(
          color: background, borderColor: scheme.ink, offset: NeoBrutal.shadowOffsetSmall),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 8, color: accent),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title.toUpperCase(),
                      style: _font(settings).copyWith(
                          color: onBackground,
                          fontSize: 20,
                          height: 1.15,
                          fontWeight: FontWeight.w900)),
                  if (showDateTime && sentAt != null) ...[
                    const SizedBox(height: 4),
                    Text(_stamp(sentAt!),
                        style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: onBackground.withValues(alpha: .65))),
                  ],
                  const SizedBox(height: _gap),
                  for (final component in components) ...[
                    _Component(
                        component: component,
                        settings: settings,
                        accent: accent,
                        onBackground: onBackground),
                    const SizedBox(height: _gap),
                  ],
                  if (footer.isNotEmpty) ...[
                    Container(height: 2, color: onBackground.withValues(alpha: .18)),
                    const SizedBox(height: 10),
                    Text(footer,
                        style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: onBackground.withValues(alpha: .65))),
                  ],
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  static TextStyle _font(Map<String, dynamic> settings) =>
      switch ((settings['font'] ?? 'PLEX_SANS').toString()) {
        'PLEX_MONO' => const TextStyle(fontFamily: 'IBMPlexMono'),
        'SYSTEM' => const TextStyle(),
        _ => const TextStyle(fontFamily: 'IBMPlexSans'),
      };

  static Color _color(dynamic value, Color fallback) {
    final text = (value ?? '').toString().replaceFirst('#', '');
    if (text.length != 6) return fallback;
    final parsed = int.tryParse(text, radix: 16);
    return parsed == null ? fallback : Color(0xFF000000 | parsed);
  }

  static String _stamp(DateTime when) {
    String two(int value) => value.toString().padLeft(2, '0');
    final local = when.toLocal();
    return '${two(local.day)}/${two(local.month)}/${local.year} • ${two(local.hour)}:${two(local.minute)}';
  }
}

class _Component extends StatelessWidget {
  const _Component({
    required this.component,
    required this.settings,
    required this.accent,
    required this.onBackground,
  });

  final Map<String, dynamic> component;
  final Map<String, dynamic> settings;
  final Color accent;
  final Color onBackground;

  @override
  Widget build(BuildContext context) {
    final font = NewsletterEmbed._font(settings);
    final type = (component['type'] ?? '').toString().toUpperCase();
    final text = (component['text'] ?? '').toString();
    final url = (component['url'] ?? '').toString();

    return switch (type) {
      'HEADING' => Align(
          alignment: Alignment.centerLeft,
          child: Text(text,
              style: font.copyWith(
                  color: onBackground, fontSize: 16, fontWeight: FontWeight.w900))),
      'TEXT' => Align(
          alignment: Alignment.centerLeft,
          child: Text(text,
              style: font.copyWith(
                  color: onBackground, fontSize: 14, height: 1.45))),
      'DIVIDER' => Container(height: 3, color: accent),
      'IMAGE' => url.isEmpty
          ? _unavailable(context, 'Imagem indisponível')
          : ClipRRect(
              borderRadius: BorderRadius.circular(NeoBrutal.borderRadius),
              child: Image.network(url,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) =>
                      _unavailable(context, 'Imagem indisponível'))),
      'AUDIO' => _mediaTile(context, Icons.graphic_eq, 'ÁUDIO',
          component['caption']?.toString() ?? 'Tocar áudio', url),
      'VIDEO' => _mediaTile(context, Icons.play_circle_outline, 'VÍDEO',
          component['caption']?.toString() ?? 'Assistir vídeo', url),
      'BUTTON' => _button(context, component),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _button(BuildContext context, Map<String, dynamic> component) {
    final link = (component['link'] ?? '').toString();
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: link.isEmpty ? null : () => launchUrl(Uri.parse(link)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: NeoBrutal.decoration(
              color: accent,
              borderColor: Theme.of(context).colorScheme.ink,
              offset: NeoBrutal.shadowOffsetSmall),
          child: Text((component['label'] ?? '').toString().toUpperCase(),
              style: TextStyle(
                  color:
                      ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
                          ? Colors.white
                          : NeoBrutal.inkLight,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5)),
        ),
      ),
    );
  }

  /// Áudio e vídeo abrem no player do sistema. Player embutido exigiria
  /// controlar ciclo de vida de mídia dentro de uma lista que também roda no
  /// preview do painel — fica para quando houver necessidade real.
  Widget _mediaTile(BuildContext context, IconData icon, String code,
      String label, String url) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: url.isEmpty ? null : () => launchUrl(Uri.parse(url)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            border: Border.all(color: onBackground.withValues(alpha: .35), width: 2),
            borderRadius: BorderRadius.circular(NeoBrutal.borderRadius)),
        child: Row(children: [
          Icon(icon, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(code,
                  style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: onBackground.withValues(alpha: .6))),
              Text(label,
                  style: TextStyle(color: onBackground, fontWeight: FontWeight.w700)),
            ]),
          ),
          Icon(Icons.open_in_new, size: 16, color: scheme.ink.withValues(alpha: .5)),
        ]),
      ),
    );
  }

  Widget _unavailable(BuildContext context, String label) => Container(
      padding: const EdgeInsets.all(14),
      width: double.infinity,
      decoration: BoxDecoration(
          border: Border.all(color: onBackground.withValues(alpha: .3), width: 2),
          borderRadius: BorderRadius.circular(NeoBrutal.borderRadius)),
      child: Text(label,
          style: TextStyle(
              color: onBackground.withValues(alpha: .7), fontWeight: FontWeight.w700)));
}
