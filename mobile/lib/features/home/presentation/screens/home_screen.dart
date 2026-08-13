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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.user});

  final UserModel user;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _destinations = [
    NeoBottomNavDestination(icon: Icons.route_rounded, label: 'Caronas'),
    NeoBottomNavDestination(icon: Icons.add_box_outlined, label: 'Criar'),
    NeoBottomNavDestination(icon: Icons.forum_outlined, label: 'Chat'),
    NeoBottomNavDestination(icon: Icons.tune_rounded, label: 'Ajustes'),
  ];

  static const _titles = ['CARONAS', 'CRIAR', 'CHAT', 'AJUSTES'];
  static const _codes = ['VJ//RIDES', 'VJ//CREATE', 'VJ//COMMS', 'VJ//SYSTEM'];

  int _currentIndex = 0;
  CreateRideMode _createMode = CreateRideMode.offer;

  void _openCreate(CreateRideMode mode) {
    setState(() {
      _createMode = mode;
      _currentIndex = 1;
    });
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
    final pages = [
      RidesScreen(
        onCreateOffer: () => _openCreate(CreateRideMode.offer),
        onCreateDemand: () => _openCreate(CreateRideMode.demand),
      ),
      CreateHubScreen(
        mode: _createMode,
        onModeChanged: (mode) => setState(() => _createMode = mode),
        onCreated: _handleCreated,
      ),
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
        destinations: _destinations,
        onSelected: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
