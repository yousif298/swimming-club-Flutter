import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/pool_model.dart';
import '../../../data/models/booking_type_model.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/pool_repository.dart';
import '../../providers/pool_provider.dart';

List<String> _genSlots(String startTime, String endTime, int durationMinutes) {
  final slots = <String>[];
  final parts = startTime.split(':');
  var startHour = int.parse(parts[0]);
  var startMin = int.parse(parts[1]);
  final endParts = endTime.split(':');
  var endHour = int.parse(endParts[0]);
  var endMin = int.parse(endParts[1]);
  var currentMin = startHour * 60 + startMin;
  final endMinTotal = endHour * 60 + endMin;
  while (currentMin + durationMinutes <= endMinTotal) {
    final h = (currentMin ~/ 60).toString().padLeft(2, '0');
    final m = (currentMin % 60).toString().padLeft(2, '0');
    final eh = ((currentMin + durationMinutes) ~/ 60).toString().padLeft(2, '0');
    final em = ((currentMin + durationMinutes) % 60).toString().padLeft(2, '0');
    slots.add('$h:$m-$eh:$em');
    currentMin += durationMinutes;
  }
  return slots;
}

class ScheduleBookingScreen extends ConsumerStatefulWidget {
  const ScheduleBookingScreen({super.key});

  @override
  ConsumerState<ScheduleBookingScreen> createState() => _ScheduleBookingScreenState();
}

class _ScheduleBookingScreenState extends ConsumerState<ScheduleBookingScreen> {
  final _bookingRepo = BookingRepository();
  final _searchCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _coachCtrl = TextEditingController();

  final _dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  final List<Map<String, dynamic>> _dayConfigs = [];
  final List<String> _selectedLaneIds = [];
  final List<Map<String, dynamic>> _members = [];

