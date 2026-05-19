import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/pool_model.dart';
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
            )),
          ],
          rows: mirror.lanes.map((lane) {
            return DataRow(cells: [
              DataCell(Container(
                width: 60,
                child: Text('L${lane.number}', style: const TextStyle(fontWeight: FontWeight.bold)),
              )),
              ...mirror.timeSlots.map((slot) {
                return DataCell(
                  GestureDetector(
                    onTap: () => _showSlotDetail(context, mirror.poolId, lane.id, slot.id),
                    child: Container(
                      width: 80,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.slotAvailable.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.slotAvailable.withOpacity(0.3)),
                      ),
                      child: const Center(
                        child: Icon(Icons.add_circle_outline, color: AppTheme.slotAvailable, size: 18),
                      ),
                    ),
                  ),
                );
              }),
            ]);
          }).toList(),
        ),
      ),
    );
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
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Quick Booking', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Lane: ${widget.laneId}', style: TextStyle(color: Colors.grey.shade600)),
          Text('Date: ${DateFormat('MMM d, yyyy').format(widget.date)}', style: TextStyle(color: Colors.grey.shade600)),
          Text('Slot: ${widget.slotId}', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          Text('Select a customer and booking type to proceed.',
            style: TextStyle(color: Colors.grey.shade500)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking feature ready - integrate with backend')),
                );
              },
              child: const Text('Create Booking'),
            ),
          ),
        ],
      ),
    );
  }
}
