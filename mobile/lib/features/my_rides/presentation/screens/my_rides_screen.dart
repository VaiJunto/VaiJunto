import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/neo_button.dart';
import '../../../../core/ui/neo_card.dart';
import '../../../../core/ui/neo_segmented_control.dart';
import '../../../demands/presentation/providers/demand_provider.dart';
import '../../../offers/presentation/providers/offer_provider.dart';
import '../../../offers/data/models/offer_model.dart';

class MyRidesScreen extends ConsumerStatefulWidget {
  const MyRidesScreen({super.key, required this.onOfferAgain});
  final ValueChanged<OfferModel?> onOfferAgain;

  @override
  ConsumerState<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends ConsumerState<MyRidesScreen> {
  var _history = false;

  @override
  Widget build(BuildContext context) {
    final offers = ref.watch(myOffersProvider);
    final demands = ref.watch(myDemandsProvider);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: NeoSegmentedControl(
          selectedIndex: _history ? 1 : 0,
          onSelected: (index) => setState(() => _history = index == 1),
          segments: const [
            NeoSegment(label: 'Próximas', icon: Icons.upcoming_rounded),
            NeoSegment(label: 'Histórico', icon: Icons.history_rounded),
          ],
        ),
      ),
      Expanded(
        child: offers.when(
          loading: () => const Center(child: Text('CARREGANDO CARONAS...')),
          error: (_, __) =>
              const Center(child: Text('NÃO FOI POSSÍVEL CARREGAR')),
          data: (offerList) => demands.when(
            loading: () => const Center(child: Text('CARREGANDO CARONAS...')),
            error: (_, __) =>
                const Center(child: Text('NÃO FOI POSSÍVEL CARREGAR')),
            data: (demandList) => _RideList(
              history: _history,
              onOfferAgain: widget.onOfferAgain,
              items: [
                ...offerList.map((o) => _RideItem(
                    driver: true,
                    offer: o,
                    time: o.departureAt,
                    title: '${o.originName} → ${o.destinationName}',
                    detail:
                        '${o.availableSeats} vagas • R\$ ${o.price.toStringAsFixed(2)}')),
                ...demandList.map((d) => _RideItem(
                    driver: false,
                    time: d.desiredTime,
                    title: '${d.originName} → ${d.destinationName}',
                    detail: 'Pedido publicado')),
              ],
            ),
          ),
        ),
      ),
    ]);
  }
}

class _RideList extends StatelessWidget {
  const _RideList(
      {required this.history, required this.items, required this.onOfferAgain});
  final bool history;
  final List<_RideItem> items;
  final ValueChanged<OfferModel?> onOfferAgain;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final filtered = items
        .where((item) =>
            history ? item.time.isBefore(now) : !item.time.isBefore(now))
        .toList()
      ..sort((a, b) =>
          history ? b.time.compareTo(a.time) : a.time.compareTo(b.time));
    if (filtered.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: NeoCard(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                    history ? 'SEM HISTÓRICO AINDA' : 'NENHUMA CARONA PRÓXIMA'),
                const SizedBox(height: 12),
                NeoButton(
                    onPressed: () => onOfferAgain(null),
                    child: const Text('OFERECER CARONA'))
              ]))));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final item = filtered[index];
        return NeoCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.driver ? 'VOCÊ DIRIGE' : 'VOCÊ VAI',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Text(item.title),
          const SizedBox(height: 6),
          Text('${_label(item.time)} • ${item.detail}'),
          if (item.driver && !history)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: NeoOutlineButton(
                    onPressed: () => onOfferAgain(item.offer),
                    child: const Text('OFERECER NOVAMENTE')))
        ]));
      },
    );
  }

  String _label(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')} • ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _RideItem {
  const _RideItem(
      {required this.driver,
      required this.time,
      required this.title,
      required this.detail,
      this.offer});
  final bool driver;
  final DateTime time;
  final String title, detail;
  final OfferModel? offer;
}