  PoolModel? _selectedPool;
  List<LaneModel> _lanes = [];
  bool _lanesLoading = false;
  BookingTypeModel? _selectedType;
  CustomerModel? _selectedCustomer;
  List<CustomerModel> _customers = [];
  List<BookingTypeModel> _types = [];
  bool _typesLoading = true;
  String _paymentStatus = 'Paid';
  bool _loading = false;
  int _durationMonths = 1;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 7; i++) {
      _dayConfigs.add({'dayOfWeek': i, 'isActive': false, 'startTime': '08:00', 'endTime': '17:00', 'slotDurationMinutes': 60, 'enabledSlots': <String>[]});
    }
    _loadTypes();
    _searchCustomers();
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
      if (mounted) setState(() { _types = types.where((t) => t.hasSchedule).toList(); _typesLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _typesLoading = false);
    }
  }

  Future<void> _searchCustomers([String? query]) async {
    final repo = CustomerRepository();
    final customers = await repo.getAll(search: query, pageSize: 50);
    if (mounted) setState(() => _customers = customers);
  }

  Future<void> _loadLanes() async {
    if (_selectedPool == null) return;
    setState(() => _lanesLoading = true);
    try {
      final repo = PoolRepository();
      final lanes = await repo.getLanes(_selectedPool!.id);
      if (mounted) setState(() { _lanes = lanes; _lanesLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _lanesLoading = false);
    }
  }

  void _updateMember(int index, String field, String value) {
    setState(() => _members[index][field] = value);
  }

  void _updateDayConfig(int dayIdx, String field, dynamic value) {
    setState(() => _dayConfigs[dayIdx][field] = value);
  }

  void _toggleSlot(int dayIdx, String slotDisplay) {
    setState(() {
      final list = List<String>.from(_dayConfigs[dayIdx]['enabledSlots'] as List);
      if (list.contains(slotDisplay)) {
        list.remove(slotDisplay);
      } else {
        list.add(slotDisplay);
      }
      _dayConfigs[dayIdx]['enabledSlots'] = list;
    });
  }

  Future<void> _createBooking() async {
    if (_selectedPool == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a pool'))); return;
    }
    if (_selectedLaneIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one lane'))); return;
    }
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a customer'))); return;
    }
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a booking type'))); return;
    }

    final activeDays = _dayConfigs.where((d) => d['isActive'] == true && (d['enabledSlots'] as List).isNotEmpty).toList();
    if (activeDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please activate at least one day with slots'))); return;
    }

    final price = double.tryParse(_priceCtrl.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid price'))); return;
    }

    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final todayDOW = now.weekday;
      final dartDowMap = {1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 0};
      final todayDowInt = dartDowMap[todayDOW]!;

      final sortedActive = activeDays.map((d) => d['dayOfWeek'] as int).toList()..sort();
      var targetDay = sortedActive.firstWhere((d) => d >= todayDowInt, orElse: () => sortedActive.first);
      var diff = targetDay - todayDowInt;
      if (diff < 0) diff += 7;
      final bookingDate = now.add(Duration(days: diff));

      final activeDayConfig = _dayConfigs.firstWhere((d) => d['dayOfWeek'] == targetDay);
      final enabledDisplays = Set<String>.from(activeDayConfig['enabledSlots'] as List);

      final schedulePayload = _dayConfigs.map((d) => {
        'dayOfWeek': d['dayOfWeek'],
        'startTime': d['startTime'],
        'endTime': d['endTime'],
        'slotDurationMinutes': d['slotDurationMinutes'],
        'isActive': d['isActive'],
        'enabledSlots': d['enabledSlots'],
      }).toList();
      await _bookingRepo.updateCategorySchedules(_selectedType!.id, schedulePayload);

      final availResp = await _bookingRepo.getAvailableSlots(_selectedType!.id, bookingDate, targetDayOfWeek: targetDay);
      final slotsList = (availResp['slots'] as List).cast<Map<String, dynamic>>();
      final normEnabled = enabledDisplays.map((e) => e.replaceAll(' ', '')).toSet();
      final matchedIds = slotsList
          .where((s) => normEnabled.contains((s['display'] as String).replaceAll(' ', '')))
          .map((s) => s['id'] as String)
          .toList();

      if (matchedIds.isEmpty) {
        if (mounted) setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No matching time slots found for the selected schedule')));
        return;
      }

      final primaryLane = _selectedLaneIds.first;
      final additionalLanes = _selectedLaneIds.skip(1).map((id) => {'laneId': id}).toList();

      final membersList = _selectedType!.hasCapacity
          ? _members.where((m) => (m['fullName'] as String).isNotEmpty).map((m) => {
                'fullName': m['fullName'],
                if (m['age'] != null) 'age': int.tryParse(m['age'].toString()),
                if (m['phone'] != null && (m['phone'] as String).isNotEmpty) 'phone': m['phone'],
              }).toList()
          : null;

      final scheduleDays = activeDays.map((d) => {'dayOfWeek': d['dayOfWeek']}).toList();

      await _bookingRepo.create(
        customerId: _selectedCustomer!.id,
        laneId: primaryLane,
        slotIds: matchedIds,
        bookingDate: bookingDate,
        bookingTypeId: _selectedType!.id,
        price: price,
        paymentStatus: _paymentStatus,
        title: _titleCtrl.text.isNotEmpty ? _titleCtrl.text : null,
        coachName: _coachCtrl.text.isNotEmpty ? _coachCtrl.text : null,
        durationMonths: _durationMonths,
        daysPerMonth: activeDays.length,
        members: membersList,
        scheduleDays: scheduleDays,
        additionalLanes: additionalLanes.isNotEmpty ? additionalLanes : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recurring booking created'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
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
    final poolsAsync = ref.watch(poolListProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Schedule Booking', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    poolsAsync.when(
                      data: (pools) => DropdownButtonFormField<PoolModel>(
                        decoration: const InputDecoration(labelText: 'Pool'),
                        value: _selectedPool,
                        items: pools.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                        onChanged: (v) { setState(() => _selectedPool = v); _loadLanes(); },
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error loading pools'),
                    ),
                    const SizedBox(height: 12),

                    if (_lanesLoading)
                      const LinearProgressIndicator()
                    else if (_lanes.isNotEmpty) ...[
                      const Text('Select Lanes:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: _lanes.map((lane) {
                          final isSelected = _selectedLaneIds.contains(lane.id);
                          return FilterChip(
                            label: Text('Lane ${lane.laneNumber}', style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
                            selected: isSelected,
                            onSelected: (v) {
                              setState(() {
                                if (v) { _selectedLaneIds.add(lane.id); }
                                else if (_selectedLaneIds.length > 1) { _selectedLaneIds.remove(lane.id); }
                              });
                            },
                            selectedColor: AppTheme.primaryGreen,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

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
                        height: 100,
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
                    const SizedBox(height: 12),

                    if (_typesLoading) const LinearProgressIndicator()
                    else DropdownButtonFormField<BookingTypeModel>(
                      decoration: const InputDecoration(labelText: 'Booking Type (Schedule)'),
                      items: _types.map((t) => DropdownMenuItem(value: t, child: Text('${t.name} (\$${t.defaultPrice.toStringAsFixed(0)})'))).toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedType = v;
                          if (v != null && v.hasCapacity && v.capacity != null) {
                            _members.clear();
                            for (int i = 0; i < v.capacity!; i++) {
                              _members.add({'fullName': '', 'age': null, 'phone': null});
                            }
                          } else {
                            _members.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    const Text('Configure Schedule:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 8),
                    ...List.generate(7, (dayIdx) {
                      final config = _dayConfigs[dayIdx];
                      final isActive = config['isActive'] as bool;
                      final startTime = config['startTime'] as String;
                      final endTime = config['endTime'] as String;
                      final duration = config['slotDurationMinutes'] as int;
                      final allSlots = _genSlots(startTime, endTime, duration);
                      final enabledSlots = List<String>.from(config['enabledSlots'] as List);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(_dayNames[dayIdx], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const Spacer(),
                                Switch(
                                  value: isActive,
                                  onChanged: (v) {
                                    setState(() {
                                      _dayConfigs[dayIdx]['isActive'] = v;
                                      if (v && (_dayConfigs[dayIdx]['enabledSlots'] as List).isEmpty) {
                                        _dayConfigs[dayIdx]['enabledSlots'] = List<String>.from(allSlots);
                                      }
                                    });
                                  },
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ]),
                              if (isActive) ...[
                                Row(children: [
                                  Expanded(child: TextFormField(
                                    initialValue: startTime,
                                    decoration: const InputDecoration(labelText: 'Start', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                                    style: const TextStyle(fontSize: 12),
                                    onChanged: (v) { _dayConfigs[dayIdx]['startTime'] = v; },
                                  )),
                                  const SizedBox(width: 6),
                                  Expanded(child: TextFormField(
                                    initialValue: endTime,
                                    decoration: const InputDecoration(labelText: 'End', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                                    style: const TextStyle(fontSize: 12),
                                    onChanged: (v) { _dayConfigs[dayIdx]['endTime'] = v; },
                                  )),
                                  const SizedBox(width: 6),
                                  Expanded(child: TextFormField(
                                    initialValue: duration.toString(),
                                    decoration: const InputDecoration(labelText: 'Min', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                                    style: const TextStyle(fontSize: 12),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) { _dayConfigs[dayIdx]['slotDurationMinutes'] = int.tryParse(v) ?? 60; },
                                  )),
                                ]),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: allSlots.map((slot) {
                                    final isOn = enabledSlots.contains(slot);
                                    return FilterChip(
                                      label: Text(slot, style: TextStyle(fontSize: 10, color: isOn ? Colors.white : null)),
                                      selected: isOn,
                                      onSelected: (_) => _toggleSlot(dayIdx, slot),
                                      selectedColor: AppTheme.primaryGreen,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),

                    TextFormField(
                      initialValue: _durationMonths.toString(),
                      decoration: const InputDecoration(labelText: 'Duration (months)'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() => _durationMonths = int.tryParse(v) ?? 1),
                    ),
                    const SizedBox(height: 12),

                    TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title (optional)'), style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(controller: _coachCtrl, decoration: const InputDecoration(labelText: 'Coach Name (optional)'), style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 12),

                    if (_selectedType != null && _selectedType!.hasCapacity) ...[
                      const Divider(),
                      Text('Members (${_members.where((m) => (m['fullName'] as String).isNotEmpty).length}/${_selectedType!.capacity})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      ..._members.asMap().entries.map((entry) {
                        final i = entry.key;
                        return Card(child: Padding(padding: const EdgeInsets.all(8), child: Column(children: [
                          TextField(decoration: const InputDecoration(labelText: 'Name', isDense: true), onChanged: (v) => _updateMember(i, 'fullName', v)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Age', isDense: true), keyboardType: TextInputType.number, onChanged: (v) => _updateMember(i, 'age', v))),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Phone', isDense: true), onChanged: (v) => _updateMember(i, 'phone', v))),
                          ]),
                        ])));
                      }),
                      const SizedBox(height: 12),
                    ],

                    TextField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(labelText: 'Monthly Price (\$)', prefixIcon: Icon(Icons.attach_money)),
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
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _createBooking,
                        child: _loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Create Schedule Booking'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
