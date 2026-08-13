import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/campus.dart';
import '../../../../core/theme/neo_brutal_theme.dart';
import '../../../../core/ui/neo_button.dart';
import '../../../../core/ui/neo_card.dart';
import '../../../../core/ui/neo_loading_indicator.dart';
import '../../../../core/ui/neo_segmented_control.dart';
import '../../../demands/data/models/demand_model.dart';
import '../../../demands/presentation/providers/demand_provider.dart';
import '../../../offers/data/models/offer_model.dart';
import '../../../offers/presentation/providers/offer_provider.dart';

enum RideFeedMode { offers, demands }

class RidesScreen extends ConsumerStatefulWidget {
  const RidesScreen({
    super.key,
    required this.onCreateOffer,
    required this.onCreateDemand,
  });

  final VoidCallback onCreateOffer;
  final VoidCallback onCreateDemand;

  @override
  ConsumerState<RidesScreen> createState() => _RidesScreenState();
}

class _RidesScreenState extends ConsumerState<RidesScreen> {
  RideFeedMode _mode = RideFeedMode.offers;

  void _refresh() {
    if (_mode == RideFeedMode.offers) {
      ref.invalidate(nearbyOffersProvider(kFatecLocation));
    } else {
      ref.invalidate(nearbyDemandsProvider(kFatecLocation));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final offers = ref.watch(nearbyOffersProvider(kFatecLocation));
    final demands = ref.watch(nearbyDemandsProvider(kFatecLocation));
    final current = _mode == RideFeedMode.offers ? offers : demands;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ENCONTRE QUEM VAI JUNTO',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'REGIÃO DA FATEC • ATUALIZADO AGORA',
                            style: TextStyle(
                              color: scheme.tertiary,
                              fontFamily: 'IBMPlexMono',
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.75,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _HudIconButton(
                      icon: Icons.refresh_rounded,
                      label: 'Atualizar',
                      onTap: _refresh,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                NeoSegmentedControl(
                  selectedIndex: _mode.index,
                  onSelected: (index) =>
                      setState(() => _mode = RideFeedMode.values[index]),
                  segments: const [
                    NeoSegment(
                        label: 'Caronas disponíveis',
                        icon: Icons.directions_car_rounded),
                    NeoSegment(
                        label: 'Pedidos de carona', icon: Icons.hail_rounded),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 3, color: scheme.ink),
          Expanded(
            child: current.when(
              loading: () => const _FeedLoading(),
              error: (_, __) => _FeedError(onRetry: _refresh),
              data: (_) => _mode == RideFeedMode.offers
                  ? _OfferList(
                      offers: offers.valueOrNull ?? const [],
                      onCreate: widget.onCreateOffer,
                    )
                  : _DemandList(
                      demands: demands.valueOrNull ?? const [],
                      onCreate: widget.onCreateDemand,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferList extends StatelessWidget {
  const _OfferList({required this.offers, required this.onCreate});

  final List<OfferModel> offers;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return _EmptyFeed(
        icon: Icons.route_rounded,
        title: 'NENHUMA CARONA AGORA',
        description:
            'Se você vai de carro, publique sua rota e encontre companhia.',
        action: 'OFERECER CARONA',
        onAction: onCreate,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: offers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _OfferCard(offer: offers[index]),
    );
  }
}

class _DemandList extends StatelessWidget {
  const _DemandList({required this.demands, required this.onCreate});

  final List<DemandModel> demands;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    if (demands.isEmpty) {
      return _EmptyFeed(
        icon: Icons.hail_rounded,
        title: 'NENHUM PEDIDO AGORA',
        description:
            'Publique para motoristas da região saberem quando você precisa ir.',
        action: 'PEDIR CARONA',
        onAction: onCreate,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: demands.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _DemandCard(demand: demands[index]),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer});

  final OfferModel offer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showRideDetails(
        context,
        kind: offer.isFixed ? 'CARONA FIXA' : 'CARONA DISPONÍVEL',
        person: offer.driverName,
        origin: offer.originName,
        destination: offer.destinationName,
        schedule: _offerScheduleLabel(offer),
        extra: offer.price == 0
            ? '${offer.availableSeats} VAGAS • GRÁTIS'
            : '${offer.availableSeats} VAGAS • R\$ ${offer.price.toStringAsFixed(2).replaceAll('.', ',')}',
      ),
      child: NeoCard(
        color: scheme.surface,
        padding: const EdgeInsets.all(14),
        offset: NeoBrutal.shadowOffsetSmall,
        child: Column(
          children: [
            Row(
              children: [
                NeoBadge(
                  color: scheme.secondary,
                  child: Text(offer.isFixed ? 'FIXA' : 'CARONA'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    offer.driverName.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                Text(
                  _offerScheduleLabel(offer),
                  style: _hudStyle(scheme),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _RouteLine(
                origin: offer.originName, destination: offer.destinationName),
            const SizedBox(height: 14),
            Row(
              children: [
                _Metric(
                    icon: Icons.event_seat_rounded,
                    value: '${offer.availableSeats} vagas'),
                const SizedBox(width: 16),
                _Metric(
                  icon: Icons.payments_outlined,
                  value: offer.price == 0
                      ? 'Grátis'
                      : 'R\$ ${offer.price.toStringAsFixed(2).replaceAll('.', ',')}',
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_rounded, color: scheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DemandCard extends StatelessWidget {
  const _DemandCard({required this.demand});

  final DemandModel demand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showRideDetails(
        context,
        kind: 'PEDIDO DE CARONA',
        person: demand.passengerName,
        origin: demand.originName,
        destination: demand.destinationName,
        schedule: _dateLabel(demand.desiredTime),
        extra: 'AGUARDANDO MOTORISTA',
      ),
      child: NeoCard(
        color: scheme.surface,
        padding: const EdgeInsets.all(14),
        offset: NeoBrutal.shadowOffsetSmall,
        child: Column(
          children: [
            Row(
              children: [
                NeoBadge(color: scheme.secondary, child: const Text('PEDIDO')),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    demand.passengerName.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                Text(_dateLabel(demand.desiredTime), style: _hudStyle(scheme)),
              ],
            ),
            const SizedBox(height: 14),
            _RouteLine(
                origin: demand.originName, destination: demand.destinationName),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('VER DETALHES', style: _hudStyle(scheme)),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded,
                    size: 18, color: scheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({required this.origin, required this.destination});

  final String origin;
  final String destination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: scheme.primary,
                border: Border.all(color: scheme.ink, width: 2),
              ),
            ),
            Container(width: 2, height: 34, color: scheme.ink),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: scheme.tertiary,
                border: Border.all(color: scheme.ink, width: 2),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(origin,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 17),
              Text(destination,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 17, color: scheme.primary),
        const SizedBox(width: 5),
        Text(value.toUpperCase(), style: _hudStyle(scheme)),
      ],
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Align(
      alignment: const Alignment(0, -0.65),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeoCard(
              color: scheme.surface,
              rotation: -0.008,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        color: scheme.primary,
                        alignment: Alignment.center,
                        child: Icon(icon, size: 24, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SCAN FINALIZADO',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.tertiary,
                                fontSize: 9,
                              ),
                            ),
                            Text(
                              '0 ROTAS NESTE CANAL',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  NeoButton(
                    onPressed: onAction,
                    icon: Icon(icon),
                    trailing: const Icon(Icons.arrow_forward_rounded),
                    child: Text(action),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 7, height: 7, color: scheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  'ATUALIZAÇÃO AUTOMÁTICA ATIVA',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedLoading extends StatelessWidget {
  const _FeedLoading();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: NeoCard(
          color: scheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: const NeoLoadingIndicator(label: 'BUSCANDO ROTAS...'),
        ),
      ),
    );
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 42),
            const SizedBox(height: 12),
            const Text('NÃO FOI POSSÍVEL CARREGAR'),
            const SizedBox(height: 16),
            NeoOutlineButton(
                onPressed: onRetry, child: const Text('TENTAR NOVAMENTE')),
          ],
        ),
      ),
    );
  }
}

class _HudIconButton extends StatelessWidget {
  const _HudIconButton(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border.all(color: scheme.ink, width: NeoBrutal.borderWidth),
            borderRadius: BorderRadius.circular(NeoBrutal.borderRadius),
          ),
          child: Icon(icon, color: scheme.ink),
        ),
      ),
    );
  }
}

TextStyle _hudStyle(ColorScheme scheme) => TextStyle(
      color: scheme.ink,
      fontFamily: 'IBMPlexMono',
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
    );

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month • $hour:$minute';
}

String _offerScheduleLabel(OfferModel offer) {
  if (!offer.isFixed) return _dateLabel(offer.departureAt);
  final hour = offer.departureAt.hour.toString().padLeft(2, '0');
  final minute = offer.departureAt.minute.toString().padLeft(2, '0');
  return 'FIXA • $hour:$minute';
}

void _showRideDetails(
  BuildContext context, {
  required String kind,
  required String person,
  required String origin,
  required String destination,
  required String schedule,
  required String extra,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          child: NeoCard(
            color: scheme.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    NeoBadge(color: scheme.secondary, child: Text(kind)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(person.toUpperCase(), style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                _RouteLine(origin: origin, destination: destination),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: scheme.ink,
                  child: Text(
                    '$schedule  •  $extra',
                    style: TextStyle(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'O contato direto estará disponível quando o chat for liberado.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
