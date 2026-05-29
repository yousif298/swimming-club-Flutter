import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/pool_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/booking_type_model.dart';
import '../../../data/models/mirror_model.dart';
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
  List<BookingTypeModel> _bookingTypes = [];
  bool _typesLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(poolListProvider.notifier).load());
    _loadBookingTypes();
  }

  Future<void> _loadBookingTypes() async {
    try {
      final types = await BookingRepository().getBookingTypes();
      if (mounted) setState(() { _bookingTypes = types; _typesLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _typesLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final poolsAsync = ref.watch(poolListProvider);
    final mirrorState = ref.watch(mirrorProvider);

    return Scaffold(
      body: Column(
        children: [
          _buildControls(context, poolsAsync, mirrorState),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final mirrorState2 = ref.read(mirrorProvider);
                if (_selectedPool != null) await ref.read(mirrorProvider.notifier).load(_selectedPool!.id, _selectedDate, bookingTypeId: mirrorState2.selectedBookingTypeId);
              },
              child: mirrorState.data.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading mirror view: $e')),
                data: (mirror) {
                  if (mirror == null) return const Center(child: Text('Select a pool to view'));
                  return _buildMirrorGrid(context, mirror);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, AsyncValue<List<PoolModel>> poolsAsync, MirrorState mirrorState) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              poolsAsync.when(
                data: (pools) => DropdownButton<PoolModel>(
                  value: _selectedPool,
                  hint: const Text('Select Pool'),
                  items: pools.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                  onChanged: (pool) {
                    setState(() => _selectedPool = pool);
                    if (pool != null) ref.read(mirrorProvider.notifier).load(pool.id, _selectedDate, bookingTypeId: mirrorState.selectedBookingTypeId);
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
                  if (_selectedPool != null) ref.read(mirrorProvider.notifier).load(_selectedPool!.id, _selectedDate, bookingTypeId: mirrorState.selectedBookingTypeId);
                },
              ),
              Text(DateFormat('EEEE, MMM d').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
                  if (_selectedPool != null) ref.read(mirrorProvider.notifier).load(_selectedPool!.id, _selectedDate, bookingTypeId: mirrorState.selectedBookingTypeId);
                },
              ),
              const Spacer(),
              if (_selectedDate != DateTime.now())
                TextButton(
                  onPressed: () {
                    setState(() => _selectedDate = DateTime.now());
                    if (_selectedPool != null) ref.read(mirrorProvider.notifier).load(_selectedPool!.id, _selectedDate, bookingTypeId: mirrorState.selectedBookingTypeId);
                  },
                  child: const Text('Today'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('Category: ', style: TextStyle(fontSize: 12)),
              if (_typesLoading)
                const SizedBox(width: 80, child: LinearProgressIndicator())
              else
                DropdownButton<String?>(
                  value: mirrorState.selectedBookingTypeId,
                  hint: const Text('All (global)', style: TextStyle(fontSize: 12)),
                  isDense: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All (global)', style: TextStyle(fontSize: 12))),
                    ..._bookingTypes.map((t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(t.name, style: const TextStyle(fontSize: 12)),
                    )),
                  ],
                  onChanged: (id) => ref.read(mirrorProvider.notifier).setBookingTypeFilter(id),
                ),
              const Spacer(),
              Text(DateFormat('MMM d, yyyy').format(_selectedDate), style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
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
                  final bookingColor = ms?.color;
                  return DataCell(
                    GestureDetector(
                      onTap: () => _showSlotDetail(context, mirror.poolId, lane.id, slot.id),
                      child: Container(
                        width: 80,
                        height: 36,
                        decoration: BoxDecoration(
                          color: booked
                              ? (bookingColor != null && bookingColor.isNotEmpty
                                  ? Color(int.parse(bookingColor.replaceFirst('#', '0xFF')))
                                  : AppTheme.primaryGreen.withOpacity(0.2))
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
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
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
    final mirrorState = ref.read(mirrorProvider);
    final mirror = mirrorState.data.valueOrNull;
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
                      onPressed: () { Navigator.pop(ctx); _editBooking(context, ms.bookingId!); },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Cancel Booking'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () { Navigator.pop(ctx); _cancelBooking(context, ms.bookingId!); },
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
          height: MediaQuery.of(context).size.height * 0.9,
          child: QuickBookingSheet(
            poolId: poolId,
            laneId: laneId,
            slotId: slotId,
            date: _selectedDate,
            timeSlots: mirror?.timeSlots,
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
        final mirrorState = ref.read(mirrorProvider);
        if (_selectedPool != null) ref.read(mirrorProvider.notifier).load(_selectedPool!.id, _selectedDate, bookingTypeId: mirrorState.selectedBookingTypeId);
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
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
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
                    if (price == null) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Enter a valid price'))); return; }
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
      final mirrorState = ref.read(mirrorProvider);
      ref.read(mirrorProvider.notifier).load(_selectedPool!.id, _selectedDate, bookingTypeId: mirrorState.selectedBookingTypeId);
    }
  }
}

class QuickBookingSheet extends ConsumerStatefulWidget {
  final String poolId, laneId, slotId;
  final DateTime date;
  final List<TimeSlotMirror>? timeSlots;

  const QuickBookingSheet({
    super.key,
    required this.poolId,
    required this.laneId,
    required this.slotId,
    required this.date,
    this.timeSlots,
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
  List<TimeSlotMirror> _timeSlots = [];
  final Set<String> _selectedSlotIds = {};
  final Set<String> _lockedSlotIds = {};

  final List<Map<String, dynamic>> _members = [];
  final Set<int> _lockedDays = {};
  bool _showSchedule = false;
  int _durationMonths = 1;
  int _daysPerMonth = 4;
  final List<Map<String, dynamic>> _scheduleDays = [];

  final List<String> _selectedLaneIds = [];
  final List<Map<String, dynamic>> _allLanes = [];

  final _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  List<TimeSlotMirror> get _displayTimeSlots {
    if (_selectedType != null && _selectedType!.hasSchedule) {
      var targetDay = widget.date.weekday;
      if (targetDay == 7) targetDay = 0;
      return _timeSlots.where((ts) => ts.dayOfWeek == null || ts.dayOfWeek == targetDay).toList();
    }
    return _timeSlots;
  }

  @override
  void initState() {
    super.initState();
    _selectedLaneIds.add(widget.laneId);
    _initLanes();
    _searchCustomers();
    _loadTypes();
    _loadTimeSlots();
  }

  void _initLanes() {
    final mirror = ref.read(mirrorProvider).data.valueOrNull;
    if (mirror != null) {
      for (final lane in mirror.lanes) {
        _allLanes.add({'id': lane.id, 'number': lane.number});
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _priceCtrl.dispose();
    _titleCtrl.dispose();
    _coachCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTimeSlots() async {
    if (widget.timeSlots != null) {
      _timeSlots = widget.timeSlots!;
    } else {
      final mirror = ref.read(mirrorProvider).data.valueOrNull;
      if (mirror != null) _timeSlots = mirror.timeSlots;
    }
    if (widget.slotId.isNotEmpty && _timeSlots.any((ts) => ts.id == widget.slotId)) {
      _selectedSlotIds.add(widget.slotId);
      _lockedSlotIds.add(widget.slotId);
      _updatePrice();
    }
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

  void _onTypeChanged(BookingTypeModel? type) {
    setState(() {
      _selectedType = type;
      if (type != null) {
        _updatePrice();
        _showSchedule = type.hasSchedule;
        if (type.hasCapacity && type.capacity != null) {
          _members.clear();
          for (int i = 0; i < type.capacity!; i++) {
            _members.add({'fullName': '', 'age': null, 'phone': null});
          }
        } else {
          _members.clear();
        }
        if (type.hasSchedule) {
          final dayIndex = widget.date.weekday - 1;
          if (!_scheduleDays.any((d) => d['dayOfWeek'] == dayIndex)) {
            _scheduleDays.add({'dayOfWeek': dayIndex});
            _lockedDays.add(dayIndex);
          }
        } else {
          _scheduleDays.clear();
          _lockedDays.clear();
          _durationMonths = 1;
          _daysPerMonth = 4;
        }
      } else {
        _showSchedule = false;
        _members.clear();
        _scheduleDays.clear();
        _lockedDays.clear();
      }
    });
  }

  void _updatePrice() {
    if (_selectedType == null) return;
    final hours = _selectedSlotIds.length;
    final lanes = _selectedLaneIds.length;
    final rate = _selectedType!.defaultPrice;
    final total = (hours > 0 ? rate * hours : rate) * lanes;
    _priceCtrl.text = total.toStringAsFixed(0);
  }

  void _toggleSlot(String slotId) {
    if (_lockedSlotIds.contains(slotId)) return;
    setState(() {
      if (_selectedSlotIds.contains(slotId)) {
        _selectedSlotIds.remove(slotId);
      } else {
        _selectedSlotIds.add(slotId);
      }
      _updatePrice();
    });
  }

  void _toggleLane(String laneId) {
    setState(() {
      if (_selectedLaneIds.contains(laneId)) {
        if (_selectedLaneIds.length > 1) {
          _selectedLaneIds.remove(laneId);
        }
      } else {
        _selectedLaneIds.add(laneId);
      }
      _updatePrice();
    });
  }

  void _toggleDay(int dayIndex) {
    if (_lockedDays.contains(dayIndex)) return;
    setState(() {
      final existing = _scheduleDays.indexWhere((d) => d['dayOfWeek'] == dayIndex);
      if (existing >= 0) {
        _scheduleDays.removeAt(existing);
      } else {
        _scheduleDays.add({'dayOfWeek': dayIndex});
      }
    });
  }

  void _updateMember(int index, String field, String value) {
    setState(() => _members[index][field] = value);
  }

  Future<void> _createBooking() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a customer'))); return;
    }
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a booking type'))); return;
    }
    if (_selectedSlotIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one time slot'))); return;
    }
    final price = double.tryParse(_priceCtrl.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid price'))); return;
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

      final additionalLanes = _selectedLaneIds
          .where((id) => id != widget.laneId)
          .map((id) => {'laneId': id})
          .toList();

      await _bookingRepo.create(
        customerId: _selectedCustomer!.id,
        laneId: widget.laneId,
        slotIds: _selectedSlotIds.toList(),
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
            ? _scheduleDays.map((d) => {'dayOfWeek': d['dayOfWeek']}).toList()
            : null,
        additionalLanes: additionalLanes.isNotEmpty ? additionalLanes : null,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking created successfully'), backgroundColor: Colors.green),
        );
        final mirrorState = ref.read(mirrorProvider);
        final pools = ref.read(poolListProvider).valueOrNull;
        final poolId = pools?.firstOrNull?.id ?? widget.poolId;
        ref.read(mirrorProvider.notifier).load(poolId, widget.date, bookingTypeId: mirrorState.selectedBookingTypeId);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
                              onPressed: () { setState(() { _selectedCustomer = null; _searchCtrl.clear(); }); _searchCustomers(); },
                            )
                          : null,
                    ),
                    onChanged: (v) => _searchCustomers(v),
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
                          onTap: () { setState(() { _selectedCustomer = c; _searchCtrl.text = c.fullName; _customers = []; }); },
                        )).toList(),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (_typesLoading) const LinearProgressIndicator()
                  else DropdownButtonFormField<BookingTypeModel>(
                    decoration: const InputDecoration(labelText: 'Booking Type'),
                    items: _types.map((t) => DropdownMenuItem(value: t, child: Text('${t.name} (\$${t.defaultPrice.toStringAsFixed(0)}/hr)'))).toList(),
                    onChanged: _onTypeChanged,
                  ),
                  const SizedBox(height: 8),
                  if (_allLanes.isNotEmpty && _allLanes.length > 1) ...[
                    const Text('Select Lanes:', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: _allLanes.map((lane) {
                        final laneId = lane['id'] as String;
                        final isSelected = _selectedLaneIds.contains(laneId);
                        return FilterChip(
                          label: Text('Lane ${lane['number']}', style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
                          selected: isSelected,
                          onSelected: (_) => _toggleLane(laneId),
                          selectedColor: AppTheme.primaryGreen,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Text('Selected: ${_selectedLaneIds.length} lane(s)', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 8),
                  ],
                  if (_displayTimeSlots.isNotEmpty) ...[
                    const Text('Select Time Slots:', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: _displayTimeSlots.map((ts) {
                        final isLocked = _lockedSlotIds.contains(ts.id);
                        return FilterChip(
                          label: Row(mainAxisSize: MainAxisSize.min, children: [
                            if (isLocked) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.lock, size: 12, color: Colors.white70)),
                            Text(ts.display, style: const TextStyle(fontSize: 12)),
                          ]),
                          selected: _selectedSlotIds.contains(ts.id) || isLocked,
                          onSelected: isLocked ? null : (_) => _toggleSlot(ts.id),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Text('${_selectedSlotIds.length} hr(s) selected × ${_selectedLaneIds.length} lane(s)${_selectedType != null && _selectedType!.hasSchedule ? ' (${_dayNames[(widget.date.weekday == 7 ? 6 : widget.date.weekday - 1)]})' : ''}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 8),
                  ],
                  TextField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(labelText: 'Total Price (\$)', prefixIcon: Icon(Icons.attach_money), hintText: 'rate × hours × lanes'),
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
                    const SizedBox(height: 12), const Divider(),
                    Text('Members (${_members.where((m) => (m['fullName'] as String).isNotEmpty).length}/${_selectedType!.capacity})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 8),
                    ..._members.asMap().entries.map((entry) {
                      final i = entry.key;
                      return Card(child: Padding(padding: const EdgeInsets.all(8), child: Column(children: [
                        TextField(decoration: InputDecoration(labelText: 'Member ${i + 1} Name', isDense: true), onChanged: (v) => _updateMember(i, 'fullName', v)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Age', isDense: true), keyboardType: TextInputType.number, onChanged: (v) => _updateMember(i, 'age', v))),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Phone', isDense: true), onChanged: (v) => _updateMember(i, 'phone', v))),
                        ]),
                      ])));
                    }),
                  ],
                  if (_showSchedule) ...[
                    const SizedBox(height: 12), const Divider(),
                    Text('Schedule', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Duration (months)', isDense: true), keyboardType: TextInputType.number, initialValue: '$_durationMonths', onChanged: (v) => setState(() => _durationMonths = int.tryParse(v) ?? 1))),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Days/month', isDense: true), keyboardType: TextInputType.number, initialValue: '$_daysPerMonth', onChanged: (v) => setState(() => _daysPerMonth = int.tryParse(v) ?? 4))),
                    ]),
                    const SizedBox(height: 8),
                    TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title (optional)', isDense: true)),
                    const SizedBox(height: 8),
                    TextField(controller: _coachCtrl, decoration: const InputDecoration(labelText: 'Coach Name (optional)', isDense: true)),
                    const SizedBox(height: 8),
                    const Text('Select Days:', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: List.generate(7, (i) {
                        final isLocked = _lockedDays.contains(i);
                        return FilterChip(
                          label: Row(mainAxisSize: MainAxisSize.min, children: [
                            if (isLocked) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.lock, size: 12, color: Colors.white70)),
                            Text(_dayNames[i], style: const TextStyle(fontSize: 12)),
                          ]),
                          selected: _scheduleDays.any((d) => d['dayOfWeek'] == i) || isLocked,
                          onSelected: isLocked ? null : (_) => _toggleDay(i),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }),
                    ),
                    if (_scheduleDays.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Selected: ${_scheduleDays.length} day(s)', style: const TextStyle(fontSize: 13, color: Colors.grey)),
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
