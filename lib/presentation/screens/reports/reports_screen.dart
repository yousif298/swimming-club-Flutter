import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/booking_list_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/report_repository.dart';
import '../../providers/pool_provider.dart';

final _repo = ReportRepository();

final customerSearchProvider = FutureProvider.autoDispose.family<List<CustomerModel>, String>((ref, query) {
  if (query.isEmpty) return [];
  return CustomerRepository().getAll(search: query, pageSize: 15);
});

final customerBookingsProvider = FutureProvider.autoDispose.family<List<BookingListModel>, String>((ref, id) {
  return _repo.getCustomerBookings(id);
});

final customerPaymentsProvider = FutureProvider.autoDispose.family<List<PaymentListModel>, String>((ref, id) {
  return _repo.getCustomerPayments(id);
});

final poolReportProvider = FutureProvider.autoDispose.family<PoolReportModel?, ({String poolId, DateTime? from, DateTime? to})>((ref, params) async {
  return _repo.getPoolReport(params.poolId, from: params.from, to: params.to);
});

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => ref.read(poolListProvider.notifier).load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reports', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Client Report'),
                Tab(text: 'Pool Report'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ClientReportTab(),
                  _PoolReportTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientReportTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ClientReportTab> createState() => _ClientReportTabState();
}

class _ClientReportTabState extends ConsumerState<_ClientReportTab> {
  final _searchCtrl = TextEditingController();
  CustomerModel? _selected;
  List<CustomerModel> _results = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search(String q) {
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    CustomerRepository().getAll(search: q, pageSize: 10).then((r) {
      if (mounted) setState(() => _results = r);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selected == null) {
      return Column(
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(labelText: 'Search Customer', prefixIcon: Icon(Icons.search)),
            onChanged: _search,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: _results.map((c) => ListTile(
                leading: CircleAvatar(child: Text(c.fullName[0])),
                title: Text(c.fullName),
                subtitle: Text('${c.phone} · Balance: \$${c.currentBalance.toStringAsFixed(0)}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => setState(() {
                  _selected = c;
                  _searchCtrl.text = c.fullName;
                  _results = [];
                }),
              )).toList(),
            ),
          ),
        ],
      );
    }

    final bookingsAsync = ref.watch(customerBookingsProvider(_selected!.id));
    final paymentsAsync = ref.watch(customerPaymentsProvider(_selected!.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selected!.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${_selected!.phone} · Balance: \$${_selected!.currentBalance.toStringAsFixed(0)}'),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _selected = null;
                _searchCtrl.clear();
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(),
        const Text('Bookings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        Expanded(
          flex: 3,
          child: bookingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (list) => list.isEmpty
                ? const Center(child: Text('No bookings'))
                : ListView(
                    children: list.map((b) => ListTile(
                      dense: true,
                      title: Text('Lane ${b.laneNumber} · ${b.slotTime}'),
                      subtitle: Text('${b.bookingType} · ${DateFormat('MMM d, yyyy').format(b.bookingDate)}'),
                      trailing: Text('\$${b.price.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: b.paymentStatus == 'Paid' ? AppTheme.primaryGreen : Colors.orange)),
                    )).toList(),
                  ),
          ),
        ),
        const Divider(),
        const Text('Payments', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        Expanded(
          flex: 2,
          child: paymentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (list) => list.isEmpty
                ? const Center(child: Text('No payments'))
                : ListView(
                    children: list.map((p) => ListTile(
                      dense: true,
                      title: Text('${p.paymentMethod} · \$${p.amount.toStringAsFixed(0)}'),
                      subtitle: Text(DateFormat('MMM d, h:mm a').format(p.createdAt)),
                      trailing: Chip(
                        label: Text(p.paymentStatus, style: const TextStyle(fontSize: 11, color: Colors.white)),
                        backgroundColor: p.paymentStatus == 'Paid' ? AppTheme.primaryGreen : Colors.orange,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                    )).toList(),
                  ),
          ),
        ),
      ],
    );
  }
}

class _PoolReportTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PoolReportTab> createState() => _PoolReportTabState();
}

class _PoolReportTabState extends ConsumerState<_PoolReportTab> {
  String? _selectedPoolId;
  DateTime? _from;
  DateTime? _to;

  @override
  Widget build(BuildContext context) {
    final poolsAsync = ref.watch(poolListProvider);
    final reportAsync = _selectedPoolId != null
        ? ref.watch(poolReportProvider((poolId: _selectedPoolId!, from: _from, to: _to)))
        : null;

    return poolsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (pools) {
        if (pools.isEmpty) return const Center(child: Text('No pools'));
        return Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Select Pool'),
              items: pools.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
              onChanged: (id) {
                setState(() => _selectedPoolId = id);
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final d = await showDatePicker(context: context, initialDate: _from ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (d != null) setState(() => _from = d);
                    },
                    child: Text(_from != null ? DateFormat('MMM d, yyyy').format(_from!) : 'From'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final d = await showDatePicker(context: context, initialDate: _to ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (d != null) setState(() => _to = d);
                    },
                    child: Text(_to != null ? DateFormat('MMM d, yyyy').format(_to!) : 'To'),
                  ),
                ),
              ],
            ),
            if (_selectedPoolId != null) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Generate Report'),
                onPressed: () => ref.invalidate(poolReportProvider),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: reportAsync?.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (report) {
                      if (report == null) return const Center(child: Text('Select pool and date range'));
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Text(report.poolName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _StatItem(label: 'Bookings', value: '${report.totalBookings}'),
                                        _StatItem(label: 'Revenue', value: '\$${report.totalRevenue.toStringAsFixed(0)}'),
                                        _StatItem(label: 'Credits', value: '\$${report.totalCredits.toStringAsFixed(0)}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('Bookings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            const SizedBox(height: 4),
                            if (report.bookings == null || report.bookings!.isEmpty)
                              const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No bookings in this period')))
                            else
                              ...report.bookings!.map((b) => ListTile(
                                    dense: true,
                                    title: Text('${b.customerName} · Lane ${b.laneNumber}'),
                                    subtitle: Text('${b.slotTime} · ${b.bookingType} · ${b.date}'),
                                    trailing: Text('\$${b.price.toStringAsFixed(0)}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: b.paymentStatus == 'Paid' ? AppTheme.primaryGreen : Colors.orange)),
                                  )),
                          ],
                        ),
                      );
                    },
                  ) ??
                  const Center(child: Text('Select a pool and date range')),
            ),
          ],
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }
}
