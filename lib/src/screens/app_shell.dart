import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../telemetor_ui/telemetor_ui.dart';
import '../data/dashboard_controller.dart';
import '../data/stream_stats.dart';
import '../network/telemetry_transport.dart';
import '../navigation/app_routes.dart';
import 'add_chart_dialog.dart';
import 'dashboard_screen.dart';
import 'settings_dialog.dart';

/// Default sidebar sections for the Telemetor application.
List<TDLSidebarSection> defaultSidebarSections() => const [
      TDLSidebarSection(
        label: 'Main',
        destinations: [
          TDLSidebarDestination(id: AppRoutes.dashboard, label: 'Dashboard'),
        ],
      ),
      TDLSidebarSection(
        label: 'Data',
        destinations: [
          TDLSidebarDestination(
              id: AppRoutes.channels, label: 'Channels', enabled: false),
          TDLSidebarDestination(
              id: AppRoutes.devices, label: 'Devices', enabled: false),
          TDLSidebarDestination(
              id: AppRoutes.logs, label: 'Logs', enabled: false),
          TDLSidebarDestination(
              id: AppRoutes.sessions, label: 'Sessions', enabled: false),
          TDLSidebarDestination(
              id: AppRoutes.replay, label: 'Replay', enabled: false),
        ],
      ),
      TDLSidebarSection(
        label: 'Config',
        destinations: [
          TDLSidebarDestination(
              id: AppRoutes.sources, label: 'Sources', enabled: false),
          TDLSidebarDestination(
              id: AppRoutes.parsers, label: 'Parsers', enabled: false),
          TDLSidebarDestination(id: AppRoutes.settings, label: 'Settings'),
        ],
      ),
      TDLSidebarSection(
        label: 'About',
        destinations: [
          TDLSidebarDestination(
              id: AppRoutes.docs, label: 'Docs', enabled: false),
          TDLSidebarDestination(
              id: AppRoutes.about, label: 'About', enabled: false),
        ],
      ),
    ];

/// Root mission-control shell wrapping all application routes.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.themeMode});

  final ValueNotifier<ThemeMode> themeMode;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String _route = AppRoutes.dashboard;

  @override
  Widget build(BuildContext context) {
    final transport = context.read<TelemetryTransport>();
    final stats = context.read<StreamStats>();
    final controller = context.watch<DashboardController>();

    return MissionControlLayout(
      sidebar: TDLSidebar(
        sections: defaultSidebarSections(),
        selectedId: _route,
        onSelected: (id) {
          if (id == AppRoutes.settings) {
            ConnectionSettingsDialog.show(context, transport);
            return;
          }
          setState(() => _route = id);
        },
        footer: StreamBuilder<TransportState>(
          stream: transport.states,
          initialData: transport.state,
          builder: (context, snapshot) {
            final state = snapshot.data ?? TransportState.disconnected;
            final connected = state == TransportState.connected;
            return TDLConnectionIndicator(
              connected: connected,
              label: _connectionLabel(state),
              subtitle: 'TCP + ACK',
              detail: '${transport.host}:${transport.port}',
            );
          },
        ),
      ),
      header: StreamBuilder<TransportState>(
        stream: transport.states,
        initialData: transport.state,
        builder: (context, snapshot) {
          final connected =
              (snapshot.data ?? TransportState.disconnected) ==
                  TransportState.connected;
          return ValueListenableBuilder<double>(
            valueListenable: stats.rowsPerSecond,
            builder: (context, rate, _) {
              final kbPerSec = rate * 24 / 1024;
              return TDLPageHeader(
                title: _pageTitle(_route),
                breadcrumb: _breadcrumb(_route),
                live: connected && rate > 0,
                metrics: [
                  HeaderMetric(
                    label: 'Rate',
                    value: '${rate.toStringAsFixed(1)} Hz',
                  ),
                  HeaderMetric(
                    label: 'Throughput',
                    value: '${kbPerSec.toStringAsFixed(1)} kb/s',
                  ),
                ],
                actions: [
                  if (_route == AppRoutes.dashboard) ...[
                    TDLHeaderIconButton(
                      icon: Icons.add_chart,
                      tooltip: 'Add chart',
                      onPressed: () =>
                          AddChartDialog.show(context, controller),
                    ),
                    _LayoutMenu(controller: controller),
                  ],
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: widget.themeMode,
                    builder: (context, mode, _) => TDLHeaderIconButton(
                      icon: mode == ThemeMode.dark
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      tooltip: 'Toggle theme',
                      onPressed: () => widget.themeMode.value =
                          mode == ThemeMode.dark
                              ? ThemeMode.light
                              : ThemeMode.dark,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      body: _buildBody(context),
      footer: StatusStrip(
        leading: ValueListenableBuilder<int>(
          valueListenable: stats.droppedFrames,
          builder: (context, dropped, _) => Text('DROPPED: $dropped'),
        ),
        trailing: const Text('BUILD 2.0.0  © 2024'),
        children: [
          ValueListenableBuilder<int>(
            valueListenable: stats.totalRows,
            builder: (context, total, _) => Text('ROWS: $total'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return switch (_route) {
      AppRoutes.dashboard => DashboardScreen(themeMode: widget.themeMode),
      _ => MissionControlBody(
          child: Center(
            child: TDLPanel(
              title: _pageTitle(_route),
              child: Text(
                'Coming in a future release.',
                style: context.tdlText.tableCell,
              ),
            ),
          ),
        ),
    };
  }

  static String _connectionLabel(TransportState state) => switch (state) {
        TransportState.connected => 'Connected',
        TransportState.connecting => 'Connecting',
        TransportState.handshaking => 'Handshaking',
        TransportState.reconnecting => 'Reconnecting',
        TransportState.disconnected => 'Disconnected',
      };

  static String _pageTitle(String route) => switch (route) {
        AppRoutes.dashboard => 'Dashboard',
        AppRoutes.channels => 'Channels',
        AppRoutes.devices => 'Devices',
        AppRoutes.logs => 'Logs',
        AppRoutes.sessions => 'Sessions',
        AppRoutes.replay => 'Replay',
        AppRoutes.sources => 'Sources',
        AppRoutes.parsers => 'Parsers',
        AppRoutes.settings => 'Settings',
        AppRoutes.docs => 'Docs',
        AppRoutes.about => 'About',
        _ => 'Telemetor',
      };

  static String _breadcrumb(String route) => switch (route) {
        AppRoutes.dashboard => 'Home / Overview',
        _ => 'Home / ${_pageTitle(route)}',
      };
}

class _LayoutMenu extends StatelessWidget {
  const _LayoutMenu({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DashboardLayout>(
      icon: Icon(Icons.dashboard_customize,
          size: 18, color: context.tdlColors.textSecondary),
      tooltip: 'Layout',
      initialValue: controller.layout,
      onSelected: controller.setLayout,
      itemBuilder: (context) => const [
        PopupMenuItem(
            value: DashboardLayout.single, child: Text('Single column')),
        PopupMenuItem(
            value: DashboardLayout.dual, child: Text('Two columns')),
        PopupMenuItem(value: DashboardLayout.grid, child: Text('Grid')),
      ],
    );
  }
}
