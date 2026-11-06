import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../application/uv_alert_coordinator.dart';
import '../../core/design/app_logo.dart';
import '../../data/repositories/measurement_repository.dart';
import '../alerts/alerts_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../history/history_screen.dart';
import '../station/station_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.repository,
    required this.isConfigured,
    this.notifications,
  });
  final MeasurementRepository repository;
  final bool isConfigured;
  final UvAlertCoordinator? notifications;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  var _index = 0;
  final _stackKey = GlobalKey();
  late final List<Widget?> _screens;
  List<(String, IconData)> get _items => [
    (kIsWeb ? 'Dashboard' : 'Inicio', Icons.space_dashboard_outlined),
    ('Historial', Icons.timeline_rounded),
    ('Alertas', Icons.notifications_none_rounded),
    ('Estación', Icons.sensors_rounded),
  ];
  @override
  void initState() {
    super.initState();
    _screens = List.filled(_items.length, null);
    _screens[0] = _screen(0);
  }

  Widget _screen(int index) {
    final label = _items[index].$1;
    return switch (label) {
      'Inicio' || 'Dashboard' => DashboardScreen(
        repository: widget.repository,
        isConfigured: widget.isConfigured,
      ),
      'Historial' => HistoryScreen(
        repository: widget.repository,
        isConfigured: widget.isConfigured,
      ),
      'Alertas' => AlertsScreen(
        repository: widget.repository,
        isConfigured: widget.isConfigured,
        notifications: widget.notifications,
      ),
      _ => StationScreen(
        repository: widget.repository,
        isConfigured: widget.isConfigured,
      ),
    };
  }

  void _select(int index) => setState(() {
    _screens[index] ??= _screen(index);
    _index = index;
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // GlobalKey conserva controladores, filtros y scroll al mover el contenido
      // entre navegación inferior/lateral durante un cambio de tamaño.
      final content = IndexedStack(
        key: _stackKey,
        index: _index,
        children: [
          for (final screen in _screens) screen ?? const SizedBox.shrink(),
        ],
      );
      if (constraints.maxWidth < 700 || constraints.maxHeight < 420) {
        return Scaffold(
          body: SafeArea(child: content),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _select,
            labelBehavior: kIsWeb && constraints.maxWidth < 400
                ? NavigationDestinationLabelBehavior.onlyShowSelected
                : NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              for (final item in _items)
                NavigationDestination(icon: Icon(item.$2), label: item.$1),
            ],
          ),
        );
      }
      final wide = constraints.maxWidth >= (kIsWeb ? 800 : 1100);
      return Scaffold(
        body: Row(
          children: [
            if (wide)
              _WideNavigation(
                items: _items,
                selectedIndex: _index,
                onSelected: _select,
              )
            else
              SafeArea(
                child: NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: AppLogo(size: 40),
                  ),
                  destinations: [
                    for (final item in _items)
                      NavigationRailDestination(
                        icon: Icon(item.$2),
                        label: Text(item.$1),
                      ),
                  ],
                ),
              ),
            const VerticalDivider(width: 1),
            Expanded(
              child: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1440),
                          child: content,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _WideNavigation extends StatelessWidget {
  const _WideNavigation({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });
  final List<(String, IconData)> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: ColoredBox(
      color: const Color(0xff141e32),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 22),
          children: [
            const Row(
              children: [
                AppLogo(size: 44),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Solar Safe',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: .8,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6, bottom: 28),
              child: Text(
                'Smart Station',
                style: TextStyle(color: Color(0xffbecfe1), fontSize: 13),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 12, bottom: 16),
              child: Text(
                'MONITOREO AMBIENTAL',
                style: TextStyle(
                  color: Color(0xffbecfe1),
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ),
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: selectedIndex == i
                      ? const Color(0xff4b4edb)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    selected: selectedIndex == i,
                    selectedColor: Colors.white,
                    iconColor: const Color(0xffbecfe1),
                    textColor: const Color(0xffbecfe1),
                    leading: Icon(items[i].$2, size: 22),
                    title: Text(
                      items[i].$1,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => onSelected(i),
                  ),
                ),
              ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.wb_sunny_outlined, color: Color(0xfffabd00)),
                  SizedBox(height: 12),
                  Text(
                    'Disfruta el sol.\nCuida tu piel.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Información para tomar mejores decisiones al aire libre.',
                    style: TextStyle(
                      color: Color(0xffbecfe1),
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
