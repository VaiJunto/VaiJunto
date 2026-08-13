import 'package:flutter/material.dart';
import '../config/campus.dart';
import '../theme/neo_brutal_theme.dart';
import 'neo_button.dart';
import 'neo_card.dart';

/// Toda viagem no app tem a Fatec como origem OU destino — nunca as duas
/// pontas livres. Este enum decide qual lado fica fixo.
enum TripDirection { toFatec, fromFatec }

/// Alterna a direção da viagem e mostra o lado fixo (Fatec) por cima do
/// campo de endereço livre, que fica por conta de quem usa este widget.
class FatecDirectionSelector extends StatelessWidget {
  const FatecDirectionSelector({
    super.key,
    required this.direction,
    required this.onChanged,
  });

  final TripDirection direction;
  final ValueChanged<TripDirection> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.ink;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: NeoButton(
                height: 48,
                color: direction == TripDirection.toFatec ? theme.colorScheme.secondary : theme.colorScheme.surface,
                onPressed: () => onChanged(TripDirection.toFatec),
                icon: Icon(Icons.login_rounded, size: 18, color: ink),
                child: const Text('IR P/ FATEC'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NeoButton(
                height: 48,
                color: direction == TripDirection.fromFatec ? theme.colorScheme.secondary : theme.colorScheme.surface,
                onPressed: () => onChanged(TripDirection.fromFatec),
                icon: Icon(Icons.logout_rounded, size: 18, color: ink),
                child: const Text('SAIR DA FATEC'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        NeoCard(
          color: theme.colorScheme.surface,
          rotation: -0.015,
          child: Row(
            children: [
              Icon(Icons.school_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kFatecName,
                      style: TextStyle(color: ink, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      direction == TripDirection.toFatec ? 'DESTINO' : 'ORIGEM',
                      style: TextStyle(color: ink.withOpacity(0.7), fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
