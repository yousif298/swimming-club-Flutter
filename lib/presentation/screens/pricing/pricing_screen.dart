import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/pricing_model.dart';
import '../../../data/repositories/pricing_repository.dart';

final _activitiesProvider = FutureProvider.autoDispose<List<ActivityModel>>((ref) {
  return PricingRepository().getActivities();
});

final _pricingProvider = FutureProvider.autoDispose.family<List<PricingModel>, String>((ref, activityId) {
  return PricingRepository().getPricing(activityId);
});

final _repo = PricingRepository();

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  String? _selectedActivityId;

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(_activitiesProvider);
    final pricingAsync = _selectedActivityId != null ? ref.watch(_pricingProvider(_selectedActivityId!)) : null;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service Pricing', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: activitiesAsync.when(
                    data: (activities) => DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Select Activity', isDense: true),
                      items: activities.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                      onChanged: (id) => setState(() => _selectedActivityId = id),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ),
                const SizedBox(width: 12),
                if (_selectedActivityId != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Pricing'),
                    onPressed: () => _showForm(context),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: pricingAsync?.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (pricings) => pricings.isEmpty
                        ? const Center(child: Text('No pricing configured'))
                        : ListView(
                            children: pricings.map((p) => Card(
                              child: ListTile(
                                title: Text('\$${p.price.toStringAsFixed(0)} · ${p.pricingType}'),
                                subtitle: Text(
                                  p.minParticipants != null || p.maxParticipants != null
                                      ? 'Participants: ${p.minParticipants ?? 0}-${p.maxParticipants ?? '∞'}'
                                      : 'No participant limits',
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _showForm(context, pricing: p);
                                    if (v == 'delete') _confirmDelete(context, p);
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              ),
                            )).toList(),
                          ),
                  ) ??
                  const Center(child: Text('Select an activity')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showForm(BuildContext context, {PricingModel? pricing}) async {
    final priceCtrl = TextEditingController(text: pricing?.price.toStringAsFixed(0) ?? '');
    String pricingType = pricing?.pricingType ?? 'PerSession';
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
                Text(pricing == null ? 'Add Pricing' : 'Edit Pricing',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: pricingType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'PerSession', child: Text('Per Session')),
                    DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'Package', child: Text('Package')),
                  ],
                  onChanged: (v) => setSheetState(() => pricingType = v!),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      setSheetState(() => saving = true);
                      try {
                        final price = double.parse(priceCtrl.text);
                        if (pricing == null) {
                          await _repo.create(
                            activityId: _selectedActivityId!,
                            price: price,
                            pricingType: pricingType,
                          );
                        } else {
                          await _repo.update(pricing.id, price: price, pricingType: pricingType);
                        }
                        Navigator.pop(ctx, true);
                      } catch (e) {
                        setSheetState(() => saving = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      }
                    },
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(pricing == null ? 'Add' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );

    if (result == true && _selectedActivityId != null) ref.invalidate(_pricingProvider(_selectedActivityId!));
  }

  Future<void> _confirmDelete(BuildContext context, PricingModel pricing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Pricing'),
        content: Text('Delete this pricing entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _repo.delete(pricing.id);
        ref.invalidate(_pricingProvider(_selectedActivityId!));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
