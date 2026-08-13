import 'package:flutter/material.dart';

import '../../../../core/theme/neo_brutal_theme.dart';
import '../../../../core/ui/neo_card.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: NeoCard(
            color: scheme.surface,
            rotation: -0.012,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('VJ//COMMS_CHANNEL', style: _hudStyle(scheme)),
                    const SizedBox(width: 10),
                    Expanded(child: Divider(color: scheme.ink, thickness: 2)),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: NeoBrutal.decoration(
                        color: scheme.primary,
                        borderColor: scheme.ink,
                        radius: 3,
                        offset: NeoBrutal.shadowOffsetSmall,
                      ),
                      child: const Icon(Icons.forum_rounded,
                          size: 28, color: Colors.white),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CONVERSAS\nEM BREVE',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              height: 0.95,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          NeoBadge(
                            color: scheme.secondary,
                            child: const Text('CANAL OFFLINE'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'Combine ponto de encontro e detalhes da viagem sem sair do VaiJunto.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: scheme.ink,
                  child: Text(
                    'STATUS: EM DESENVOLVIMENTO',
                    style: TextStyle(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _hudStyle(ColorScheme scheme) => TextStyle(
      color: scheme.secondary,
      fontFamily: 'IBMPlexMono',
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
    );
