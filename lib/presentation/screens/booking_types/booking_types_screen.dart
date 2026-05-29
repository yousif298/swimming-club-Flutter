import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/booking_type_model.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../core/theme/app_theme.dart';

final _typesProvider = FutureProvider.autoDispose<List<BookingTypeModel>>((ref) {
  return BookingRepository().getBookingTypes();
});

final _repo = BookingRepository();

List<String> _generateSlotTimes(String startTime, String endTime, int durationMinutes) {
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

class BookingTypesScreen extends ConsumerStatefulWidget {
  const BookingTypesScreen({super.key});

  @override
  ConsumerState<BookingTypesScreen> createState() => _BookingTypesScreenState();
}

class _BookingTypesScreenState extends ConsumerState<BookingTypesScreen> {
  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(_typesProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Booking Types', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Type'),
                  onPressed: () => _showForm(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: typesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (types) => types.isEmpty
                    ? const Center(child: Text('No booking types'))
                    : ListView(
                        children: types.map((t) => Card(
                          child: ListTile(
                            title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '\$${t.defaultPrice.toStringAsFixed(0)}'
                              '${t.hasCapacity ? ' · Capacity: ${t.capacity}' : ''}'
                              '${t.hasSchedule ? ' · Schedule' : ''}'
                              '${!t.isActive ? ' · Inactive' : ''}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (t.hasSchedule)
                                  IconButton(
                                    icon: const Icon(Icons.schedule, size: 20),
                                    tooltip: 'Configure Schedule',
                                    onPressed: () => _showScheduleConfig(context, t),
                                  ),
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _showForm(context, type: t);
                                    if (v == 'delete') _confirmDelete(context, t);
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )).toList(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showScheduleConfig(BuildContext context, BookingTypeModel type) async {
    List<Map<String, dynamic>> schedules = [];
    bool loading = true;

    try {
      schedules = await _repo.getCategorySchedules(type.id);
      loading = false;
    } catch (_) {
      loading = false;
    }

    final dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('Schedule: ${type.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Configure daily schedule - slots are auto-generated', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 16),
                if (loading)
                  const Center(child: CircularProgressIndicator())
                else
                  ...List.generate(7, (dayIdx) {
                    final existingIdx = schedules.indexWhere((s) => s['dayOfWeek'] == dayIdx);
                    final hasSchedule = existingIdx >= 0;
                    final startTime = hasSchedule ? schedules[existingIdx]['startTime'] as String : '08:00';
                    final endTime = hasSchedule ? schedules[existingIdx]['endTime'] as String : '17:00';
                    final duration = hasSchedule ? schedules[existingIdx]['slotDurationMinutes'] as int : 60;
                    final isActive = hasSchedule ? schedules[existingIdx]['isActive'] as bool : false;
                    List<String> enabledSlots;
                    if (hasSchedule && schedules[existingIdx]['enabledSlots'] != null) {
                      enabledSlots = List<String>.from(schedules[existingIdx]['enabledSlots'] as List);
                    } else {
                      enabledSlots = _generateSlotTimes(startTime, endTime, duration);
                    }
                    final allSlots = _generateSlotTimes(startTime, endTime, duration);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(dayNames[dayIdx], style: const TextStyle(fontWeight: FontWeight.w600)),
                                const Spacer(),
                                Switch(
                                  value: hasSchedule && isActive,
                                  onChanged: (v) {
                                    setSheetState(() {
                                      if (existingIdx >= 0) {
                                        schedules[existingIdx]['isActive'] = v;
                                      } else {
                                        schedules.add({
                                          'dayOfWeek': dayIdx,
                                          'startTime': '08:00',
                                          'endTime': '17:00',
                                          'slotDurationMinutes': 60,
                                          'isActive': v,
                                        });
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            if (hasSchedule && isActive) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: startTime,
                                      decoration: const InputDecoration(labelText: 'Start', isDense: true),
                                      onChanged: (v) {
                                        final idx = schedules.indexWhere((s) => s['dayOfWeek'] == dayIdx);
                                        if (idx >= 0) schedules[idx]['startTime'] = v;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: endTime,
                                      decoration: const InputDecoration(labelText: 'End', isDense: true),
                                      onChanged: (v) {
                                        final idx = schedules.indexWhere((s) => s['dayOfWeek'] == dayIdx);
                                        if (idx >= 0) schedules[idx]['endTime'] = v;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: duration.toString(),
                                      decoration: const InputDecoration(labelText: 'Min/slot', isDense: true),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) {
                                        final idx = schedules.indexWhere((s) => s['dayOfWeek'] == dayIdx);
                                        if (idx >= 0) schedules[idx]['slotDurationMinutes'] = int.tryParse(v) ?? 60;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: allSlots.map((slot) {
                                  final isOn = enabledSlots.contains(slot);
                                  return FilterChip(
                                    label: Text(slot, style: TextStyle(fontSize: 11, color: isOn ? Colors.white : null)),
                                    selected: isOn,
                                    onSelected: (v) {
                                      final idx = schedules.indexWhere((s) => s['dayOfWeek'] == dayIdx);
                                      if (idx < 0) return;
                                      setSheetState(() {
                                        final list = List<String>.from(schedules[idx]['enabledSlots'] as List? ?? allSlots);
                                        if (v) {
                                          if (!list.contains(slot)) list.add(slot);
                                        } else {
                                          list.remove(slot);
                                        }
                                        schedules[idx]['enabledSlots'] = list;
                                      });
                                    },
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      setSheetState(() => saving = true);
                      try {
                        final days = schedules.map((s) => {
                          'dayOfWeek': s['dayOfWeek'],
                          'startTime': s['startTime'],
                          'endTime': s['endTime'],
                          'slotDurationMinutes': s['slotDurationMinutes'],
                          'isActive': s['isActive'],
                          if (s['enabledSlots'] != null) 'enabledSlots': s['enabledSlots'],
                        }).toList();
                        await _repo.updateCategorySchedules(type.id, days);
                        Navigator.pop(ctx, true);
                      } catch (e) {
                        setSheetState(() => saving = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      }
                    },
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Schedule'),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );

    if (result == true) ref.invalidate(_typesProvider);
  }

  Future<void> _showForm(BuildContext context, {BookingTypeModel? type}) async {
    final nameCtrl = TextEditingController(text: type?.name ?? '');
    final descCtrl = TextEditingController(text: type?.description ?? '');
    final priceCtrl = TextEditingController(text: type?.defaultPrice.toStringAsFixed(0) ?? '');
    final capCtrl = TextEditingController(text: type?.capacity?.toString() ?? '');
    bool hasCapacity = type?.hasCapacity ?? false;
    bool hasSchedule = type?.hasSchedule ?? false;
    bool isActive = type?.isActive ?? true;
    bool saving = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type == null ? 'New Booking Type' : 'Edit Booking Type', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)')),
                const SizedBox(height: 8),
                TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Default Price'), keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Has Capacity'),
                  value: hasCapacity,
                  onChanged: (v) => setSheetState(() => hasCapacity = v),
                  contentPadding: EdgeInsets.zero,
                ),
                if (hasCapacity)
                  TextField(controller: capCtrl, decoration: const InputDecoration(labelText: 'Capacity'), keyboardType: TextInputType.number),
                SwitchListTile(
                  title: const Text('Has Schedule (per-day config)'),
                  value: hasSchedule,
                  onChanged: (v) => setSheetState(() => hasSchedule = v),
                  contentPadding: EdgeInsets.zero,
                ),
                if (type != null)
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (v) => setSheetState(() => isActive = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      setSheetState(() => saving = true);
                      try {
                        if (type == null) {
                          await _repo.createBookingType(
                            name: nameCtrl.text,
                            description: descCtrl.text.isNotEmpty ? descCtrl.text : null,
                            defaultPrice: double.parse(priceCtrl.text),
                            hasCapacity: hasCapacity,
                            capacity: hasCapacity ? int.tryParse(capCtrl.text) : null,
                            hasSchedule: hasSchedule,
                          );
                        } else {
                          await _repo.updateBookingType(
                            type.id,
                            name: nameCtrl.text,
                            description: descCtrl.text.isNotEmpty ? descCtrl.text : null,
                            defaultPrice: double.parse(priceCtrl.text),
                            hasCapacity: hasCapacity,
                            capacity: hasCapacity ? int.tryParse(capCtrl.text) : null,
                            hasSchedule: hasSchedule,
                            isActive: isActive,
                          );
                        }
                        Navigator.pop(ctx, true);
                      } catch (e) {
                        setSheetState(() => saving = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      }
                    },
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(type == null ? 'Create' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );

    if (result == true) ref.invalidate(_typesProvider);
  }

  Future<void> _confirmDelete(BuildContext context, BookingTypeModel type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Booking Type'),
        content: Text('Delete "${type.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _repo.deleteBookingType(type.id);
        ref.invalidate(_typesProvider);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
