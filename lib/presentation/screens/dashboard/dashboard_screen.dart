import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dashboardProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return dashboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (dashboard) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildStatsGrid(context, dashboard),
            const SizedBox(height: 24),
            Text('Recent Bookings', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildRecentBookings(context, dashboard),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, dashboard) {
    final stats = [
      _StatCard('Today Bookings', dashboard.todayBookings.toString(), Icons.calendar_today, AppTheme.primaryGreen),
      _StatCard('Active Customers', dashboard.activeCustomers.toString(), Icons.people, AppTheme.secondaryBlue),
      _StatCard('Revenue Today', '\$${dashboard.todayRevenue.toStringAsFixed(0)}', Icons.trending_up, AppTheme.accentOrange),
      _StatCard('Occupied Lanes', dashboard.occupiedLanes.toString(), Icons.pool, Colors.purple),
      _StatCard('Total Credits', '\$${dashboard.totalCredits.toStringAsFixed(0)}', Icons.credit_card, Colors.red),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: stats.map((s) => SizedBox(
        width: 200,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(s.icon, color: s.color, size: 32),
                const SizedBox(height: 12),
                Text(s.value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(s.label, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildRecentBookings(BuildContext context, dashboard) {
    return Card(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Customer')),
          DataColumn(label: Text('Lane')),
          DataColumn(label: Text('Time')),
          DataColumn(label: Text('Price')),
          DataColumn(label: Text('Status')),
        ],
        rows: [
          ...dashboard.recentBookings.map((b) => DataRow(cells: [
            DataCell(Text(b.customerName)),
            DataCell(Text('Lane ${b.laneNumber}')),
            DataCell(Text(b.slotTime)),
            DataCell(Text('\$${b.price.toStringAsFixed(0)}')),
            DataCell(_statusChip(b.status)),
          ])),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'Paid': color = AppTheme.slotAvailable; break;
      case 'Credit': color = AppTheme.accentOrange; break;
      case 'Partial': color = Colors.blue; break;
      default: color = Colors.grey;
    }
    return Chip(label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12)), backgroundColor: color, padding: EdgeInsets.zero, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap);
  }
}

class _StatCard {
  final String label, value;
  final IconData icon;
  final Color color;
  _StatCard(this.label, this.value, this.icon, this.color);
}
