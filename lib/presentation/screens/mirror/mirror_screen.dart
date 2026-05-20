import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/pool_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/booking_type_model.dart';
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
    final mirror = ref.read(mirrorProvider).valueOrNull;
    final ms = mirror?.slotMap['$laneId-$slotId'];

    if (ms != null && ms.isBooked && ms.bookingId != null) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Booking Details', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(leading: const Icon(Icons.person), title: Text(ms.customerName ?? ''), subtitle: const Text('Customer')),
              ListTile(leading: const Icon(Icons.category), title: Text(ms.bookingType ?? ''), subtitle: const Text('Booking Type')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _editBooking(context, ms.bookingId!);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Cancel Booking'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _cancelBooking(context, ms.bookingId!);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
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

  Future<void> _cancelBooking(BuildContext context, String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await BookingRepository().cancel(bookingId);
        if (_selectedPool != null) ref.read(mirrorProvider.notifier).load(_selectedPool!.id, _selectedDate);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking cancelled'), backgroundColor: Colors.green));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _editBooking(BuildContext context, String bookingId) async {
    final priceCtrl = TextEditingController();
    String paymentStatus = 'Paid';
    bool saving = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Edit Booking', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: paymentStatus,
                decoration: const InputDecoration(labelText: 'Payment Status'),
                items: const [
                  DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                  DropdownMenuItem(value: 'Credit', child: Text('Credit')),
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                ],
                onChanged: (v) => setSheetState(() => paymentStatus = v!),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : () async {
                    final price = double.tryParse(priceCtrl.text);
                    if (price == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Enter a valid price')));
                      return;
                    }
                    setSheetState(() => saving = true);
                    try {
                      await BookingRepository().update(bookingId, price: price, paymentStatus: paymentStatus);
                      Navigator.pop(ctx, true);
                    } catch (e) {
                      setSheetState(() => saving = false);
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                    }
                  },
                  child: saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        );
      }),
    );

    if (result == true && _selectedPool != null) {
      ref.read(mirrorProvider.notifier).load(_selectedPool!.id, _selectedDate);
    }
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
  final _titleCtrl = TextEditingController();
  final _coachCtrl = TextEditingController();

  CustomerModel? _selectedCustomer;
  BookingTypeModel? _selectedType;
  String _paymentStatus = 'Paid';
  bool _loading = false;
  List<CustomerModel> _customers = [];
  List<BookingTypeModel> _types = [];
  bool _typesLoading = true;

  // Members
  final List<Map<String, dynamic>> _members = [];

  // Schedule
  bool _showSchedule = false;
  int _durationMonths = 1;
  int _daysPerMonth = 4;
  final List<Map<String, dynamic>> _scheduleDays = [];

  final _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _searchCustomers();
    _loadTypes();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _priceCtrl.dispose();
    _titleCtrl.dispose();
    _coachCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    try {
      final types = await _bookingRepo.getBookingTypes();
      if (mounted) setState(() { _types = types; _typesLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _typesLoading = false);
    }
  }

  Future<void> _searchCustomers([String? query]) async {
    final repo = CustomerRepository();
    final customers = await repo.getAll(search: query, pageSize: 50);
    setState(() => _customers = customers);
  }

  void _onSearchChanged(String value) {
    _searchCustomers(value);
  }

  void _onTypeChanged(BookingTypeModel? type) {
    setState(() {
      _selectedType = type;
      if (type != null) {
        _priceCtrl.text = type.defaultPrice.toStringAsFixed(0);
        _showSchedule = type.hasSchedule;
        if (type.hasCapacity && type.capacity != null) {
          _members.clear();
          for (int i = 0; i < type.capacity!; i++) {
            _members.add({'fullName': '', 'age': null, 'phone': null});
          }
        } else {
          _members.clear();
        }
        if (!type.hasSchedule) {
          _scheduleDays.clear();
          _durationMonths = 1;
          _daysPerMonth = 4;
        }
      } else {
        _showSchedule = false;
        _members.clear();
        _scheduleDays.clear();
      }
    });
  }

  void _toggleDay(int dayIndex) {
    setState(() {
      final existing = _scheduleDays.indexWhere((d) => d['dayOfWeek'] == dayIndex);
      if (existing >= 0) {
        _scheduleDays.removeAt(existing);
      } else {
        _scheduleDays.add({'dayOfWeek': dayIndex, 'startTime': '09:00', 'endTime': '10:00'});
      }
    });
  }

  void _updateScheduleTime(int index, String field, String value) {
    setState(() => _scheduleDays[index][field] = value);
  }

  void _updateMember(int index, String field, String value) {
    setState(() => _members[index][field] = value);
  }

  Future<void> _createBooking() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a customer')));
      return;
    }
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a booking type')));
      return;
    }
    final price = double.tryParse(_priceCtrl.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid price')));
      return;
    }

    setState(() => _loading = true);
    try {
      final membersList = _selectedType!.hasCapacity
          ? _members.where((m) => (m['fullName'] as String).isNotEmpty).map((m) => {
                'fullName': m['fullName'],
                if (m['age'] != null) 'age': int.tryParse(m['age'].toString()),
                if (m['phone'] != null && (m['phone'] as String).isNotEmpty) 'phone': m['phone'],
              }).toList()
          : null;

      await _bookingRepo.create(
        customerId: _selectedCustomer!.id,
        laneId: widget.laneId,
        slotId: widget.slotId,
        bookingDate: widget.date,
        bookingTypeId: _selectedType!.id,
        price: price,
        paymentStatus: _paymentStatus,
        title: _titleCtrl.text.isNotEmpty ? _titleCtrl.text : null,
        coachName: _coachCtrl.text.isNotEmpty ? _coachCtrl.text : null,
        durationMonths: _showSchedule ? _durationMonths : null,
        daysPerMonth: _showSchedule ? _daysPerMonth : null,
        members: membersList,
        scheduleDays: _showSchedule && _scheduleDays.isNotEmpty
            ? _scheduleDays.map((d) => {
                  'dayOfWeek': d['dayOfWeek'],
                  'startTime': d['startTime'],
                  'endTime': d['endTime'],
                }).toList()
            : null,
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
                  if (_typesLoading)
                    const LinearProgressIndicator()
                  else
                    DropdownButtonFormField<BookingTypeModel>(
                      decoration: const InputDecoration(labelText: 'Booking Type'),
                      items: _types.map((t) => DropdownMenuItem(value: t, child: Text('${t.name} (\$${t.defaultPrice.toStringAsFixed(0)})'))).toList(),
                      onChanged: _onTypeChanged,
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
                  if (_selectedType != null && _selectedType!.hasCapacity) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    Text('Members (${_members.where((m) => (m['fullName'] as String).isNotEmpty).length}/${_selectedType!.capacity})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 8),
                    ..._members.asMap().entries.map((entry) {
                      final i = entry.key;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              TextField(
                                decoration: InputDecoration(labelText: 'Member ${i + 1} Name', isDense: true),
                                onChanged: (v) => _updateMember(i, 'fullName', v),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      decoration: const InputDecoration(labelText: 'Age', isDense: true),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => _updateMember(i, 'age', v),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      decoration: const InputDecoration(labelText: 'Phone', isDense: true),
                                      onChanged: (v) => _updateMember(i, 'phone', v),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                  if (_showSchedule) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    Text('Schedule', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Duration (months)', isDense: true),
                          keyboardType: TextInputType.number,
                          initialValue: '$_durationMonths',
                          onChanged: (v) => setState(() => _durationMonths = int.tryParse(v) ?? 1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Days/month', isDense: true),
                          keyboardType: TextInputType.number,
                          initialValue: '$_daysPerMonth',
                          onChanged: (v) => setState(() => _daysPerMonth = int.tryParse(v) ?? 4),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title (optional)', isDense: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _coachCtrl,
                      decoration: const InputDecoration(labelText: 'Coach Name (optional)', isDense: true),
                    ),
                    const SizedBox(height: 8),
                    const Text('Select Days:', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: List.generate(7, (i) => FilterChip(
                        label: Text(_dayNames[i], style: const TextStyle(fontSize: 12)),
                        selected: _scheduleDays.any((d) => d['dayOfWeek'] == i),
                        onSelected: (_) => _toggleDay(i),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )),
                    ),
                    if (_scheduleDays.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Set Times:', style: TextStyle(fontWeight: FontWeight.w500)),
                      ..._scheduleDays.asMap().entries.map((entry) {
                        final i = entry.key;
                        final d = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              SizedBox(width: 60, child: Text(_dayNames[d['dayOfWeek'] as int], style: const TextStyle(fontSize: 13))),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(labelText: 'Start', isDense: true),
                                  initialValue: d['startTime'] as String,
                                  onChanged: (v) => _updateScheduleTime(i, 'startTime', v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(labelText: 'End', isDense: true),
                                  initialValue: d['endTime'] as String,
                                  onChanged: (v) => _updateScheduleTime(i, 'endTime', v),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
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
