import 'package:flutter/material.dart';

import '../../../../core/ui/neo_segmented_control.dart';
import '../../../demands/presentation/screens/create_demand_screen.dart';
import '../../../offers/presentation/screens/create_offer_screen.dart';

enum CreateRideMode { offer, demand }

class CreateHubScreen extends StatelessWidget {
  const CreateHubScreen({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.onCreated,
  });

  final CreateRideMode mode;
  final ValueChanged<CreateRideMode> onModeChanged;
  final VoidCallback onCreated;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: NeoSegmentedControl(
              selectedIndex: mode.index,
              onSelected: (index) =>
                  onModeChanged(CreateRideMode.values[index]),
              segments: const [
                NeoSegment(
                    label: 'Oferecer carona',
                    icon: Icons.directions_car_rounded),
                NeoSegment(label: 'Pedir carona', icon: Icons.hail_rounded),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: mode.index,
              children: [
                CreateOfferScreen(embedded: true, onCreated: onCreated),
                CreateDemandScreen(embedded: true, onCreated: onCreated),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
