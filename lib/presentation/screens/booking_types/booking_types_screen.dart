import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/booking_type_model.dart';
import '../../../data/repositories/booking_repository.dart';

final _typesProvider = FutureProvider.autoDispose<List<BookingTypeModel>>((ref) {
  return BookingRepository().getBookingTypes();
});

final _repo = BookingRepository();

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
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'edit') _showForm(context, type: t);
                                if (v == 'delete') _confirmDelete(context, t);
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
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
                Text(type == null ? 'New Booking Type' : 'Edit Booking Type',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  title: const Text('Has Schedule'),
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
