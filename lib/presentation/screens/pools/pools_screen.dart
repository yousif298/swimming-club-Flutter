import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pool_provider.dart';

class PoolsScreen extends ConsumerStatefulWidget {
  const PoolsScreen({super.key});

  @override
  ConsumerState<PoolsScreen> createState() => _PoolsScreenState();
}

class _PoolsScreenState extends ConsumerState<PoolsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(poolListProvider.notifier).load());
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pools', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Pool'),
                  onPressed: () => _showAddDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: poolsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (pools) => ListView.builder(
                  itemCount: pools.length,
                  itemBuilder: (context, i) {
                    final pool = pools[i];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.pool, color: Colors.white)),
                        title: Text(pool.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${pool.totalLanes} Lanes'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showPoolDetail(context, pool),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final lanesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Pool'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Pool Name')),
            const SizedBox(height: 12),
            TextField(controller: lanesCtrl, decoration: const InputDecoration(labelText: 'Number of Lanes'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ref.read(poolListProvider.notifier).add(nameCtrl.text, int.parse(lanesCtrl.text));
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showPoolDetail(BuildContext context, pool) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(pool.name),
        content: Text('Total Lanes: ${pool.totalLanes}\nID: ${pool.id}'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }
}
