import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/campus.dart';
import '../../../../core/platform/pwa_environment.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/neo_brutal_theme.dart';
import '../../../../core/ui/neo_avatar.dart';
import '../../../../core/ui/neo_bottom_nav_bar.dart';
import '../../../../core/ui/neo_card.dart';
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
import '../../../notifications/presentation/notification_destination_resolver.dart';
import '../../../tracking/data/services/stomp_client_service.dart';
import '../../../chat/presentation/providers/conversation_provider.dart';

enum _NotificationPrompt { hidden, installPwa, enable, denied }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.user});

  final UserModel user;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  static const _titles = ['CARONAS', 'MINHAS CARONAS', 'CHAT', 'AJUSTES'];
  static const _codes = [
    'VJ//RIDES',
    'VJ//MY_RIDES',
    'VJ//COMMS',
    'VJ//SYSTEM'
  ];

  int _currentIndex = 0;
  StreamSubscription<RealtimeEvent>? _eventSubscription;
  StreamSubscription<Map<String, dynamic>>? _pushSubscription;
  StreamSubscription<Map<String, dynamic>>? _foregroundPushSubscription;
  Timer? _fallbackTimer;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  _NotificationPrompt _notificationPrompt = _NotificationPrompt.hidden;

  static const _notificationPromptDismissedKey =
      'notification_prompt_dismissed_at';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_startLiveUpdates);
  }

  Future<void> _startLiveUpdates() async {
    final notifications = ref.read(notificationServiceProvider);
    await notifications.init();
    await _refreshNotificationPrompt();
    if (!mounted) return;
    _pushSubscription = notifications.openedMessages.listen((data) {
      if (mounted) NotificationDestinationResolver.navigate(context, ref, data);
    });
    _foregroundPushSubscription = notifications.foregroundMessages.listen((_) {
      if (mounted) _refreshAll();
    });
    final socket = ref.read(stompClientProvider);
    _eventSubscription = socket.events.listen((event) {
      if (!mounted) return;
      final conversationId = event.payload['conversationId']?.toString();
      if (conversationId != null) {
        ref.invalidate(conversationMessagesProvider(conversationId));
      }
      _refreshAll();
    });
    await socket.connect();
    _fallbackTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (_lifecycle == AppLifecycleState.resumed && !socket.isConnected) {
        _refreshAll();
        socket.connect();
      }
    });
    _refreshAll();
  }

  void _refreshAll() {
    ref.invalidate(myOffersProvider);
    ref.invalidate(myDemandsProvider);
    ref.invalidate(nearbyOffersProvider);
    ref.invalidate(nearbyDemandsProvider);
    ref.invalidate(conversationsProvider);
    ref.invalidate(notificationsProvider);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (state == AppLifecycleState.resumed) {
      _refreshAll();
      _refreshNotificationPrompt(ignoreCooldown: true);
      ref.read(stompClientProvider).connect();
    }
  }

  Future<void> _refreshNotificationPrompt({bool ignoreCooldown = false}) async {
    final storage = ref.read(secureStorageProvider);
    if (!ignoreCooldown) {
      final raw = await storage.readPrivate(_notificationPromptDismissedKey);
      final dismissedAt = raw == null ? null : DateTime.tryParse(raw);
      if (dismissedAt != null &&
          DateTime.now().isBefore(dismissedAt.add(const Duration(hours: 24)))) {
        return;
      }
    }

    final prompt = kIsWeb && isIosBrowser && !isRunningAsInstalledPwa
        ? _NotificationPrompt.installPwa
        : switch (
            await ref.read(notificationServiceProvider).permissionState()) {
            NotificationPermissionState.enabled ||
            NotificationPermissionState.unavailable =>
              _NotificationPrompt.hidden,
            NotificationPermissionState.notDetermined =>
              _NotificationPrompt.enable,
            NotificationPermissionState.denied => _NotificationPrompt.denied,
          };
    if (mounted) setState(() => _notificationPrompt = prompt);
  }

  Future<void> _dismissNotificationPrompt() async {
    await ref.read(secureStorageProvider).writePrivate(
        _notificationPromptDismissedKey, DateTime.now().toIso8601String());
    if (mounted) {
      setState(() => _notificationPrompt = _NotificationPrompt.hidden);
    }
  }

  Future<void> _handleNotificationPrompt() async {
    if (_notificationPrompt == _NotificationPrompt.enable) {
      final enabled =
          await ref.read(notificationServiceProvider).enablePushNotifications();
      await _refreshNotificationPrompt(ignoreCooldown: true);
      if (mounted && enabled) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notificações ativadas.')));
      }
      return;
    }

    final installing = _notificationPrompt == _NotificationPrompt.installPwa;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
            installing ? 'ADICIONE À TELA DE INÍCIO' : 'ATIVE NOS AJUSTES'),
        content: Text(installing
            ? 'No Safari, toque em Compartilhar e depois em “Adicionar à Tela de Início”. Abra o VaiJunto pelo novo ícone para ativar os avisos.'
            : 'Abra Ajustes > Notificações > VaiJunto no iPhone e permita os avisos.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ENTENDI')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eventSubscription?.cancel();
    _pushSubscription?.cancel();
    _foregroundPushSubscription?.cancel();
    _fallbackTimer?.cancel();
    super.dispose();
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
          if (_notificationPrompt != _NotificationPrompt.hidden)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: _buildNotificationPrompt(scheme),
            ),
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

  Widget _buildNotificationPrompt(ColorScheme scheme) {
    final installing = _notificationPrompt == _NotificationPrompt.installPwa;
    final denied = _notificationPrompt == _NotificationPrompt.denied;
    return NeoCard(
      color: scheme.secondaryContainer,
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      offset: NeoBrutal.shadowOffsetSmall,
      child: Row(
        children: [
          Icon(installing
              ? Icons.install_mobile_rounded
              : Icons.notifications_active_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  installing
                      ? 'INSTALE O VAIJUNTO'
                      : denied
                          ? 'NOTIFICAÇÕES BLOQUEADAS'
                          : 'NÃO PERCA NENHUM AVISO',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  installing
                      ? 'Adicione à Tela de Início para receber notificações.'
                      : denied
                          ? 'Libere as notificações nos Ajustes do iPhone.'
                          : 'Ative para receber pedidos e mensagens.',
                  style: const TextStyle(fontSize: 12),
                ),
                TextButton(
                  onPressed: _handleNotificationPrompt,
                  child: Text(installing
                      ? 'COMO INSTALAR'
                      : denied
                          ? 'COMO LIBERAR'
                          : 'ATIVAR'),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Lembrar depois',
            onPressed: _dismissNotificationPrompt,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
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
