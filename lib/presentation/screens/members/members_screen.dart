import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/member_model.dart';
import '../../../data/repositories/member_repository.dart';

final _membersProvider = FutureProvider.autoDispose<List<MemberModel>>((ref) {
  return MemberRepository().getAll();
});

final _repo = MemberRepository();

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(_membersProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Members', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Member'),
                  onPressed: () => _showForm(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: membersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (members) => members.isEmpty
                    ? const Center(child: Text('No members'))
                    : ListView(
                        children: members.map((m) => Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Text(m.fullName[0])),
                            title: Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${m.age != null ? '${m.age} yrs · ' : ''}${m.phone ?? ''}'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'edit') _showForm(context, member: m);
                                if (v == 'delete') _confirmDelete(context, m);
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

  Future<void> _showForm(BuildContext context, {MemberModel? member}) async {
    final nameCtrl = TextEditingController(text: member?.fullName ?? '');
    final ageCtrl = TextEditingController(text: member?.age?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: member?.phone ?? '');
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
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text(member == null ? 'Add Member' : 'Edit Member', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 8),
                TextField(controller: ageCtrl, decoration: const InputDecoration(labelText: 'Age (optional)'), keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone (optional)'), keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      setSheetState(() => saving = true);
                      try {
                        if (member == null) {
                          await _repo.create(
                            fullName: nameCtrl.text,
                            age: int.tryParse(ageCtrl.text),
                            phone: phoneCtrl.text.isNotEmpty ? phoneCtrl.text : null,
                          );
                        } else {
                          await _repo.update(
                            member.id,
                            fullName: nameCtrl.text,
                            age: int.tryParse(ageCtrl.text),
                            phone: phoneCtrl.text.isNotEmpty ? phoneCtrl.text : null,
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
                        : Text(member == null ? 'Add' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );

    if (result == true) ref.invalidate(_membersProvider);
  }

  Future<void> _confirmDelete(BuildContext context, MemberModel member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text('Delete "${member.fullName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _repo.delete(member.id);
        ref.invalidate(_membersProvider);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
