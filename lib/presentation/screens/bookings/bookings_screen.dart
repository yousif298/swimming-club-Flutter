import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../data/repositories/member_repository.dart';
import '../../../data/models/booking_list_model.dart';
import '../../../data/models/member_model.dart';

final bookingsProvider = FutureProvider.autoDispose<List<BookingListModel>>((ref) {
  return BookingRepository().getAll();
});

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Bookings', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(bookingsProvider),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: bookingsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (bookings) {
                  if (bookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.book_online, size: 64, color: AppTheme.primaryGreen.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text('No bookings yet', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Use the Mirror View to create bookings', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: bookings.length,
                    itemBuilder: (context, i) {
                      final b = bookings[i];
                      final isPaid = b.paymentStatus == 'Paid';
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: b.color != null && b.color!.isNotEmpty
                                ? Color(int.parse(b.color!.replaceFirst('#', '0xFF')))
                                : (isPaid ? AppTheme.primaryGreen.withOpacity(0.15) : Colors.orange.withOpacity(0.15)),
                            child: Text(b.customerName.isNotEmpty ? b.customerName[0] : '?', style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(b.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('Lane ${b.laneNumber} · ${b.slotTime} · ${b.bookingType}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('\$${b.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Chip(
                                    label: Text(isPaid ? 'Paid' : b.paymentStatus, style: const TextStyle(fontSize: 11, color: Colors.white)),
                                    backgroundColor: isPaid ? AppTheme.primaryGreen : Colors.orange,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'members') _addMembers(context, b.id, ref);
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 'members', child: ListTile(leading: Icon(Icons.person_add, size: 18), title: Text('Add Members', style: TextStyle(fontSize: 14)), dense: true, visualDensity: VisualDensity.compact)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addMembers(BuildContext context, String bookingId, WidgetRef ref) async {
    final members = await MemberRepository().getAll();
    if (!context.mounted) return;

    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) => _MemberPickerDialog(members: members),
    );

    if (selected != null && selected.isNotEmpty) {
      try {
        await BookingRepository().addMembers(
          bookingId,
          members.where((m) => selected.contains(m.id)).map((m) => {
            'memberId': m.id,
            'fullName': m.fullName,
            if (m.age != null) 'age': m.age,
            if (m.phone != null) 'phone': m.phone,
          }).toList(),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Members added to booking'), backgroundColor: Colors.green),
          );
          ref.invalidate(bookingsProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

class _MemberPickerDialog extends StatefulWidget {
  final List<MemberModel> members;
  const _MemberPickerDialog({required this.members});

  @override
  State<_MemberPickerDialog> createState() => _MemberPickerDialogState();
}

class _MemberPickerDialogState extends State<_MemberPickerDialog> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Members'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: widget.members.isEmpty
            ? const Center(child: Text('No members. Add members from the Members screen.'))
            : ListView(
                children: widget.members.map((m) => CheckboxListTile(
                  title: Text(m.fullName),
                  subtitle: Text('${m.age != null ? '${m.age} yrs · ' : ''}${m.phone ?? ''}'),
                  value: _selected.contains(m.id),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selected.add(m.id);
                      } else {
                        _selected.remove(m.id);
                      }
                    });
                  },
                )).toList(),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _selected.isEmpty ? null : () => Navigator.pop(context, _selected),
          child: Text('Add (${_selected.isEmpty ? '' : '${_selected.length}'})'),
        ),
      ],
    );
  }
}
