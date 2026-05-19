import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/pool_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../providers/mirror_provider.dart';
import '../../providers/pool_provider.dart';

class MirrorScreen extends ConsumerStatefulWidget {
  const MirrorScreen({super.key});

  @override
  ConsumerState<MirrorScreen> createState() => _MirrorScreenState();
}

class _MirrorScreenState extends ConsumerState<MirrorScreen> {
  PoolModel? _selectedPool;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(poolListProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final poolsAsync = ref.watch(poolListProvider);
    final mirrorAsync = ref.watch(mirrorProvider);

    return Scaffold(
      body: Column(
        children: [
          _buildControls(context, poolsAsync),
          const Divider(height: 1),
          Expanded(
            child: mirrorAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading mirror view: $e')),
              data: (mirror) {
                if (mirror == null) return const Center(child: Text('Select a pool to view'));
                return _buildMirrorGrid(context, mirror);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, AsyncValue<List<PoolModel>> poolsAsync) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          poolsAsync.when(
            data: (pools) => DropdownButton<PoolModel>(
              value: _selectedPool,
              hint: const Text('Select Pool'),
              items: pools.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
              onChanged: (pool) {
                setState(() => _selectedPool = pool);
                if (pool != null) ref.read(mirrorProvider.notifier).load(pool.id, _selectedDate);
              },
            ),
            loading: () => const SizedBox(width: 100, child: LinearProgressIndicator()),
            error: (_, __) => const Text('Error loading pools'),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
              if (_selectedPool != null) ref.read(mirrorProvider.notifier).load(_selectedPool!.id, _selectedDate);
            },
          ),
          Text(DateFormat('EEEE, MMM d').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.w600)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
              if (_selectedPool != null) ref.read(mirrorProvider.notifier).load(_selectedPool!.id, _selectedDate);
            },
          ),
          const Spacer(),
          if (_selectedDate != DateTime.now())
            TextButton(
              onPressed: () {
                setState(() => _selectedDate = DateTime.now());
                if (_selectedPool != null) ref.read(mirrorProvider.notifier).load(_selectedPool!.id, _selectedDate);
              },
              child: const Text('Today'),
            ),
        ],
      ),
    );
  }

  Widget _buildMirrorGrid(BuildContext context, mirror) {
    final slotMap = mirror.slotMap;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowHeight: 48,
          dataRowMinHeight: 44,
          dataRowMaxHeight: 48,
          columnSpacing: 4,
          columns: [
            const DataColumn(label: Text('Lane', style: TextStyle(fontWeight: FontWeight.bold))),
            ...mirror.timeSlots.map((slot) => DataColumn(
              label: Text(slot.display, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            )).toList(),
          ],
          rows: [
            ...mirror.lanes.map((lane) {
              return DataRow(cells: [
                DataCell(Container(
                  width: 60,
                  child: Text('L${lane.number}', style: const TextStyle(fontWeight: FontWeight.bold)),
                )),
                ...mirror.timeSlots.map((slot) {
                  final ms = slotMap['${lane.id}-${slot.id}'];
                  final booked = ms?.isBooked ?? false;
                  final customerName = ms?.customerName;
                  return DataCell(
                    GestureDetector(
                      onTap: () => _showSlotDetail(context, mirror.poolId, lane.id, slot.id),
                      child: Container(
                        width: 80,
                        height: 36,
                        decoration: BoxDecoration(
                          color: booked
                              ? AppTheme.primaryGreen.withOpacity(0.2)
                              : AppTheme.slotAvailable.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: booked
                                ? AppTheme.primaryGreen.withOpacity(0.5)
                                : AppTheme.slotAvailable.withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: booked
                              ? Text(
                                  customerName != null ? _initials(customerName) : '',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen),
                                )
                              : const Icon(Icons.add_circle_outline, color: AppTheme.slotAvailable, size: 18),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ]);
            }),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

  void _showSlotDetail(BuildContext context, String poolId, String laneId, String slotId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: QuickBookingSheet(
          poolId: poolId,
          laneId: laneId,
          slotId: slotId,
          date: _selectedDate,
        ),
      ),
    );
  }
}

class QuickBookingSheet extends ConsumerStatefulWidget {
  final String poolId, laneId, slotId;
  final DateTime date;

  const QuickBookingSheet({
    super.key,
    required this.poolId,
    required this.laneId,
    required this.slotId,
    required this.date,
  });

  @override
  ConsumerState<QuickBookingSheet> createState() => _QuickBookingSheetState();
}

class _QuickBookingSheetState extends ConsumerState<QuickBookingSheet> {
  final BookingRepository _bookingRepo = BookingRepository();
  final _searchCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  CustomerModel? _selectedCustomer;
  String _bookingType = 'LaneHire';
  String _paymentStatus = 'Paid';
  bool _loading = false;
  List<CustomerModel> _customers = [];

  @override
  void initState() {
    super.initState();
    _searchCustomers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchCustomers([String? query]) async {
    final repo = CustomerRepository();
    final customers = await repo.getAll(search: query, pageSize: 50);
    setState(() => _customers = customers);
  }

  void _onSearchChanged(String value) {
    _searchCustomers(value);
  }

  Future<void> _createBooking() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a customer')));
      return;
    }
    final price = double.tryParse(_priceCtrl.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid price')));
      return;
    }

    setState(() => _loading = true);
    try {
      await _bookingRepo.create(
        customerId: _selectedCustomer!.id,
        laneId: widget.laneId,
        slotId: widget.slotId,
        bookingDate: widget.date,
        bookingType: _bookingType,
        price: price,
        paymentStatus: _paymentStatus,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking created successfully'), backgroundColor: Colors.green),
        );
        ref.read(mirrorProvider.notifier).load(ref.read(poolListProvider).valueOrNull?.firstOrNull?.id ?? widget.poolId, widget.date);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Text('Quick Booking', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.info_outline, size: 18, color: AppTheme.primaryGreen),
                      const SizedBox(width: 8),
                      Text('Date: ${DateFormat('MMM d, yyyy').format(widget.date)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      labelText: 'Search Customer',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _selectedCustomer != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() { _selectedCustomer = null; _searchCtrl.clear(); });
                                _searchCustomers();
                              },
                            )
                          : null,
                    ),
                    onChanged: _onSearchChanged,
                  ),
                  if (_selectedCustomer != null)
                    ListTile(
                      leading: CircleAvatar(child: Text(_selectedCustomer!.fullName[0])),
                      title: Text(_selectedCustomer!.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${_selectedCustomer!.phone} · Balance: \$${_selectedCustomer!.currentBalance.toStringAsFixed(0)}'),
                    )
                  else
                    SizedBox(
                      height: 120,
                      child: ListView(
                        children: _customers.map((c) => ListTile(
                          dense: true,
                          leading: CircleAvatar(child: Text(c.fullName[0])),
                          title: Text(c.fullName),
                          subtitle: Text(c.phone),
                          onTap: () {
                            setState(() { _selectedCustomer = c; _searchCtrl.text = c.fullName; _customers = []; });
                          },
                        )).toList(),
                      ),
                    ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _bookingType,
                    decoration: const InputDecoration(labelText: 'Booking Type'),
                    items: const [
                      DropdownMenuItem(value: 'LaneHire', child: Text('Lane Hire')),
                      DropdownMenuItem(value: 'Lesson', child: Text('Swimming Lesson')),
                      DropdownMenuItem(value: 'Casual', child: Text('Casual Swim')),
                      DropdownMenuItem(value: 'School', child: Text('Swimming School')),
                    ],
                    onChanged: (v) => setState(() => _bookingType = v!),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(labelText: 'Price (\$)', prefixIcon: Icon(Icons.attach_money)),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _paymentStatus,
                    decoration: const InputDecoration(labelText: 'Payment'),
                    items: const [
                      DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                      DropdownMenuItem(value: 'Credit', child: Text('Credit (Add to balance)')),
                    ],
                    onChanged: (v) => setState(() => _paymentStatus = v!),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _createBooking,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create Booking'),
            ),
          ),
        ],
      ),
    );
  }
}
