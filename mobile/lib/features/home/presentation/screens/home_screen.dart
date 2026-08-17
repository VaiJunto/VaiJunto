import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/campus.dart';
import '../../../../core/theme/neo_brutal_theme.dart';
import '../../../../core/ui/neo_avatar.dart';
import '../../../../core/ui/neo_bottom_nav_bar.dart';
import '../../../../core/ui/neo_street_backdrop.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../create/presentation/screens/create_hub_screen.dart';
import '../../../demands/presentation/providers/demand_provider.dart';
import '../../../offers/presentation/providers/offer_provider.dart';
import '../../../rides/presentation/screens/rides_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../my_rides/presentation/screens/my_rides_screen.dart';
import '../../../offers/presentation/screens/create_offer_screen.dart';
import '../../../offers/data/models/offer_model.dart';
import '../../../demands/presentation/screens/create_demand_screen.dart';
import '../../../notifications/presentation/notification_center_screen.dart';
import '../../../notifications/data/services/notification_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.user});

  final UserModel user;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _titles = ['CARONAS', 'MINHAS CARONAS', 'CHAT', 'AJUSTES'];
  static const _codes = [
    'VJ//RIDES',
    'VJ//MY_RIDES',
    'VJ//COMMS',
    'VJ//SYSTEM'
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notificationServiceProvider).init());
  }

  void _openCreate(CreateRideMode mode, {OfferModel? offer}) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => mode == CreateRideMode.offer
            ? CreateOfferScreen(onCreated: _handleCreated, initialOffer: offer)
            : CreateDemandScreen(onCreated: _handleCreated)));
  }

  void _handleCreated() {
    ref.invalidate(nearbyOffersProvider(kFatecLocation));
    ref.invalidate(nearbyDemandsProvider(kFatecLocation));
    setState(() => _currentIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final upcomingCount = ref
            .watch(myOffersProvider)
            .valueOrNull
            ?.where((offer) => offer.departureAt.isAfter(DateTime.now()))
            .length ??
        0;
    final destinations = [
      const NeoBottomNavDestination(
          icon: Icons.route_rounded, label: 'Caronas'),
      NeoBottomNavDestination(
          icon: Icons.directions_car_filled_rounded,
          label: 'Minhas',
          badgeCount: upcomingCount),
      const NeoBottomNavDestination(icon: Icons.forum_outlined, label: 'Chat'),
      const NeoBottomNavDestination(icon: Icons.tune_rounded, label: 'Ajustes'),
    ];
    final pages = [
      RidesScreen(
        onCreateOffer: () => _openCreate(CreateRideMode.offer),
        onCreateDemand: () => _openCreate(CreateRideMode.demand),
      ),
      MyRidesScreen(
          onOfferAgain: (offer) =>
              _openCreate(CreateRideMode.offer, offer: offer)),
      const ChatScreen(),
      SettingsScreen(user: widget.user),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 62,
        titleSpacing: 14,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: NeoBrutal.decoration(
                color: scheme.secondary,
                borderColor: scheme.ink,
                radius: 3,
                offset: NeoBrutal.shadowOffsetSmall,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.alt_route_rounded,
                  size: 21, color: Colors.white),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titles[_currentIndex],
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      shadows: [
                        Shadow(
                            color: scheme.tertiary,
                            offset: const Offset(-1, 0)),
                        Shadow(
                            color: scheme.primary, offset: const Offset(1, 0)),
                      ],
                    ),
                  ),
                  Text(
                    _codes[_currentIndex],
                    style: TextStyle(
                      color: scheme.tertiary,
                      fontFamily: 'IBMPlexMono',
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notificações',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const NotificationCenterScreen())),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: NeoAvatar(
              name: widget.user.name,
              size: 38,
              onTap: () => setState(() => _currentIndex = 3),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const NeoStreetBackdrop(),
          IndexedStack(index: _currentIndex, children: pages),
        ],
      ),
      bottomNavigationBar: NeoBottomNavBar(
        currentIndex: _currentIndex,
        destinations: destinations,
        onSelected: (index) => setState(() => _currentIndex = index),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateMenu(context),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.directions_car_rounded),
                title: const Text('OFERECER CARONA'),
                onTap: () {
                  Navigator.pop(sheet);
                  _openCreate(CreateRideMode.offer);
                },
              ),
              ListTile(
                leading: const Icon(Icons.hail_rounded),
                title: const Text('PEDIR CARONA'),
                onTap: () {
                  Navigator.pop(sheet);
                  _openCreate(CreateRideMode.demand);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
